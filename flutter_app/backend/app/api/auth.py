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

    # Try to find existing user by firebase_uid
    result = await db.execute(select(User).where(User.firebase_uid == firebase_uid))
    user = result.scalar_one_or_none()

    if not user and email:
        # Try matching by email (user may have registered with password before)
        result = await db.execute(select(User).where(User.email == email))
        user = result.scalar_one_or_none()
        if user:
            # Link Firebase to existing account
            user.firebase_uid = firebase_uid
            if avatar_url and not user.avatar_url:
                user.avatar_url = avatar_url
            if display_name and user.display_name == user.username:
                user.display_name = display_name

    # Update avatar/display_name for existing users on every login
    if user:
        changed = False
        if avatar_url and user.avatar_url != avatar_url:
            user.avatar_url = avatar_url
            changed = True
        if display_name and not user.display_name:
            user.display_name = display_name
            changed = True
        if changed:
            await db.commit()
            await db.refresh(user)

    if not user:
        # Auto-register new user
        from sqlalchemy import func
        from app.models.tenant import Tenant

        user_count = await db.execute(select(func.count()).select_from(User))
        is_first_user = user_count.scalar() == 0

        # Assign to default tenant
        default = await db.execute(select(Tenant).where(Tenant.slug == "default"))
        tenant = default.scalar_one_or_none()

        username = email.split("@")[0] if email else f"fb_{firebase_uid[:12]}"
        # Ensure username uniqueness
        existing = await db.execute(select(User).where(User.username == username))
        if existing.scalar_one_or_none():
            username = f"{username}_{firebase_uid[:6]}"

        user = User(
            username=username,
            email=email or f"{firebase_uid}@firebase.local",
            password_hash=hash_password(uuid.uuid4().hex),  # random password (not used)
            display_name=display_name or username,
            avatar_url=avatar_url or None,
            role="platform_admin",  # every user owns their own space
            tenant_id=tenant.id if tenant else None,
            firebase_uid=firebase_uid,
            quota_message_limit=tenant.default_message_limit if tenant else 50,
            quota_message_period=tenant.default_message_period if tenant else "permanent",
            quota_max_agents=tenant.default_max_agents if tenant else 2,
            quota_agent_ttl_hours=tenant.default_agent_ttl_hours if tenant else 48,
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

        # Seed defaults for first user
        if is_first_user:
            await db.commit()
            try:
                from app.services.agent_seeder import seed_default_agents
                await seed_default_agents()
            except Exception:
                pass

    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account is disabled")

    token = create_access_token(str(user.id), user.role)
    return TokenResponse(access_token=token, user=UserOut.model_validate(user))
