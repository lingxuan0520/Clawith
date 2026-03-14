"""Authentication API routes."""

import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token, get_current_user, hash_password, verify_password
from app.database import get_db
from app.models.user import User
from app.schemas.schemas import TokenResponse, UserLogin, UserOut, UserRegister, UserUpdate

router = APIRouter(prefix="/auth", tags=["auth"])


@router.get("/registration-config")
async def get_registration_config(db: AsyncSession = Depends(get_db)):
    """Public endpoint — returns registration requirements (no auth needed)."""
    from app.models.system_settings import SystemSetting
    result = await db.execute(select(SystemSetting).where(SystemSetting.key == "invitation_code_enabled"))
    setting = result.scalar_one_or_none()
    enabled = setting.value.get("enabled", False) if setting else False
    return {"invitation_code_required": enabled}


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(data: UserRegister, db: AsyncSession = Depends(get_db)):
    """Register a new user account.

    The first user to register becomes the platform admin automatically.
    """
    # Check existing
    existing = await db.execute(
        select(User).where((User.username == data.username) | (User.email == data.email))
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Username or email already exists")

    # Check if this is the first user (→ platform admin)
    from sqlalchemy import func
    user_count = await db.execute(select(func.count()).select_from(User))
    is_first_user = user_count.scalar() == 0

    # Resolve tenant — required; fall back to default if not provided
    from app.models.tenant import Tenant
    tenant_uuid = None
    if data.tenant_id:
        t_result = await db.execute(select(Tenant).where(Tenant.id == uuid.UUID(data.tenant_id)))
        tenant = t_result.scalar_one_or_none()
        if not tenant:
            raise HTTPException(status_code=400, detail="选择的公司不存在")
        tenant_uuid = tenant.id
    else:
        # Auto-assign to the default company
        default = await db.execute(select(Tenant).where(Tenant.slug == "default"))
        tenant = default.scalar_one_or_none()
        if tenant:
            tenant_uuid = tenant.id

    # ── Invitation code check ──
    from app.models.system_settings import SystemSetting
    inv_setting = await db.execute(select(SystemSetting).where(SystemSetting.key == "invitation_code_enabled"))
    inv_s = inv_setting.scalar_one_or_none()
    invitation_required = inv_s.value.get("enabled", False) if inv_s else False

    invitation_code_obj = None
    if invitation_required:
        if not data.invitation_code:
            raise HTTPException(status_code=400, detail="Invitation code is required")
        from app.models.invitation_code import InvitationCode
        ic_result = await db.execute(
            select(InvitationCode).where(InvitationCode.code == data.invitation_code, InvitationCode.is_active == True)
        )
        invitation_code_obj = ic_result.scalar_one_or_none()
        if not invitation_code_obj:
            raise HTTPException(status_code=400, detail="Invalid invitation code")
        if invitation_code_obj.used_count >= invitation_code_obj.max_uses:
            raise HTTPException(status_code=400, detail="Invitation code has reached its usage limit")

    user = User(
        username=data.username,
        email=data.email,
        password_hash=hash_password(data.password),
        display_name=data.display_name or data.username,
        role="platform_admin" if is_first_user else "member",
        tenant_id=tenant_uuid,
        # Inherit quota defaults from tenant
        quota_message_limit=tenant.default_message_limit if tenant else 50,
        quota_message_period=tenant.default_message_period if tenant else "permanent",
        quota_max_agents=tenant.default_max_agents if tenant else 2,
        quota_agent_ttl_hours=tenant.default_agent_ttl_hours if tenant else 48,
    )
    db.add(user)
    await db.flush()

    # Auto-create Participant identity for the new user
    from app.models.participant import Participant
    db.add(Participant(
        type="user", ref_id=user.id,
        display_name=user.display_name, avatar_url=user.avatar_url,
    ))
    await db.flush()

    # Increment invitation code usage
    if invitation_code_obj:
        invitation_code_obj.used_count += 1

    # Seed default agents after first user (platform admin) registration
    if is_first_user:
        await db.commit()  # commit user first so seeder can find the admin
        try:
            from app.services.agent_seeder import seed_default_agents
            await seed_default_agents()
        except Exception as e:
            import logging
            logging.getLogger(__name__).warning(f"Failed to seed default agents: {e}")

    token = create_access_token(str(user.id), user.role)
    return TokenResponse(access_token=token, user=UserOut.model_validate(user))


@router.post("/login", response_model=TokenResponse)
async def login(data: UserLogin, db: AsyncSession = Depends(get_db)):
    """Login with username and password."""
    result = await db.execute(select(User).where(User.username == data.username))
    user = result.scalar_one_or_none()

    if not user or not verify_password(data.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account is disabled")

    token = create_access_token(str(user.id), user.role)
    return TokenResponse(access_token=token, user=UserOut.model_validate(user))


@router.get("/me", response_model=UserOut)
async def get_me(current_user: User = Depends(get_current_user)):
    """Get current user profile."""
    return UserOut.model_validate(current_user)


@router.patch("/me", response_model=UserOut)
async def update_me(
    data: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Update current user profile."""
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(current_user, field, value)
    await db.flush()
    return UserOut.model_validate(current_user)


@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT)
async def delete_account(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Permanently delete the current user account and all associated data.

    Required by Apple App Store guidelines.
    """
    from sqlalchemy import delete as sa_delete, update as sa_update
    from app.models.agent import Agent, AgentTemplate
    from app.models.audit import AuditLog, ApprovalRequest, ChatMessage
    from app.models.chat_session import ChatSession
    from app.models.task import Task, TaskLog
    from app.models.schedule import AgentSchedule
    from app.models.participant import Participant
    from app.models.plaza import PlazaPost, PlazaComment, PlazaLike

    user_id = current_user.id

    # 1. Get all agent IDs owned by this user
    agent_result = await db.execute(select(Agent.id).where(Agent.creator_id == user_id))
    agent_ids = [row[0] for row in agent_result.all()]

    if agent_ids:
        # 2. Delete agent child data (tables without DB-level CASCADE)
        await db.execute(sa_delete(ChatMessage).where(ChatMessage.agent_id.in_(agent_ids)))
        await db.execute(sa_delete(ChatSession).where(ChatSession.agent_id.in_(agent_ids)))
        await db.execute(sa_delete(ApprovalRequest).where(ApprovalRequest.agent_id.in_(agent_ids)))

        # TaskLogs via tasks
        task_result = await db.execute(select(Task.id).where(Task.agent_id.in_(agent_ids)))
        task_ids = [row[0] for row in task_result.all()]
        if task_ids:
            await db.execute(sa_delete(TaskLog).where(TaskLog.task_id.in_(task_ids)))
        await db.execute(sa_delete(Task).where(Task.agent_id.in_(agent_ids)))

        # Activity logs (no FK constraint, but clean up)
        try:
            from app.models.activity_log import AgentActivityLog
            await db.execute(sa_delete(AgentActivityLog).where(AgentActivityLog.agent_id.in_(agent_ids)))
        except Exception:
            pass

        # Channel configs
        try:
            from app.models.channel_config import ChannelConfig
            await db.execute(sa_delete(ChannelConfig).where(ChannelConfig.agent_id.in_(agent_ids)))
        except Exception:
            pass

        # Agent participants
        for aid in agent_ids:
            await db.execute(sa_delete(Participant).where(Participant.type == "agent", Participant.ref_id == aid))

        # 3. Delete agents (DB-level CASCADE handles: schedules, triggers, tools, relationships)
        await db.execute(sa_delete(Agent).where(Agent.creator_id == user_id))

    # 4. Delete user's own chat data (if any remain)
    await db.execute(sa_delete(ChatMessage).where(ChatMessage.user_id == user_id))
    await db.execute(sa_delete(ChatSession).where(ChatSession.user_id == user_id))

    # 5. Delete user's tasks
    user_task_result = await db.execute(select(Task.id).where(Task.created_by == user_id))
    user_task_ids = [row[0] for row in user_task_result.all()]
    if user_task_ids:
        await db.execute(sa_delete(TaskLog).where(TaskLog.task_id.in_(user_task_ids)))
    await db.execute(sa_delete(Task).where(Task.created_by == user_id))

    # 6. Delete schedules created by user
    await db.execute(sa_delete(AgentSchedule).where(AgentSchedule.created_by == user_id))

    # 7. Delete user participant record
    await db.execute(sa_delete(Participant).where(Participant.type == "user", Participant.ref_id == user_id))

    # 8. Delete plaza content
    await db.execute(sa_delete(PlazaLike).where(PlazaLike.author_type == "human", PlazaLike.author_id == user_id))
    await db.execute(sa_delete(PlazaComment).where(PlazaComment.author_type == "human", PlazaComment.author_id == user_id))
    await db.execute(sa_delete(PlazaPost).where(PlazaPost.author_type == "human", PlazaPost.author_id == user_id))

    # 9. Set NULL on nullable references
    await db.execute(sa_update(AuditLog).where(AuditLog.user_id == user_id).values(user_id=None))
    await db.execute(sa_update(ApprovalRequest).where(ApprovalRequest.resolved_by == user_id).values(resolved_by=None))
    await db.execute(sa_update(AgentTemplate).where(AgentTemplate.created_by == user_id).values(created_by=None))

    # 10. Delete user workspace files
    import shutil
    from pathlib import Path
    for base in [Path("/tmp/clawith_workspaces"), Path("/tmp/clawith_persistent")]:
        for aid in agent_ids:
            agent_dir = base / str(aid)
            if agent_dir.exists():
                shutil.rmtree(agent_dir, ignore_errors=True)

    # 11. Delete the user record
    await db.execute(sa_delete(User).where(User.id == user_id))
    await db.commit()


# ─── Firebase Auth ─────────────────────────────────────

FIREBASE_PROJECT_ID = "soloship-57b40"
GOOGLE_CERTS_URL = "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com"

# Cache Google's public certificates (they rotate infrequently)
_google_certs_cache: dict = {}


async def _verify_firebase_id_token(id_token: str) -> dict:
    """Verify a Firebase ID token without firebase-admin SDK.

    Uses Google's public certificates to verify the RS256 JWT signature,
    then validates standard Firebase claims.
    """
    import time
    import httpx
    from jose import jwt as jose_jwt, JWTError as JoseJWTError
    from cryptography.x509 import load_pem_x509_certificate

    # Fetch Google's public certificates (cached)
    global _google_certs_cache
    now = time.time()
    if not _google_certs_cache or _google_certs_cache.get("_expires", 0) < now:
        async with httpx.AsyncClient() as client:
            resp = await client.get(GOOGLE_CERTS_URL)
            resp.raise_for_status()
            certs = resp.json()
            # Cache based on Cache-Control max-age
            max_age = 3600  # default 1 hour
            cc = resp.headers.get("Cache-Control", "")
            for part in cc.split(","):
                part = part.strip()
                if part.startswith("max-age="):
                    try:
                        max_age = int(part.split("=")[1])
                    except ValueError:
                        pass
            _google_certs_cache = {**certs, "_expires": now + max_age}

    # Decode JWT header to get the key ID
    try:
        header = jose_jwt.get_unverified_header(id_token)
    except Exception:
        raise ValueError("Invalid token format")

    kid = header.get("kid")
    if not kid or kid not in _google_certs_cache:
        raise ValueError("Token signed with unknown key")

    # Extract public key from X.509 certificate
    cert_pem = _google_certs_cache[kid]
    cert = load_pem_x509_certificate(cert_pem.encode("utf-8"))
    public_key = cert.public_key()

    # Verify and decode the token
    try:
        payload = jose_jwt.decode(
            id_token,
            public_key,
            algorithms=["RS256"],
            audience=FIREBASE_PROJECT_ID,
            issuer=f"https://securetoken.google.com/{FIREBASE_PROJECT_ID}",
        )
    except JoseJWTError as e:
        raise ValueError(f"Token verification failed: {e}")

    # Validate required claims
    if not payload.get("sub"):
        raise ValueError("Token missing subject claim")

    return {
        "uid": payload["sub"],
        "email": payload.get("email", ""),
        "name": payload.get("name", ""),
        "picture": payload.get("picture", ""),
        "email_verified": payload.get("email_verified", False),
        "firebase": payload.get("firebase", {}),
    }


class FirebaseLoginRequest(BaseModel):
    id_token: str


@router.post("/firebase", response_model=TokenResponse)
async def firebase_login(data: FirebaseLoginRequest, db: AsyncSession = Depends(get_db)):
    """Login or register via Firebase Authentication.

    Accepts a Firebase ID token, verifies it, and returns a platform JWT.
    If the user doesn't exist yet, a new account is created automatically.
    """
    # Verify the Firebase ID token
    try:
        decoded = await _verify_firebase_id_token(data.id_token)
    except (ValueError, Exception) as e:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=f"Invalid Firebase token: {e}")

    firebase_uid = decoded["uid"]
    email = decoded.get("email", "")
    display_name = decoded.get("name", "")
    avatar_url = decoded.get("picture", "")
    provider = decoded.get("firebase", {}).get("sign_in_provider", "")

    import logging
    _logger = logging.getLogger(__name__)
    _logger.warning(f"[FIREBASE] login: uid={firebase_uid} email={email} provider={provider} name={display_name}")

    # Only match by firebase_uid — different providers = different accounts
    result = await db.execute(select(User).where(User.firebase_uid == firebase_uid))
    user = result.scalar_one_or_none()
    _logger.warning(f"[FIREBASE] find by uid: user={user.id if user else None}")

    # Update avatar/display_name/role for existing users on every login
    # 2C model: every user owns their own space → always platform_admin
    if user:
        changed = False
        if avatar_url and user.avatar_url != avatar_url:
            user.avatar_url = avatar_url
            changed = True
        if display_name and not user.display_name:
            user.display_name = display_name
            changed = True
        if user.role != "platform_admin":
            user.role = "platform_admin"
            changed = True
        if changed:
            await db.commit()
            await db.refresh(user)

    if not user:
        # Auto-register new user
        from sqlalchemy import func
        import time

        # Provider tag for uniqueness (e.g. "apple", "google")
        provider_tag = provider.replace(".com", "") if provider else "fb"

        username = email.split("@")[0] if email else f"fb_{firebase_uid[:12]}"
        # Ensure username uniqueness
        existing = await db.execute(select(User).where(User.username == username))
        if existing.scalar_one_or_none():
            username = f"{username}_{provider_tag}"
        # Double-check
        existing2 = await db.execute(select(User).where(User.username == username))
        if existing2.scalar_one_or_none():
            username = f"{username}_{firebase_uid[:6]}"

        # Ensure email uniqueness — different provider gets tagged email
        user_email = email or f"{firebase_uid}@firebase.local"
        existing_email = await db.execute(select(User).where(User.email == user_email))
        if existing_email.scalar_one_or_none():
            # e.g. "19910520chen+apple@gmail.com"
            local, domain = user_email.split("@", 1)
            user_email = f"{local}+{provider_tag}@{domain}"
        _logger.warning(f"[FIREBASE] creating new user: username={username} email={user_email} provider={provider}")

        # Create user (no tenant yet — user creates company in onboarding)
        user = User(
            username=username,
            email=user_email,
            password_hash=hash_password(uuid.uuid4().hex),  # random password (not used)
            display_name=display_name or username,
            avatar_url=avatar_url or None,
            role="platform_admin",  # every user owns their own space
            firebase_uid=firebase_uid,
        )
        db.add(user)
        await db.flush()

        # Create Participant identity
        from app.models.participant import Participant
        db.add(Participant(
            type="user", ref_id=user.id,
            display_name=user.display_name, avatar_url=user.avatar_url,
        ))
        await db.flush()

    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account is disabled")

    token = create_access_token(str(user.id), user.role)
    return TokenResponse(access_token=token, user=UserOut.model_validate(user))
