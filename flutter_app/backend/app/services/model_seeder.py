"""Seed the platform model pool with popular OpenRouter models.

Runs on every startup. Idempotent: upserts by model name, updates pricing if changed.
"""

from sqlalchemy import select

from app.database import async_session
from app.models.llm import LLMModel

# ── Model definitions ───────────────────────────────────────────────
# fmt: off
SYSTEM_MODELS = [
    {"model": "openai/gpt-4o",              "label": "GPT-4o",              "input": 2.50,  "output": 10.00, "tier": "premium",  "vision": True},
    {"model": "openai/gpt-4o-mini",          "label": "GPT-4o Mini",         "input": 0.15,  "output": 0.60,  "tier": "budget",   "vision": True},
    {"model": "anthropic/claude-sonnet-4",  "label": "Claude Sonnet 4",    "input": 3.00,  "output": 15.00, "tier": "premium",  "vision": True},
    {"model": "anthropic/claude-haiku-3.5",  "label": "Claude Haiku 3.5",   "input": 0.80,  "output": 4.00,  "tier": "standard", "vision": True},
    {"model": "google/gemini-2.0-flash-001", "label": "Gemini 2.0 Flash",   "input": 0.10,  "output": 0.40,  "tier": "budget",   "vision": True},
    {"model": "google/gemini-2.5-pro-preview", "label": "Gemini 2.5 Pro",   "input": 1.25,  "output": 10.00, "tier": "premium",  "vision": True},
    {"model": "deepseek/deepseek-chat-v3-0324", "label": "DeepSeek V3",     "input": 0.27,  "output": 1.10,  "tier": "budget",   "vision": False},
    {"model": "deepseek/deepseek-r1",        "label": "DeepSeek R1",        "input": 0.55,  "output": 2.19,  "tier": "standard", "vision": False},
    {"model": "meta-llama/llama-4-maverick", "label": "Llama 4 Maverick",  "input": 0.20,  "output": 0.60,  "tier": "budget",   "vision": False},
    {"model": "mistralai/mistral-large-2411","label": "Mistral Large",      "input": 2.00,  "output": 6.00,  "tier": "standard", "vision": False},
    {"model": "qwen/qwen-2.5-72b-instruct", "label": "Qwen 2.5 72B",      "input": 0.30,  "output": 0.30,  "tier": "budget",   "vision": False},
]
# fmt: on


async def seed_system_models() -> None:
    """Insert or update system models in the DB. Safe to call on every boot."""
    # Use Redis lock to prevent duplicate seeding from multiple workers
    try:
        from app.core.events import get_redis
        redis = await get_redis()
        acquired = await redis.set("model_seeder_lock", "1", nx=True, ex=30)
        if not acquired:
            print("[startup] ⏳ Model seeder skipped (another worker is running it)", flush=True)
            return
    except Exception:
        pass  # If Redis unavailable, proceed anyway

    created = 0
    updated = 0

    async with async_session() as db:
        for m in SYSTEM_MODELS:
            result = await db.execute(
                select(LLMModel).where(LLMModel.model == m["model"], LLMModel.is_system_model == True)  # noqa: E712
            )
            existing_list = result.scalars().all()

            # Clean up duplicates if any
            if len(existing_list) > 1:
                for dup in existing_list[1:]:
                    await db.delete(dup)
                existing_list = existing_list[:1]

            existing = existing_list[0] if existing_list else None

            if existing:
                # Update pricing / label if changed
                changed = False
                if existing.cost_per_input_token_million != m["input"]:
                    existing.cost_per_input_token_million = m["input"]
                    changed = True
                if existing.cost_per_output_token_million != m["output"]:
                    existing.cost_per_output_token_million = m["output"]
                    changed = True
                if existing.tier != m["tier"]:
                    existing.tier = m["tier"]
                    changed = True
                if existing.label != m["label"]:
                    existing.label = m["label"]
                    changed = True
                if existing.supports_vision != m["vision"]:
                    existing.supports_vision = m["vision"]
                    changed = True
                if changed:
                    updated += 1
            else:
                db.add(LLMModel(
                    provider="openrouter",
                    model=m["model"],
                    api_key_encrypted="",  # uses platform key at runtime
                    label=m["label"],
                    enabled=True,
                    supports_vision=m["vision"],
                    cost_per_input_token_million=m["input"],
                    cost_per_output_token_million=m["output"],
                    is_system_model=True,
                    tier=m["tier"],
                ))
                created += 1

        await db.commit()

    print(f"[startup] ✅ Model pool seeded: {created} created, {updated} updated ({len(SYSTEM_MODELS)} total)", flush=True)
