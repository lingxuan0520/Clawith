"""Tenant (Company) management API."""

import uuid
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import select, delete as sa_delete
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_current_user
from app.database import get_db
from app.models.tenant import Tenant
from app.models.user import User

router = APIRouter(prefix="/tenants", tags=["tenants"])


class TenantCreate(BaseModel):
    name: str = Field(min_length=1, max_length=200)
    im_provider: str = "web_only"


class TenantOut(BaseModel):
    id: uuid.UUID
    name: str
    slug: str
    owner_id: uuid.UUID | None = None
    im_provider: str
    is_active: bool
    created_at: datetime | None = None

    model_config = {"from_attributes": True}


class TenantUpdate(BaseModel):
    name: str | None = None
    im_provider: str | None = None
    is_active: bool | None = None


@router.get("/", response_model=list[TenantOut])
async def list_tenants(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """List tenants owned by the current user."""
    import logging
    logger = logging.getLogger(__name__)
    logger.warning(f"[DEBUG] list_tenants called by user={current_user.id} username={current_user.username} owner_id filter={current_user.id}")
    result = await db.execute(
        select(Tenant).where(Tenant.owner_id == current_user.id).order_by(Tenant.created_at.desc())
    )
    tenants = result.scalars().all()
    logger.warning(f"[DEBUG] list_tenants returning {len(tenants)} tenants: {[(t.id, t.name, t.owner_id) for t in tenants]}")
    return [TenantOut.model_validate(t) for t in tenants]


@router.post("/", response_model=TenantOut, status_code=status.HTTP_201_CREATED)
async def create_tenant(
    data: TenantCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Create a new tenant/company owned by the current user."""
    import time
    slug = f"co-{current_user.id.hex[:8]}-{int(time.time())}"

    tenant = Tenant(name=data.name, slug=slug, im_provider=data.im_provider, owner_id=current_user.id)
    db.add(tenant)
    await db.flush()

    # Switch user to the new tenant
    current_user.tenant_id = tenant.id
    await db.flush()

    return TenantOut.model_validate(tenant)


@router.get("/{tenant_id}", response_model=TenantOut)
async def get_tenant(
    tenant_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get tenant details (must be owner)."""
    result = await db.execute(select(Tenant).where(Tenant.id == tenant_id, Tenant.owner_id == current_user.id))
    tenant = result.scalar_one_or_none()
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant not found")
    return TenantOut.model_validate(tenant)


@router.put("/{tenant_id}", response_model=TenantOut)
async def update_tenant(
    tenant_id: uuid.UUID,
    data: TenantUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Update tenant settings (must be owner)."""
    result = await db.execute(select(Tenant).where(Tenant.id == tenant_id, Tenant.owner_id == current_user.id))
    tenant = result.scalar_one_or_none()
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant not found")

    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(tenant, field, value)
    await db.flush()
    return TenantOut.model_validate(tenant)


@router.delete("/{tenant_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_tenant(
    tenant_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Delete a tenant (must be owner). If last tenant, user returns to onboarding."""
    result = await db.execute(select(Tenant).where(Tenant.id == tenant_id, Tenant.owner_id == current_user.id))
    tenant = result.scalar_one_or_none()
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant not found")

    # Find another tenant to switch to (may be None if this is the last one)
    other = await db.execute(
        select(Tenant).where(Tenant.owner_id == current_user.id, Tenant.id != tenant_id).limit(1)
    )
    other_tenant = other.scalar_one_or_none()

    # Move user to another tenant, or clear tenant_id if last one
    if current_user.tenant_id == tenant_id:
        current_user.tenant_id = other_tenant.id if other_tenant else None

    # Delete agents under this tenant that belong to this user
    from app.models.agent import Agent
    await db.execute(sa_delete(Agent).where(Agent.tenant_id == tenant_id, Agent.creator_id == current_user.id))

    # Delete the tenant
    await db.delete(tenant)
    await db.commit()


class TenantSimple(BaseModel):
    id: uuid.UUID
    name: str
    slug: str
    model_config = {"from_attributes": True}


@router.get("/public/list", response_model=list[TenantSimple])
async def list_tenants_public(db: AsyncSession = Depends(get_db)):
    """List active tenants for registration page (no auth required)."""
    result = await db.execute(
        select(Tenant).where(Tenant.is_active == True).order_by(Tenant.name)
    )
    return [TenantSimple.model_validate(t) for t in result.scalars().all()]
