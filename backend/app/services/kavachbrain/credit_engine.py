"""
CreditEngine — determines eligible drivers for a trigger event and writes
to driver_trigger_logs. Called by the KavachBrain engine after a trigger fires.
"""
import logging
from datetime import datetime, timezone, timedelta

from app.database import db as supabase

logger = logging.getLogger(__name__)

# ── Payout config ─────────────────────────────────────────────────────────────

CYCLONE_BASE_PAYOUT  = 300.0   # ₹ max, scaled by severity
FOG_BASE_PAYOUT      = 120.0   # ₹ max
FOG_MIN_PAYOUT       = 80.0    # ₹ min
TRAFFIC_PER_MINUTE   = 2.0     # ₹/min
TRAFFIC_MAX_PAYOUT   = 120.0   # ₹/day

TIER_ELIGIBILITY: dict[str, list[str]] = {
    "cyclone": ["basic", "plus", "max"],
    "fog":     ["plus", "max"],
    "traffic": ["max"],
}

MAX_PAYOUTS_PER_WEEK = 5


# ── Payout calculators ────────────────────────────────────────────────────────

def _cyclone_payout(severity: float) -> float:
    return round(max(50.0, CYCLONE_BASE_PAYOUT * severity), 2)


def _fog_payout(severity: float) -> float:
    raw = FOG_MIN_PAYOUT + (FOG_BASE_PAYOUT - FOG_MIN_PAYOUT) * severity
    return round(raw, 2)


def _traffic_payout(delay_minutes: float) -> float:
    return round(min(TRAFFIC_MAX_PAYOUT, delay_minutes * TRAFFIC_PER_MINUTE), 2)


# ── Core ──────────────────────────────────────────────────────────────────────

def _fetch_eligible_drivers(zone_id: str, eligible_tiers: list[str]) -> list[dict]:
    """Return active drivers in the zone whose tier is eligible."""
    result = (
        supabase.table("drivers")
        .select("id, subscription_tier")
        .eq("zone_id", zone_id)
        .eq("is_active", True)
        .in_("subscription_tier", eligible_tiers)
        .execute()
    )
    return result.data or []


def _weekly_payout_count(driver_id: str) -> int:
    """Count how many trigger payouts this driver received in the last 7 days."""
    seven_days_ago = (datetime.now(timezone.utc) - timedelta(days=7)).isoformat()
    result = (
        supabase.table("driver_trigger_logs")
        .select("id", count="exact")
        .eq("driver_id", driver_id)
        .gte("awarded_at", seven_days_ago)
        .execute()
    )
    return result.count or 0


def _insert_trigger_event(
    event_type: str,
    city: str,
    zone_id: str,
    severity_multiplier: float,
    credits_per_driver: float,
    eligible_tier: str,
    drivers_notified: int,
    expires_at: str,
) -> str:
    """Insert a trigger_events row and return its id."""
    row = {
        "event_type":          event_type,
        "city":                city,
        "zone_id":             zone_id,
        "severity_multiplier": severity_multiplier,
        "credits_per_driver":  credits_per_driver,
        "eligible_tier":       eligible_tier,
        "drivers_notified":    drivers_notified,
        "triggered_at":        datetime.now(timezone.utc).isoformat(),
        "expires_at":          expires_at,
    }
    result = supabase.table("trigger_events").insert(row).execute()
    return result.data[0]["id"]


def _award_driver(
    driver_id: str,
    trigger_event_id: str,
    credits: float,
    held: bool = False,
    fraud_flag_id: str | None = None,
) -> None:
    supabase.table("driver_trigger_logs").insert({
        "driver_id":        driver_id,
        "trigger_event_id": trigger_event_id,
        "credits_awarded":  credits,
        "status":           "held" if held else "awarded",
        "fraud_flag_id":    fraud_flag_id,
        "awarded_at":       datetime.now(timezone.utc).isoformat(),
    }).execute()


# ── Public ────────────────────────────────────────────────────────────────────

def award_credits(
    event_type: str,
    city: str,
    zone_id: str,
    severity: float,
    delay_minutes: float = 0.0,
    expires_at: str | None = None,
) -> dict:
    """
    Main entry point called by the KavachBrain engine.
    Creates a trigger_event, finds eligible drivers, writes driver_trigger_logs.
    Returns summary dict.
    """
    eligible_tiers = TIER_ELIGIBILITY.get(event_type, [])
    if not eligible_tiers:
        logger.warning("[credit_engine] Unknown event_type=%s", event_type)
        return {"awarded": 0, "held": 0}

    if event_type == "cyclone":
        credits = _cyclone_payout(severity)
    elif event_type == "fog":
        credits = _fog_payout(severity)
    elif event_type == "traffic":
        credits = _traffic_payout(delay_minutes)
    else:
        credits = 0.0

    if credits <= 0:
        logger.info("[credit_engine] Zero credits for event_type=%s, skipping.", event_type)
        return {"awarded": 0, "held": 0}

    if expires_at is None:
        expires_at = (datetime.now(timezone.utc) + timedelta(hours=6)).isoformat()

    eligible_tier_label = "all" if set(eligible_tiers) == {"basic", "plus", "max"} else eligible_tiers[-1]

    drivers = _fetch_eligible_drivers(zone_id, eligible_tiers)
    if not drivers:
        logger.info("[credit_engine] No eligible drivers in zone=%s for event=%s", zone_id, event_type)
        return {"awarded": 0, "held": 0}

    trigger_event_id = _insert_trigger_event(
        event_type          = event_type,
        city                = city,
        zone_id             = zone_id,
        severity_multiplier = severity,
        credits_per_driver  = credits,
        eligible_tier       = eligible_tier_label,
        drivers_notified    = len(drivers),
        expires_at          = expires_at,
    )

    awarded = 0
    held    = 0

    for driver in drivers:
        driver_id  = driver["id"]
        week_count = _weekly_payout_count(driver_id)

        if week_count >= MAX_PAYOUTS_PER_WEEK:
            _award_driver(driver_id, trigger_event_id, credits, held=True)
            held += 1
            logger.info("[credit_engine] driver=%s held (weekly cap: %d)", driver_id, week_count)
        else:
            _award_driver(driver_id, trigger_event_id, credits, held=False)
            awarded += 1

    logger.info(
        "[credit_engine] event=%s city=%s zone=%s  awarded=%d held=%d credits=₹%.2f",
        event_type, city, zone_id, awarded, held, credits,
    )
    return {
        "trigger_event_id": trigger_event_id,
        "event_type":       event_type,
        "city":             city,
        "credits":          credits,
        "eligible_tier":    eligible_tier_label,
        "awarded":          awarded,
        "held":             held,
    }