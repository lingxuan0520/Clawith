"""Billing API — balance, usage, models, subscriptions, credit packs, and Apple IAP."""

import logging
import uuid
from datetime import datetime, timedelta, timezone

import httpx
from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.core.security import get_current_user
from app.database import get_db
from app.models.billing import PurchaseRecord, UsageRecord
from app.models.llm import LLMModel
from app.models.user import User

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/billing", tags=["billing"])


# ── Plans ────────────────────────────────────────────────────────────

SUBSCRIPTION_PLANS = {
    "pro": {
        "name": "Pro",
        "price_cents": 2999,  # $29.99/month (matches App Store Connect)
        "credit_cents": 2999,  # $29.99 worth of token credits
        "period_days": 30,
    },
}

CREDIT_PACK_CENTS = 1999  # $19.99 per pack (matches App Store Connect)

# Apple IAP product → credit mapping
APPLE_PRODUCT_MAP = {
    "pro_monthly": {"type": "subscription", "credit_cents": 2999, "tier": "pro", "period_days": 30},
    "credit_pack_20": {"type": "consumable", "credit_cents": 1999},
}

APPLE_VERIFY_URL_PROD = "https://buy.itunes.apple.com/verifyReceipt"
APPLE_VERIFY_URL_SANDBOX = "https://sandbox.itunes.apple.com/verifyReceipt"


# ── Schemas ──────────────────────────────────────────────────────────

class AddCreditsRequest(BaseModel):
    amount_cents: int


class AppleReceiptRequest(BaseModel):
    receipt_data: str       # Base64 encoded receipt from StoreKit
    product_id: str         # "pro_monthly" or "credit_pack_20"
    transaction_id: str     # For idempotency check


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
                "price_cents": 2999,
                "credit_cents": 2999,
                "period_days": 30,
                "description": "$29.99/月，含 $29.99 Token 额度，余额可累积",
            },
        ],
        "credit_packs": [
            {
                "id": "pack_20",
                "price_cents": 1999,
                "credit_cents": 1999,
                "description": "$19.99 额度包",
            },
        ],
    }


