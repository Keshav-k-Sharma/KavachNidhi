
import logging
from uuid import UUID
from datetime import datetime, timezone

from app.config import get_supabase_client
from app.services.risk.inference.service import get_pricing, get_pricing_batch

logger = logging.getLogger(__name__)

# ── Tier encoding ─────────────────────────────────────────────────────────────

TIER_MAP: dict[str, float] = {
    "basic": 0.2,
    "plus":  0.5,
    "max":   1.0,
}


def _encode_tier(tier_str: str) -> float:
    return TIER_MAP.get((tier_str or "").lower(), 0.2)


# ── Read — used by GET /risk/score/{driver_id} ────────────────────────────────

def get_risk_score(driver_id: str) -> dict | None:
    
    supabase = get_supabase_client()
    result = (
        supabase.table("risk_scores")
        .select("driver_id, location_risk, trigger_frequency, tier_risk, composite_score, last_calculated_at")
        .eq("driver_id", str(driver_id))
        .maybe_single()
        .execute()
    )
    return result.data


# ── Write — used by scheduler and POST /risk/recalculate ─────────────────────

def recalculate_driver(driver_id: str) -> dict:
    
    supabase = get_supabase_client()

    # 1. Driver + zone data
    driver_result = (
        supabase.table("drivers")
        .select("id, subscription_tier, zone_id")
        .eq("id", str(driver_id))
        .maybe_single()
        .execute()
    )
    if not driver_result.data:
        raise ValueError(f"Driver {driver_id} not found")

    driver = driver_result.data

    zone_result = (
        supabase.table("city_zones")
        .select("location_risk")
        .eq("id", driver["zone_id"])
        .maybe_single()
        .execute()
    )
    if not zone_result.data:
        raise ValueError(f"Zone not found for driver {driver_id}")

    location_risk = float(zone_result.data["location_risk"])

    # 2. Trigger frequency — count of trigger logs in last 90 days
    logs_result = (
        supabase.table("driver_trigger_logs")
        .select("id", count="exact")
        .eq("driver_id", str(driver_id))
        .gte("awarded_at", _ninety_days_ago())
        .execute()
    )
    raw_count = logs_result.count or 0
    
    trigger_frequency = min(1.0, float(raw_count) / 90.0)

    # 3. Average payout
    avg_result = (
        supabase.table("driver_trigger_logs")
        .select("credits_awarded")
        .eq("driver_id", str(driver_id))
        .execute()
    )
    payouts = [row["credits_awarded"] for row in (avg_result.data or []) if row["credits_awarded"]]
    avg_payout = float(sum(payouts) / len(payouts)) if payouts else 100.0
    avg_payout = max(50.0, min(200.0, avg_payout))

    tier_float = _encode_tier(driver["subscription_tier"])

    # 4. ML inference
    pricing = get_pricing({
        "zone_risk":         location_risk,
        "trigger_frequency": trigger_frequency,
        "avg_payout":        avg_payout,
        "tier":              tier_float,
    })

    # 5. Upsert into risk_scores
    now = datetime.now(timezone.utc).isoformat()
    supabase.table("risk_scores").upsert({
        "driver_id":          str(driver_id),
        "location_risk":      location_risk,
        "trigger_frequency":  trigger_frequency,
        "tier_risk":          tier_float,
        "composite_score":    pricing["risk_score"],
        "last_calculated_at": now,
    }, on_conflict="driver_id").execute()

    logger.info(
        "[risk_calculator] driver=%s  composite_score=%.4f  premium=₹%.2f",
        driver_id, pricing["risk_score"], pricing["weekly_premium"],
    )

    return {
        "driver_id":       str(driver_id),
        "composite_score": pricing["risk_score"],
        "weekly_premium":  pricing["weekly_premium"],
        "recalculated_at": now,
    }


def recalculate_all() -> dict:
    supabase = get_supabase_client()

    drivers_result = (
        supabase.table("drivers")
        .select("id")
        .eq("is_active", True)
        .execute()
    )
    drivers = drivers_result.data or []

    if not drivers:
        logger.warning("[risk_calculator] recalculate_all: no active drivers found")
        return {"total": 0, "updated": 0, "errors": 0}

    updated = 0
    errors  = 0

    for row in drivers:
        try:
            recalculate_driver(row["id"])
            updated += 1
        except Exception as exc:
            logger.error("[risk_calculator] failed for driver %s: %s", row["id"], exc)
            errors += 1

    logger.info("[risk_calculator] recalculate_all — updated=%d errors=%d", updated, errors)
    return {"total": len(drivers), "updated": updated, "errors": errors}


# ── Internal helpers ──────────────────────────────────────────────────────────

def _ninety_days_ago() -> str:
    from datetime import timedelta
    return (datetime.now(timezone.utc) - timedelta(days=90)).isoformat()