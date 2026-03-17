"""In-process event bus for pushing real-time status changes to clients.

Usage:
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
import uuid
from collections import defaultdict


class EventBus:
    """Simple async pub/sub keyed by user_id."""

    def __init__(self):
        # user_id_str -> set of asyncio.Queue
        self._subscribers: dict[str, set[asyncio.Queue]] = defaultdict(set)

    async def publish(self, user_id: uuid.UUID | str, event: dict) -> None:
        """Push an event to all subscribers for this user."""
        key = str(user_id)
        for q in list(self._subscribers.get(key, [])):
            try:
                q.put_nowait(event)
            except asyncio.QueueFull:
                pass  # Drop if consumer is too slow

    async def subscribe(self, user_id: uuid.UUID | str):
        """Async generator that yields events for this user."""
        key = str(user_id)
        q: asyncio.Queue = asyncio.Queue(maxsize=100)
        self._subscribers[key].add(q)
        try:
            while True:
                event = await q.get()
                yield event
        finally:
            self._subscribers[key].discard(q)
            if not self._subscribers[key]:
                del self._subscribers[key]


event_bus = EventBus()
