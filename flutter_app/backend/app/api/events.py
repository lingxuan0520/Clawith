"""WebSocket endpoint for real-time event notifications.

Clients connect once and receive all agent status changes for the current user.
This replaces polling / manual refresh for the virtual office.
"""

import uuid

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query

from app.core.security import decode_access_token
from app.services.event_bus import event_bus

router = APIRouter(tags=["events"])


@router.websocket("/ws/events")
async def websocket_events(
    websocket: WebSocket,
    token: str = Query(...),
):
    """Push real-time events (agent status changes, etc.) to the client.

    Connect: ws://<host>/ws/events?token=<jwt>
    Receive: {"type": "agent_status", "agent_id": "...", "status": "running"}
    """
    await websocket.accept()

    # Authenticate
    try:
        payload = decode_access_token(token)
        user_id = uuid.UUID(payload["sub"])
    except Exception:
        await websocket.send_json({"type": "error", "content": "Authentication failed"})
        await websocket.close(code=4001)
        return

    print(f"[Events WS] Connected: user={user_id}")

    try:
        async for event in event_bus.subscribe(user_id):
            try:
                await websocket.send_json(event)
            except Exception:
                break
    except WebSocketDisconnect:
        pass
    except Exception as e:
        print(f"[Events WS] Error: {e}")
    finally:
        print(f"[Events WS] Disconnected: user={user_id}")
