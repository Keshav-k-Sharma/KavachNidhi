"""
KavachBrain Engine — master 60-second APScheduler loop.

Every tick:
  1. cyclone_guard_module()  — storm check for coastal cities
  2. fog_block_module()      — visibility check for northern cities (04–10 IST)
  3. traffic_block_module()  — congestion check for all major cities
  4. award_credits()         — write driver_trigger_logs for eligible drivers
  5. broadcast_realtime()    — push alerts to Supabase Realtime by city

Risk scores are recalculated separately by the nightly cron_service.py job.
"""
import logging
from datetime import datetime, timezone

from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.interval import IntervalTrigger

from app.config import settings
from app.database import db as supabase
from app.services.kavachbrain.cyclone_guard       import check_cyclones_for_cities
from app.services.kavachbrain.fog_block            import check_fog_for_cities
from app.services.kavachbrain.traffic_block        import check_traffic_for_cities
from app.services.kavachbrain.credit_engine        import award_credits
from app.services.kavachbrain.realtime_broadcaster import broadcast_trigger

logger = logging.getLogger(__name__)

INTERVAL_SECONDS = settings.KAVACHBRAIN_INTERVAL_SECONDS

_scheduler: BackgroundScheduler | None = None


# ── Zone helpers ──────────────────────────────────────────────────────────────

def _fetch_active_zones() -> list[dict]:
    result = (
        supabase.table("city_zones")
        .select("id, city, cyclone_eligible, fog_eligible, location_risk")
        .execute()
    )
    return result.data or []


def _record_sensor_event(
    city: str,
    zone_id: str,
    event_type: str,
    raw_value: dict,
    severity: float,
    source: str,
) -> None:
    """Persist a raw sensor event for audit trail."""
    try:
        supabase.table("sensor_events").insert({
            "city":        city,
            "zone_id":     zone_id,
            "event_type":  event_type,
            "raw_value":   raw_value,
            "severity":    severity,
            "source":      source,
            "recorded_at": datetime.now(timezone.utc).isoformat(),
        }).execute()
    except Exception as exc:
        logger.warning("[engine] Failed to record sensor_event: %s", exc)


# ── Module functions ──────────────────────────────────────────────────────────

def cyclone_guard_module(zones: list[dict]) -> list[dict]:
    """Check coastal cities for storm conditions. Returns fired events."""
    coastal      = [z for z in zones if z.get("cyclone_eligible")]
    cities       = list({z["city"] for z in coastal})
    city_to_zone = {z["city"]: z for z in coastal}

    if not cities:
        return []

    readings = check_cyclones_for_cities(cities)
    fired: list[dict] = []

    for reading in readings:
        zone = city_to_zone.get(reading.city)
        if not zone:
            continue

        _record_sensor_event(
            city       = reading.city,
            zone_id    = zone["id"],
            event_type = "cyclone",
            raw_value  = {"wind_kmh": reading.wind_kmh, "has_alert": reading.has_alert},
            severity   = reading.severity,
            source     = reading.source,
        )

        if reading.triggered:
            logger.info("[engine] CycloneGuard FIRED city=%s severity=%.2f", reading.city, reading.severity)
            fired.append({
                "event_type": "cyclone",
                "city":       reading.city,
                "zone_id":    zone["id"],
                "severity":   reading.severity,
                "source":     reading.source,
            })

    return fired


def fog_block_module(zones: list[dict]) -> list[dict]:
    """Check northern cities for fog (04–10 IST window). Returns fired events."""
    foggy        = [z for z in zones if z.get("fog_eligible")]
    cities       = list({z["city"] for z in foggy})
    city_to_zone = {z["city"]: z for z in foggy}

    if not cities:
        return []

    readings = check_fog_for_cities(cities)
    fired: list[dict] = []

    for reading in readings:
        zone = city_to_zone.get(reading.city)
        if not zone:
            continue

        _record_sensor_event(
            city       = reading.city,
            zone_id    = zone["id"],
            event_type = "fog",
            raw_value  = {"visibility_m": reading.visibility_m, "in_time_window": reading.in_time_window},
            severity   = reading.severity,
            source     = reading.source,
        )

        if reading.triggered:
            logger.info(
                "[engine] FogBlock FIRED city=%s visibility=%.1fm severity=%.2f",
                reading.city, reading.visibility_m, reading.severity,
            )
            fired.append({
                "event_type": "fog",
                "city":       reading.city,
                "zone_id":    zone["id"],
                "severity":   reading.severity,
                "source":     reading.source,
            })

    return fired


