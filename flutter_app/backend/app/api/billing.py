"""Billing API — balance, usage, models, subscriptions, and credit packs."""

import uuid
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_current_user
from app.database import get_db
from app.models.billing import UsageRecord
from app.models.llm import LLMModel
from app.models.user import User

router = APIRouter(prefix="/billing", tags=["billing"])


# ── Plans ────────────────────────────────────────────────────────────

SUBSCRIPTION_PLANS = {
    "pro": {
        "name": "Pro",
        "price_cents": 2990,  # $29.9/month
        "credit_cents": 2990,  # $29.9 worth of token credits
        "period_days": 30,
    },
}

CREDIT_PACK_CENTS = 2000  # $20 per pack


# ── Schemas ──────────────────────────────────────────────────────────

class AddCreditsRequest(BaseModel):
    amount_cents: int


# ── Endpoints ────────────────────────────────────────────────────────

@router.get("/balance")
async def get_balance(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Return the current user's credit balance and billing summary."""
    return {
        "credit_balance_cents": current_user.credit_balance_cents or 0,
        "total_purchased_cents": current_user.total_credits_purchased_cents or 0,
        "total_used_cents": current_user.total_credits_used_cents or 0,
        "subscription_tier": current_user.subscription_tier or "free",
        "subscription_expires_at": (
            current_user.subscription_expires_at.isoformat()
            if current_user.subscription_expires_at else None
        ),
    }


@router.get("/plans")
async def list_plans(current_user: User = Depends(get_current_user)):
    """Return available subscription plans and credit packs."""
    return {
        "subscription_plans": [
            {
                "id": "pro",
                "name": "Pro",
                "price_cents": 2990,
                "credit_cents": 2990,
                "period_days": 30,
                "description": "$29.9/月，含 $29.9 Token 额度，余额可累积",
            },
        ],
        "credit_packs": [
            {
                "id": "pack_20",
                "price_cents": 2000,
                "credit_cents": 2000,
                "description": "$20 额度包",
            },
        ],
    }


@router.post("/subscribe")
async def subscribe(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Subscribe to Pro plan. Adds credits and extends subscription.

    NOTE: In production this will be triggered by RevenueCat webhook
    after IAP verification. For now it's a direct endpoint for testing.
    """
    plan = SUBSCRIPTION_PLANS["pro"]

    # Refresh user from DB to get latest balance
    result = await db.execute(select(User).where(User.id == current_user.id))
    user = result.scalar_one()

    now = datetime.now(timezone.utc)

    # Extend subscription (from current expiry if still active, else from now)
    if user.subscription_expires_at and user.subscription_expires_at > now:
        new_expiry = user.subscription_expires_at + timedelta(days=plan["period_days"])
    else:
        new_expiry = now + timedelta(days=plan["period_days"])

    # Add credits (rollover — don't reset existing balance)
    user.credit_balance_cents = (user.credit_balance_cents or 0) + plan["credit_cents"]
    user.total_credits_purchased_cents = (user.total_credits_purchased_cents or 0) + plan["credit_cents"]
    user.subscription_tier = "pro"
    user.subscription_expires_at = new_expiry

    await db.commit()
    await db.refresh(user)

    return {
        "subscription_tier": "pro",
        "subscription_expires_at": new_expiry.isoformat(),
        "credit_balance_cents": user.credit_balance_cents,
        "added_credit_cents": plan["credit_cents"],
    }


@router.post("/buy-credits")
async def buy_credits(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Buy a $20 credit pack. Credits are added to current balance (rollover).

    NOTE: In production this will be triggered by RevenueCat webhook
    after IAP verification. For now it's a direct endpoint for testing.
    """
    result = await db.execute(select(User).where(User.id == current_user.id))
    user = result.scalar_one()

    user.credit_balance_cents = (user.credit_balance_cents or 0) + CREDIT_PACK_CENTS
    user.total_credits_purchased_cents = (user.total_credits_purchased_cents or 0) + CREDIT_PACK_CENTS

    await db.commit()
    await db.refresh(user)

    return {
        "credit_balance_cents": user.credit_balance_cents,
        "added_credit_cents": CREDIT_PACK_CENTS,
    }


@router.get("/usage")
async def get_usage(
    days: int = 30,
    agent_id: str | None = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Return usage records for the current user, optionally filtered by agent."""
    since = datetime.now(timezone.utc) - timedelta(days=days)
    q = select(UsageRecord).where(
        UsageRecord.user_id == current_user.id,
        UsageRecord.created_at >= since,
    ).order_by(UsageRecord.created_at.desc())

    if agent_id:
        q = q.where(UsageRecord.agent_id == uuid.UUID(agent_id))

    result = await db.execute(q.limit(500))
    records = result.scalars().all()

    return [
        {
            "id": str(r.id),
            "agent_id": str(r.agent_id) if r.agent_id else None,
            "model_name": r.model_name,
            "input_tokens": r.input_tokens,
            "output_tokens": r.output_tokens,
            "cost_cents": r.cost_cents,
            "created_at": r.created_at.isoformat() if r.created_at else None,
        }
        for r in records
    ]


@router.get("/models")
async def list_billing_models(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Return all available system models with pricing info."""
    result = await db.execute(
        select(LLMModel).where(
            LLMModel.is_system_model == True,  # noqa: E712
            LLMModel.enabled == True,  # noqa: E712
        ).order_by(LLMModel.tier, LLMModel.label)
    )
    models = result.scalars().all()

    return [
        {
            "id": str(m.id),
            "provider": m.provider,
            "model": m.model,
            "label": m.label,
            "tier": m.tier,
            "supports_vision": m.supports_vision,
            "cost_per_input_token_million": m.cost_per_input_token_million,
            "cost_per_output_token_million": m.cost_per_output_token_million,
        }
        for m in models
    ]


@router.post("/add-credits")
async def add_credits(
    body: AddCreditsRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Add credits to the current user's balance (dev/test endpoint)."""
    if body.amount_cents <= 0:
        raise HTTPException(status_code=400, detail="amount_cents must be > 0")

    from app.services.billing import add_credits as _add_credits
    new_balance = await _add_credits(current_user.id, body.amount_cents)

    return {
        "credit_balance_cents": new_balance,
        "added_cents": body.amount_cents,
    }
