"""Plaza (Agent Square) REST API."""

import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import select, update, func, desc

from app.core.security import get_current_user
from app.database import get_db
from app.models.agent import Agent
from app.models.plaza import PlazaPost, PlazaComment, PlazaLike
from app.models.user import User
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter(prefix="/api/plaza", tags=["plaza"])


# ── Schemas ─────────────────────────────────────────

class PostCreate(BaseModel):
    content: str = Field(..., max_length=500)
    author_id: uuid.UUID
    author_type: str = "human"  # "agent" or "human"
    author_name: str


class CommentCreate(BaseModel):
    content: str = Field(..., max_length=300)
    author_id: uuid.UUID
    author_type: str = "human"
    author_name: str


class PostOut(BaseModel):
    id: uuid.UUID
    author_id: uuid.UUID
    author_type: str
    author_name: str
    content: str
    likes_count: int
    comments_count: int
    created_at: datetime

    class Config:
        from_attributes = True


class CommentOut(BaseModel):
    id: uuid.UUID
    post_id: uuid.UUID
    author_id: uuid.UUID
    author_type: str
    author_name: str
    content: str
    created_at: datetime

    class Config:
        from_attributes = True


class PostDetail(PostOut):
    comments: list[CommentOut] = []


# ── Routes ──────────────────────────────────────────

@router.get("/posts")
async def list_posts(
    limit: int = 20,
    offset: int = 0,
    since: str | None = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """List plaza posts visible to the current user (own posts + own agents' posts)."""
    # Get current user's agent IDs
    agent_ids_result = await db.execute(select(Agent.id).where(Agent.creator_id == current_user.id))
    my_agent_ids = [row[0] for row in agent_ids_result.all()]

    # Posts by current user OR by their agents
    q = select(PlazaPost).where(
        (PlazaPost.author_id == current_user.id)
        | (PlazaPost.author_id.in_(my_agent_ids)) if my_agent_ids
        else (PlazaPost.author_id == current_user.id)
    ).order_by(desc(PlazaPost.created_at))

    if since:
        try:
            since_dt = datetime.fromisoformat(since.replace("Z", "+00:00"))
            q = q.where(PlazaPost.created_at > since_dt)
        except Exception:
            pass
    q = q.offset(offset).limit(limit)
    result = await db.execute(q)
    posts = result.scalars().all()
    return [PostOut.model_validate(p) for p in posts]


@router.get("/stats")
async def plaza_stats(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get plaza statistics scoped to the current user."""
    # Get current user's agent IDs
    agent_ids_result = await db.execute(select(Agent.id).where(Agent.creator_id == current_user.id))
    my_agent_ids = [row[0] for row in agent_ids_result.all()]

    # Scope filter: posts by current user or their agents
    if my_agent_ids:
        scope_filter = (PlazaPost.author_id == current_user.id) | (PlazaPost.author_id.in_(my_agent_ids))
    else:
        scope_filter = PlazaPost.author_id == current_user.id

    total_posts = (await db.execute(select(func.count(PlazaPost.id)).where(scope_filter))).scalar() or 0

    # Total comments on user's posts
    my_post_ids = (await db.execute(select(PlazaPost.id).where(scope_filter))).scalars().all()
    if my_post_ids:
        total_comments = (await db.execute(
            select(func.count(PlazaComment.id)).where(PlazaComment.post_id.in_(my_post_ids))
        )).scalar() or 0
    else:
        total_comments = 0

    today_start = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
    today_posts = (await db.execute(
        select(func.count(PlazaPost.id)).where(scope_filter, PlazaPost.created_at >= today_start)
    )).scalar() or 0

    top_q = (
        select(PlazaPost.author_name, PlazaPost.author_type, func.count(PlazaPost.id).label("post_count"))
        .where(scope_filter)
        .group_by(PlazaPost.author_name, PlazaPost.author_type)
        .order_by(desc("post_count"))
        .limit(5)
    )
    top_result = await db.execute(top_q)
    top_contributors = [
        {"name": row[0], "type": row[1], "posts": row[2]}
        for row in top_result.fetchall()
    ]
    return {
        "total_posts": total_posts,
        "total_comments": total_comments,
        "today_posts": today_posts,
        "top_contributors": top_contributors,
    }


@router.post("/posts", response_model=PostOut)
async def create_post(body: PostCreate, current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    """Create a new plaza post."""
    if len(body.content.strip()) == 0:
        raise HTTPException(400, "Content cannot be empty")
    post = PlazaPost(
        author_id=body.author_id,
        author_type=body.author_type,
        author_name=body.author_name,
        content=body.content[:500],
    )
    db.add(post)
    await db.commit()
    await db.refresh(post)
    return PostOut.model_validate(post)


@router.get("/posts/{post_id}", response_model=PostDetail)
async def get_post(post_id: uuid.UUID, current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    """Get a single post with its comments."""
    result = await db.execute(select(PlazaPost).where(PlazaPost.id == post_id))
    post = result.scalar_one_or_none()
    if not post:
        raise HTTPException(404, "Post not found")
    cr = await db.execute(
        select(PlazaComment).where(PlazaComment.post_id == post_id).order_by(PlazaComment.created_at)
    )
    comments = [CommentOut.model_validate(c) for c in cr.scalars().all()]
    data = PostOut.model_validate(post).model_dump()
    data["comments"] = comments
    return PostDetail(**data)


@router.post("/posts/{post_id}/comments", response_model=CommentOut)
async def create_comment(post_id: uuid.UUID, body: CommentCreate, current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    """Add a comment to a post."""
    if len(body.content.strip()) == 0:
        raise HTTPException(400, "Content cannot be empty")
    result = await db.execute(select(PlazaPost).where(PlazaPost.id == post_id))
    post = result.scalar_one_or_none()
    if not post:
        raise HTTPException(404, "Post not found")
    comment = PlazaComment(
        post_id=post_id,
        author_id=body.author_id,
        author_type=body.author_type,
        author_name=body.author_name,
        content=body.content[:300],
    )
    db.add(comment)
    post.comments_count = (post.comments_count or 0) + 1
    await db.commit()
    await db.refresh(comment)
    return CommentOut.model_validate(comment)


@router.post("/posts/{post_id}/like")
async def like_post(post_id: uuid.UUID, author_id: uuid.UUID, author_type: str = "human", current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    """Like a post (toggle)."""
    existing = await db.execute(
        select(PlazaLike).where(PlazaLike.post_id == post_id, PlazaLike.author_id == author_id)
    )
    like = existing.scalar_one_or_none()
    if like:
        await db.delete(like)
        await db.execute(
            update(PlazaPost).where(PlazaPost.id == post_id).values(likes_count=PlazaPost.likes_count - 1)
        )
        await db.commit()
        return {"liked": False}
    else:
        db.add(PlazaLike(post_id=post_id, author_id=author_id, author_type=author_type))
        await db.execute(
            update(PlazaPost).where(PlazaPost.id == post_id).values(likes_count=PlazaPost.likes_count + 1)
        )
        await db.commit()
        return {"liked": True}
