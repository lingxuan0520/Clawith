"""Cross-process event bus backed by Redis Pub/Sub.

Works correctly across multiple uvicorn workers: publish() writes to Redis,
subscribe() reads from Redis, so events flow between any processes.

Usage (unchanged from the in-memory version):
    from app.services.event_bus import event_bus

    # Subscribe (WebSocket handler):
    async for event in event_bus.subscribe(user_id):
        await ws.send_json(event)

    # Publish (task_executor, tasks API, etc.):
    await event_bus.publish(user_id, {
        "type": "agent_status",
        "agent_id": "...",
        "status": "running",
    })
"""

import asyncio
import json
import uuid

import redis.asyncio as aioredis

from app.config import get_settings

_CHANNEL_PREFIX = "events:"


class EventBus:
    """Async pub/sub backed by Redis — safe for multi-worker deployment."""

    def __init__(self):
        self._redis: aioredis.Redis | None = None

    async def _get_redis(self) -> aioredis.Redis:
        if self._redis is None:
            settings = get_settings()
            self._redis = aioredis.from_url(settings.REDIS_URL, decode_responses=True)
        return self._redis

    async def publish(self, user_id: uuid.UUID | str, event: dict) -> None:
        """Push an event to all subscribers for this user (across all workers)."""
        r = await self._get_redis()
        channel = f"{_CHANNEL_PREFIX}{user_id}"
        await r.publish(channel, json.dumps(event, ensure_ascii=False))

    async def subscribe(self, user_id: uuid.UUID | str):
        """Async generator that yields events for this user via Redis Pub/Sub."""
        r = await self._get_redis()
        pubsub = r.pubsub()
        channel = f"{_CHANNEL_PREFIX}{user_id}"
        await pubsub.subscribe(channel)
        try:
            while True:
                msg = await pubsub.get_message(
                    ignore_subscribe_messages=True, timeout=1.0
                )
                if msg and msg["type"] == "message":
                    try:
                        yield json.loads(msg["data"])
                    except (json.JSONDecodeError, TypeError):
                        pass
                else:
                    # Yield control so WebSocket can detect disconnects
                    await asyncio.sleep(0.05)
        finally:
            await pubsub.unsubscribe(channel)
            await pubsub.aclose()


event_bus = EventBus()
