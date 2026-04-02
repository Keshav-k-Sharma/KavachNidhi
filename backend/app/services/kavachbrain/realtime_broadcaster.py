"""
RealtimeBroadcaster — pushes trigger alert payloads to Supabase Realtime
channels so the Flutter app can subscribe per city.

Channel naming: `city:{city_name}` (e.g. "city:mumbai")
"""
import logging
import httpx

from app.config import settings

logger = logging.getLogger(__name__)

SUPABASE_URL              = settings.SUPABASE_URL
SUPABASE_SERVICE_ROLE_KEY = settings.SUPABASE_SERVICE_ROLE_KEY
BROADCAST_ENDPOINT        = f"{SUPABASE_URL}/realtime/v1/api/broadcast"


def _channel_name(city: str) -> str:
    return f"city:{city.strip().lower().replace(' ', '_')}"


def broadcast_trigger(
    city:             str,
    event_type:       str,
    severity:         float,
    credits:          float,
    trigger_event_id: str,
    eligible_tier:    str,
    drivers_notified: int,
) -> bool:
    """
    Broadcast a trigger alert to the city's Realtime channel.
    Returns True on success, False on failure.
    """
    channel = _channel_name(city)
    payload = {
        "messages": [
            {
                "topic":   channel,
                "event":   "trigger_alert",
                "payload": {
                    "event_type":       event_type,
                    "city":             city,
                    "severity":         severity,
                    "credits":          credits,
                    "trigger_event_id": trigger_event_id,
                    "eligible_tier":    eligible_tier,
                    "drivers_notified": drivers_notified,
                },
            }
        ]
    }

    if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
        logger.warning("[broadcaster] Supabase credentials missing — skipping broadcast for city=%s", city)
        return False

    try:
        resp = httpx.post(
            BROADCAST_ENDPOINT,
            json=payload,
            headers={
                "apikey":        SUPABASE_SERVICE_ROLE_KEY,
                "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
                "Content-Type":  "application/json",
            },
            timeout=8,
        )
        resp.raise_for_status()
        logger.info(
            "[broadcaster] Broadcast sent → channel=%s  event=%s  severity=%.2f",
            channel, event_type, severity,
        )
        return True

    except httpx.HTTPStatusError as exc:
        logger.error("[broadcaster] HTTP error %s for channel=%s: %s", exc.response.status_code, channel, exc)
    except Exception as exc:
        logger.error("[broadcaster] Unexpected error for channel=%s: %s", channel, exc)

    return False


def broadcast_many(events: list[dict]) -> dict:
    sent = failed = 0
    for ev in events:
        if broadcast_trigger(**ev):
            sent += 1
        else:
            failed += 1
    return {"sent": sent, "failed": failed}