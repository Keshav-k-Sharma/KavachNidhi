
import logging
from uuid import UUID
from datetime import datetime, timezone

from app.services.risk.inference.service import get_pricing, get_pricing_batch

logger = logging.getLogger(__name__)


# ── Tier encoding helper ──────────────────────────────────────────────────────

TIER_MAP: dict[str, float] = {
    "basic": 0.2,
    "plus":  0.5,
    "max":   1.0,
}


def encode_tier(tier_str: str) -> float:
    
    return TIER_MAP.get(tier_str.lower(), 0.2)


# ── Single driver ─────────────────────────────────────────────────────────────

async def recalculate_driver(driver_id: UUID, db) -> dict:
    
    # 1. Pull driver + zone data
    
    row = await db.execute(
        """
        SELECT
            d.id              AS driver_id,
            d.subscription_tier,
            cz.location_risk,
            COALESCE(
                (SELECT COUNT(*)::float / NULLIF(90, 0)
                   FROM driver_trigger_logs dtl
                  WHERE dtl.driver_id = d.id
                    AND dtl.awarded_at > NOW() - INTERVAL '90 days'),
                0.0
            )                 AS trigger_frequency,
            COALESCE(
                (SELECT AVG(dtl.credits_awarded)
                   FROM driver_trigger_logs dtl
                  WHERE dtl.driver_id = d.id),
                100.0
            )                 AS avg_payout
        FROM drivers d
        JOIN city_zones cz ON cz.id = d.zone_id
        WHERE d.id = :driver_id
        """,
        {"driver_id": str(driver_id)},
    )
    record = row.mappings().first()

    if not record:
        raise ValueError(f"Driver {driver_id} not found or has no zone assignment")

    tier_float = encode_tier(record["subscription_tier"])

    # 2. Get ML pricing output
    pricing = get_pricing({
        "zone_risk":         float(record["location_risk"]),
        "trigger_frequency": float(record["trigger_frequency"]),
        "avg_payout":        float(max(50.0, min(200.0, record["avg_payout"]))),
        "tier":              tier_float,
    })

    # 3. Upsert into risk_scores
    now = datetime.now(timezone.utc)
    await db.execute(
        """
        INSERT INTO risk_scores
            (driver_id, location_risk, trigger_frequency, tier_risk,
             composite_score, last_calculated_at)
        VALUES
            (:driver_id, :location_risk, :trigger_frequency, :tier_risk,
             :composite_score, :last_calculated_at)
        ON CONFLICT (driver_id) DO UPDATE SET
            location_risk       = EXCLUDED.location_risk,
            trigger_frequency   = EXCLUDED.trigger_frequency,
            tier_risk           = EXCLUDED.tier_risk,
            composite_score     = EXCLUDED.composite_score,
            last_calculated_at  = EXCLUDED.last_calculated_at
        """,
        {
            "driver_id":          str(driver_id),
            "location_risk":      record["location_risk"],
            "trigger_frequency":  record["trigger_frequency"],
            "tier_risk":          tier_float,
            "composite_score":    pricing["risk_score"],
            "last_calculated_at": now,
        },
    )
    await db.commit()

    logger.info(
        "[risk_calculator] driver=%s  composite_score=%.4f  premium=₹%.2f",
        driver_id,
        pricing["risk_score"],
        pricing["weekly_premium"],
    )

    return {
        "driver_id":       str(driver_id),
        "composite_score": pricing["risk_score"],
        "weekly_premium":  pricing["weekly_premium"],
        "recalculated_at": now.isoformat(),
    }


# ── Bulk recalculate (APScheduler / POST /risk/recalculate) ───────────────────

async def recalculate_all(db) -> dict:
    
    rows = await db.execute(
        """
        SELECT
            d.id              AS driver_id,
            d.subscription_tier,
            cz.location_risk,
            COALESCE(
                (SELECT COUNT(*)::float / NULLIF(90, 0)
                   FROM driver_trigger_logs dtl
                  WHERE dtl.driver_id = d.id
                    AND dtl.awarded_at > NOW() - INTERVAL '90 days'),
                0.0
            )                 AS trigger_frequency,
            COALESCE(
                (SELECT AVG(dtl.credits_awarded)
                   FROM driver_trigger_logs dtl
                  WHERE dtl.driver_id = d.id),
                100.0
            )                 AS avg_payout
        FROM drivers d
        JOIN city_zones cz ON cz.id = d.zone_id
        WHERE d.is_active = TRUE
        """
    )
    all_drivers = rows.mappings().all()

    if not all_drivers:
        logger.warning("[risk_calculator] recalculate_all: no active drivers found")
        return {"total": 0, "updated": 0, "errors": 0}

    # Build batch input
    batch_input = []
    for r in all_drivers:
        batch_input.append({
            "zone_risk":         float(r["location_risk"]),
            "trigger_frequency": float(r["trigger_frequency"]),
            "avg_payout":        float(max(50.0, min(200.0, r["avg_payout"]))),
            "tier":              encode_tier(r["subscription_tier"]),
        })

    pricing_results = get_pricing_batch(batch_input)

    now = datetime.now(timezone.utc)
    updated = 0
    errors  = 0

    for driver_row, pricing in zip(all_drivers, pricing_results):
        try:
            await db.execute(
                """
                INSERT INTO risk_scores
                    (driver_id, location_risk, trigger_frequency, tier_risk,
                     composite_score, last_calculated_at)
                VALUES
                    (:driver_id, :location_risk, :trigger_frequency, :tier_risk,
                     :composite_score, :last_calculated_at)
                ON CONFLICT (driver_id) DO UPDATE SET
                    location_risk       = EXCLUDED.location_risk,
                    trigger_frequency   = EXCLUDED.trigger_frequency,
                    tier_risk           = EXCLUDED.tier_risk,
                    composite_score     = EXCLUDED.composite_score,
                    last_calculated_at  = EXCLUDED.last_calculated_at
                """,
                {
                    "driver_id":          str(driver_row["driver_id"]),
                    "location_risk":      driver_row["location_risk"],
                    "trigger_frequency":  driver_row["trigger_frequency"],
                    "tier_risk":          encode_tier(driver_row["subscription_tier"]),
                    "composite_score":    pricing["risk_score"],
                    "last_calculated_at": now,
                },
            )
            updated += 1
        except Exception as exc:
            logger.error(
                "[risk_calculator] failed for driver %s: %s",
                driver_row["driver_id"], exc
            )
            errors += 1

    await db.commit()
    logger.info(
        "[risk_calculator] recalculate_all done — updated=%d errors=%d",
        updated, errors
    )
    return {"total": len(all_drivers), "updated": updated, "errors": errors}