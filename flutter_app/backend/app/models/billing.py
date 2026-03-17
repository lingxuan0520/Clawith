"""Billing / usage tracking models."""

import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class UsageRecord(Base):
    """Records each LLM API call for billing and analytics."""

    __tablename__ = "usage_records"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    agent_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("agents.id"))
    model_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("llm_models.id"))
    model_name: Mapped[str | None] = mapped_column()  # denormalized for quick queries

    input_tokens: Mapped[int] = mapped_column(Integer, default=0)
    output_tokens: Mapped[int] = mapped_column(Integer, default=0)
    cost_cents: Mapped[int] = mapped_column(Integer, default=0)  # charged amount (with markup)
    openrouter_cost_cents: Mapped[int] = mapped_column(Integer, default=0)  # raw OpenRouter cost

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