def traffic_block_module(zones: list[dict]) -> list[dict]:
    """Check all cities for deep congestion. Returns fired events."""
    cities       = list({z["city"] for z in zones})
    city_to_zone = {z["city"]: z for z in zones}

    if not cities:
        return []

    readings = check_traffic_for_cities(cities)
    fired: list[dict] = []

    for reading in readings:
        zone = city_to_zone.get(reading.city)
        if not zone:
            continue

        _record_sensor_event(
            city       = reading.city,
            zone_id    = zone["id"],
            event_type = "traffic",
            raw_value  = {
                "current_speed":   reading.current_speed,
                "free_flow_speed": reading.free_flow_speed,
                "ratio":           reading.ratio,
            },
            severity   = reading.severity,
            source     = reading.source,
        )

        if reading.triggered:
            logger.info(
                "[engine] TrafficBlock FIRED city=%s ratio=%.2f delay=%.1fmin",
                reading.city, reading.ratio, reading.delay_minutes,
            )
            fired.append({
                "event_type":    "traffic",
                "city":          reading.city,
                "zone_id":       zone["id"],
                "severity":      reading.severity,
                "delay_minutes": reading.delay_minutes,
                "source":        reading.source,
            })

    return fired


# ── Main tick ─────────────────────────────────────────────────────────────────

def _run_tick() -> None:
    """Single execution of the KavachBrain loop."""
    logger.debug("[engine] Tick started at %s", datetime.now(timezone.utc).isoformat())

    try:
        zones = _fetch_active_zones()
    except Exception as exc:
        logger.error("[engine] Failed to fetch zones: %s", exc)
        return

    # 1–3. Detect conditions
    fired_events: list[dict] = []
    try:
        fired_events += cyclone_guard_module(zones)
    except Exception as exc:
        logger.error("[engine] cyclone_guard_module error: %s", exc)

    try:
        fired_events += fog_block_module(zones)
    except Exception as exc:
        logger.error("[engine] fog_block_module error: %s", exc)

    try:
        fired_events += traffic_block_module(zones)
    except Exception as exc:
        logger.error("[engine] traffic_block_module error: %s", exc)

    # 4. Award credits — carry severity + eligible_tier into result for broadcast
    credit_results: list[dict] = []
    for event in fired_events:
        try:
            result = award_credits(
                event_type    = event["event_type"],
                city          = event["city"],
                zone_id       = event["zone_id"],
                severity      = event["severity"],
                delay_minutes = event.get("delay_minutes", 0.0),
            )
            # Bug #2 fix: merge severity + eligible_tier from the fired event
            # award_credits() does not return these, so we carry them forward here
            result["severity"]      = event["severity"]
            result["eligible_tier"] = result.get("eligible_tier", "all")
            credit_results.append(result)
        except Exception as exc:
            logger.error(
                "[engine] award_credits failed for event=%s city=%s: %s",
                event["event_type"], event["city"], exc,
            )

    # 5. Broadcast realtime alerts
    for credit_result in credit_results:
        try:
            if credit_result.get("trigger_event_id"):
                broadcast_trigger(
                    city             = credit_result["city"],
                    event_type       = credit_result["event_type"],
                    severity         = credit_result["severity"],
                    credits          = credit_result["credits"],
                    trigger_event_id = credit_result["trigger_event_id"],
                    eligible_tier    = credit_result["eligible_tier"],
                    drivers_notified = credit_result.get("awarded", 0),
                )
        except Exception as exc:
            logger.error("[engine] broadcast_realtime error: %s", exc)

    if fired_events:
        logger.info("[engine] Tick done — %d event(s) fired.", len(fired_events))
    else:
        logger.debug("[engine] Tick done — no events triggered.")


# ── Lifecycle ─────────────────────────────────────────────────────────────────

def start_kavachbrain() -> None:
    """Start the KavachBrain scheduler. Call once on app startup."""
    global _scheduler
    if _scheduler and _scheduler.running:
        return

    _scheduler = BackgroundScheduler()
    _scheduler.add_job(
        _run_tick,
        trigger=IntervalTrigger(seconds=INTERVAL_SECONDS),
        id="kavachbrain_tick",
        replace_existing=True,
        max_instances=1,
    )
    _scheduler.start()
    logger.info("[engine] KavachBrain started — interval=%ds", INTERVAL_SECONDS)


def stop_kavachbrain() -> None:
    """Cleanly shut down KavachBrain on app teardown."""
    global _scheduler
    if _scheduler and _scheduler.running:
        _scheduler.shutdown(wait=False)
        logger.info("[engine] KavachBrain stopped")