import logging
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, Query

from app.api.deps import get_current_user
from app.config import get_supabase_client
from app.database import db as supabase
from app.schemas import ok, err

router = APIRouter(prefix="/triggers", tags=["triggers"])
logger = logging.getLogger(__name__)


@router.get("/active")
def get_active_triggers(
    city: str | None = Query(None, description="Filter by city name"),
    user=Depends(get_current_user),
):
    """Returns all trigger_events whose expires_at is in the future."""
    try:
        now   = datetime.now(timezone.utc).isoformat()
        query = (
            supabase.table("trigger_events")
            .select("*")
            .gt("expires_at", now)
            .order("triggered_at", desc=True)
        )
        if city:
            query = query.ilike("city", f"%{city}%")
        result = query.execute()
        return ok(result.data or [])
    except Exception as exc:
        logger.error("[triggers/active] %s", exc)
        return err(str(exc))


@router.get("/history")
def get_my_trigger_history(
    limit: int = Query(50, ge=1, le=200),
    user=Depends(get_current_user),
):
    """Returns the calling driver's personal trigger credit history."""
    try:
        driver_id = str(user.id)   # fixed: was user["id"]
        result = (
            supabase.table("driver_trigger_logs")
            .select(
                "id, credits_awarded, status, awarded_at, fraud_flag_id,"
                "trigger_events(event_type, city, triggered_at)"
            )
            .eq("driver_id", driver_id)
            .order("awarded_at", desc=True)
            .limit(limit)
            .execute()
        )
        return ok(result.data or [])
    except Exception as exc:
        logger.error("[triggers/history] %s", exc)
        return err(str(exc))


@router.get("/events")
def get_all_trigger_events(
    city:       str | None = Query(None),
    event_type: str | None = Query(None, description="cyclone | fog | traffic"),
    limit:      int        = Query(100, ge=1, le=500),
    offset:     int        = Query(0, ge=0),
    user=Depends(get_current_user),
):
    """Admin view — all trigger events, filterable by city and event_type."""
    try:
        query = (
            supabase.table("trigger_events")
            .select("*")
            .order("triggered_at", desc=True)
            .range(offset, offset + limit - 1)
        )
        if city:
            query = query.ilike("city", f"%{city}%")
        if event_type:
            query = query.eq("event_type", event_type)
        result = query.execute()
        return ok({"events": result.data or [], "offset": offset, "limit": limit})
    except Exception as exc:
        logger.error("[triggers/events] %s", exc)
        return err(str(exc))