@router.post("/subscribe")
async def subscribe(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Subscribe to Pro plan (test fallback — production should use Apple IAP)."""

    plan = SUBSCRIPTION_PLANS["pro"]

    result = await db.execute(select(User).where(User.id == current_user.id))
    user = result.scalar_one()

    now = datetime.now(timezone.utc)

    if user.subscription_expires_at and user.subscription_expires_at > now:
        new_expiry = user.subscription_expires_at + timedelta(days=plan["period_days"])
    else:
        new_expiry = now + timedelta(days=plan["period_days"])

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
    """Buy a credit pack (test fallback — production should use Apple IAP)."""

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
    """Add credits to the current user's balance (test/admin endpoint)."""

    if body.amount_cents <= 0:
        raise HTTPException(status_code=400, detail="amount_cents must be > 0")

    from app.services.billing import add_credits as _add_credits
    new_balance = await _add_credits(current_user.id, body.amount_cents)

    return {
        "credit_balance_cents": new_balance,
        "added_cents": body.amount_cents,
    }


# ── Apple IAP ────────────────────────────────────────────────────────

async def _verify_apple_receipt(receipt_data: str) -> dict:
    """Verify receipt with Apple. Tries production first, falls back to sandbox."""
    settings = get_settings()
    payload = {
        "receipt-data": receipt_data,
        "password": settings.APPLE_SHARED_SECRET,
        "exclude-old-transactions": True,
    }

    async with httpx.AsyncClient(timeout=30) as client:
        # Try production first
        resp = await client.post(APPLE_VERIFY_URL_PROD, json=payload)
        data = resp.json()

        # status 21007 means receipt is from sandbox — retry with sandbox URL
        if data.get("status") == 21007:
            resp = await client.post(APPLE_VERIFY_URL_SANDBOX, json=payload)
            data = resp.json()

    return data


@router.post("/verify-apple-receipt")
async def verify_apple_receipt(
    body: AppleReceiptRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Verify Apple IAP receipt and add credits.

    Called by Flutter after a successful StoreKit purchase.
    Idempotent — same transaction_id won't be processed twice.
    """
    # 1. Check product is known
    product_info = APPLE_PRODUCT_MAP.get(body.product_id)
    if not product_info:
        raise HTTPException(status_code=400, detail=f"Unknown product_id: {body.product_id}")

    # 2. Check idempotency — don't process same transaction twice
    existing = await db.execute(
        select(PurchaseRecord).where(PurchaseRecord.transaction_id == body.transaction_id)
    )
    if existing.scalar_one_or_none():
        # Already processed — return current balance (idempotent success)
        await db.refresh(current_user)
        return {
            "status": "already_processed",
            "credit_balance_cents": current_user.credit_balance_cents or 0,
        }

    # 3. Verify receipt with Apple
    apple_data = await _verify_apple_receipt(body.receipt_data)
    apple_status = apple_data.get("status")

    if apple_status != 0:
        logger.warning("Apple receipt verification failed: status=%s user=%s", apple_status, current_user.id)
        raise HTTPException(status_code=400, detail=f"Apple receipt invalid (status {apple_status})")

    # 4. Verify bundle_id matches
    settings = get_settings()
    receipt_info = apple_data.get("receipt", {})
    bundle_id = receipt_info.get("bundle_id")
    if bundle_id != settings.APPLE_BUNDLE_ID:
        logger.warning("Bundle ID mismatch: got %s, expected %s", bundle_id, settings.APPLE_BUNDLE_ID)
        raise HTTPException(status_code=400, detail="Bundle ID mismatch")

    # 5. Apply credits
    result = await db.execute(select(User).where(User.id == current_user.id))
    user = result.scalar_one()

    credit_cents = product_info["credit_cents"]
    user.credit_balance_cents = (user.credit_balance_cents or 0) + credit_cents
    user.total_credits_purchased_cents = (user.total_credits_purchased_cents or 0) + credit_cents

    # If subscription, update tier and expiry
    if product_info["type"] == "subscription":
        now = datetime.now(timezone.utc)
        period_days = product_info["period_days"]
        if user.subscription_expires_at and user.subscription_expires_at > now:
            user.subscription_expires_at = user.subscription_expires_at + timedelta(days=period_days)
        else:
            user.subscription_expires_at = now + timedelta(days=period_days)
        user.subscription_tier = product_info["tier"]

    # 6. Record purchase for idempotency
    purchase = PurchaseRecord(
        user_id=user.id,
        platform="apple",
        product_id=body.product_id,
        transaction_id=body.transaction_id,
        receipt_data=body.receipt_data[:5000],  # truncate for storage
        amount_cents=credit_cents,
        status="completed",
    )
    db.add(purchase)
    await db.commit()
    await db.refresh(user)

    logger.info(
        "Apple IAP processed: user=%s product=%s transaction=%s credits=%d",
        user.id, body.product_id, body.transaction_id, credit_cents,
    )

    return {
        "status": "success",
        "credit_balance_cents": user.credit_balance_cents,
        "added_credit_cents": credit_cents,
        "subscription_tier": user.subscription_tier,
        "subscription_expires_at": (
            user.subscription_expires_at.isoformat()
            if user.subscription_expires_at else None
        ),
    }


@router.post("/apple-webhook")
async def apple_webhook(
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    """Apple Server-to-Server notification for subscription events.

    No auth required (Apple calls this directly).
    Handles: RENEWAL, CANCEL, DID_FAIL_TO_RENEW, etc.
    """
    try:
        payload = await request.json()
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid JSON")

    notification_type = payload.get("notification_type", "")
    unified_receipt = payload.get("unified_receipt", {})
    latest_receipt = unified_receipt.get("latest_receipt", "")
    latest_receipt_info = unified_receipt.get("latest_receipt_info", [])

    logger.info("Apple webhook: type=%s", notification_type)

    if notification_type in ("RENEWAL", "DID_RENEW", "INITIAL_BUY"):
        # Auto-renewal succeeded — verify and add credits
        if not latest_receipt_info:
            return {"status": "no_receipt_info"}

        # Get the latest transaction
        latest = latest_receipt_info[-1] if latest_receipt_info else {}
        original_transaction_id = latest.get("original_transaction_id", "")
        transaction_id = latest.get("transaction_id", "")
        product_id = latest.get("product_id", "")

        product_info = APPLE_PRODUCT_MAP.get(product_id)
        if not product_info:
            logger.warning("Apple webhook: unknown product_id=%s", product_id)
            return {"status": "unknown_product"}

        # Find user by previous purchase with same original_transaction_id
        existing = await db.execute(
            select(PurchaseRecord).where(
                PurchaseRecord.platform == "apple",
                PurchaseRecord.transaction_id.like(f"%{original_transaction_id}%"),
            ).order_by(PurchaseRecord.created_at.desc()).limit(1)
        )
        prev_purchase = existing.scalar_one_or_none()
        if not prev_purchase:
            logger.warning("Apple webhook: no user found for original_transaction=%s", original_transaction_id)
            return {"status": "user_not_found"}

        # Check idempotency
        dup = await db.execute(
            select(PurchaseRecord).where(PurchaseRecord.transaction_id == transaction_id)
        )
        if dup.scalar_one_or_none():
            return {"status": "already_processed"}

        # Apply credits
        user_result = await db.execute(select(User).where(User.id == prev_purchase.user_id))
        user = user_result.scalar_one_or_none()
        if not user:
            return {"status": "user_not_found"}

        credit_cents = product_info["credit_cents"]
        user.credit_balance_cents = (user.credit_balance_cents or 0) + credit_cents
        user.total_credits_purchased_cents = (user.total_credits_purchased_cents or 0) + credit_cents

        if product_info["type"] == "subscription":
            now = datetime.now(timezone.utc)
            period_days = product_info["period_days"]
            if user.subscription_expires_at and user.subscription_expires_at > now:
                user.subscription_expires_at = user.subscription_expires_at + timedelta(days=period_days)
            else:
                user.subscription_expires_at = now + timedelta(days=period_days)
            user.subscription_tier = product_info["tier"]

        purchase = PurchaseRecord(
            user_id=user.id,
            platform="apple",
            product_id=product_id,
            transaction_id=transaction_id,
            receipt_data=latest_receipt[:5000] if latest_receipt else None,
            amount_cents=credit_cents,
            status="completed",
        )
        db.add(purchase)
        await db.commit()
        logger.info("Apple webhook RENEWAL: user=%s credits=%d", user.id, credit_cents)

    elif notification_type in ("CANCEL", "DID_CHANGE_RENEWAL_STATUS"):
        # User cancelled — don't remove credits, just log
        # Subscription will naturally expire at subscription_expires_at
        logger.info("Apple webhook: subscription cancelled/changed")

    elif notification_type == "DID_FAIL_TO_RENEW":
        logger.info("Apple webhook: renewal failed, subscription will expire naturally")

    else:
        logger.info("Apple webhook: unhandled type=%s", notification_type)

    return {"status": "ok"}
