"""Billing service — calculate costs and manage user credits.

All monetary values are in USD cents to avoid floating-point issues.
"""

import uuid
from datetime import datetime, timezone

from sqlalchemy import select

from app.database import async_session
from app.models.billing import UsageRecord
from app.models.llm import LLMModel
from app.models.user import User

# 30% markup on OpenRouter cost
MARKUP = 1.30


def calculate_cost_cents(
    model: LLMModel,
    input_tokens: int,
    output_tokens: int,
) -> tuple[int, int]:
    """Calculate cost for one LLM call.

    Returns (charged_cents, raw_cents):
        charged_cents: amount to deduct from user (with markup)
        raw_cents: OpenRouter cost (no markup)
    """
    input_cost = (input_tokens / 1_000_000) * model.cost_per_input_token_million
    output_cost = (output_tokens / 1_000_000) * model.cost_per_output_token_million
    raw_usd = input_cost + output_cost
    raw_cents = max(round(raw_usd * 100), 0)
    charged_cents = max(round(raw_usd * MARKUP * 100), 1) if (input_tokens + output_tokens) > 0 else 0
    return charged_cents, raw_cents


async def check_balance(user_id: uuid.UUID) -> bool:
    """Return True if user has credits remaining (or is on a subscription)."""
    async with async_session() as db:
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if not user:
            return False
        # Subscribed users with valid subscription always pass
        if user.subscription_tier != "free" and user.subscription_expires_at:
            if user.subscription_expires_at > datetime.now(timezone.utc):
                return True
        return user.credit_balance_cents > 0


async def deduct_credits(
    user_id: uuid.UUID,
    model: LLMModel,
    input_tokens: int,
    output_tokens: int,
    agent_id: uuid.UUID | None = None,
) -> int:
    """Deduct credits for an LLM call and record usage. Returns charged cents."""
    charged_cents, raw_cents = calculate_cost_cents(model, input_tokens, output_tokens)
    if charged_cents == 0:
        return 0

    async with async_session() as db:
        # Deduct from user balance
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if not user:
            return 0

        user.credit_balance_cents = max((user.credit_balance_cents or 0) - charged_cents, 0)
        user.total_credits_used_cents = (user.total_credits_used_cents or 0) + charged_cents

        # Record usage
        record = UsageRecord(
            user_id=user_id,
            agent_id=agent_id,
            model_id=model.id,
            model_name=model.label or model.model,
            input_tokens=input_tokens,
            output_tokens=output_tokens,
            cost_cents=charged_cents,
            openrouter_cost_cents=raw_cents,
        )
        db.add(record)
        await db.commit()

    return charged_cents


async def add_credits(user_id: uuid.UUID, amount_cents: int) -> int:
    """Add credits to a user's balance. Returns new balance."""
    async with async_session() as db:
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if not user:
            return 0

        user.credit_balance_cents = (user.credit_balance_cents or 0) + amount_cents
        user.total_credits_purchased_cents = (user.total_credits_purchased_cents or 0) + amount_cents
        await db.commit()
        return user.credit_balance_cents


async def get_balance(user_id: uuid.UUID) -> dict:
    """Get user's billing summary."""
    async with async_session() as db:
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if not user:
            return {"credit_balance_cents": 0, "total_purchased_cents": 0, "total_used_cents": 0, "subscription_tier": "free"}

        return {
            "credit_balance_cents": user.credit_balance_cents or 0,
            "total_purchased_cents": user.total_credits_purchased_cents or 0,
            "total_used_cents": user.total_credits_used_cents or 0,
            "subscription_tier": user.subscription_tier or "free",
            "subscription_expires_at": user.subscription_expires_at.isoformat() if user.subscription_expires_at else None,
        }
