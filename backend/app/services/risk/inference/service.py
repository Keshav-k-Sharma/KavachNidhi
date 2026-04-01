

import logging
from typing import TypedDict

from app.services.risk.inference.predict import predict_risk_score, predict_risk_scores_batch
from app.services.risk.inference.pricing import calculate_premium

logger = logging.getLogger(__name__)


# ── TypedDicts for IDE autocomplete and validation ────────────────────────────

class RiskInput(TypedDict):
    zone_risk:         float   # city_zones.location_risk — 0.0 to 1.0
    trigger_frequency: float   # events last 90d / max possible — 0.0 to 1.0
    avg_payout:        float   # mean historical payout — 50 to 200
    tier:              float   # 0.2 = basic | 0.5 = plus | 1.0 = max


class RiskOutput(TypedDict):
    risk_score:      float   # composite ML score — 0.0 to 1.0
    weekly_premium:  float   # ₹ per week
    base_premium:    float   # breakdown: base
    risk_loading:    float   # breakdown: risk-driven uplift
    tier_floor_bump: float   # breakdown: tier minimum bump


# ── Validation helpers ────────────────────────────────────────────────────────

_VALID_TIERS = {0.2, 0.5, 1.0}

def _validate(data: dict) -> None:
    
    required = ["zone_risk", "trigger_frequency", "avg_payout", "tier"]
    for field in required:
        if field not in data:
            raise ValueError(f"Missing required field: '{field}'")

    if not (0.0 <= data["zone_risk"] <= 1.0):
        raise ValueError(f"zone_risk must be in [0, 1], got {data['zone_risk']}")

    if not (0.0 <= data["trigger_frequency"] <= 1.0):
        raise ValueError(f"trigger_frequency must be in [0, 1], got {data['trigger_frequency']}")

    if not (50.0 <= data["avg_payout"] <= 200.0):
        raise ValueError(f"avg_payout must be in [50, 200], got {data['avg_payout']}")

    if data["tier"] not in _VALID_TIERS:
        raise ValueError(f"tier must be one of {_VALID_TIERS}, got {data['tier']}")


# ── Public functions ──────────────────────────────────────────────────────────

def get_pricing(data: RiskInput) -> RiskOutput:
    _validate(data)

    risk_score = predict_risk_score(
        zone_risk          = data["zone_risk"],
        trigger_frequency  = data["trigger_frequency"],
        avg_payout         = data["avg_payout"],
        tier               = data["tier"],
    )

    breakdown = calculate_premium(risk_score, tier=data["tier"])

    logger.debug(
        "[service] driver risk_score=%.4f  premium=₹%.2f",
        breakdown.risk_score,
        breakdown.weekly_premium,
    )

    return RiskOutput(
        risk_score      = breakdown.risk_score,
        weekly_premium  = breakdown.weekly_premium,
        base_premium    = breakdown.base_premium,
        risk_loading    = breakdown.risk_loading,
        tier_floor_bump = breakdown.tier_floor_bump,
    )


def get_pricing_batch(records: list[RiskInput]) -> list[RiskOutput]:
    
    for i, r in enumerate(records):
        try:
            _validate(r)
        except ValueError as e:
            raise ValueError(f"Record at index {i} failed validation: {e}") from e

    risk_scores = predict_risk_scores_batch(records)

    results: list[RiskOutput] = []
    for record, score in zip(records, risk_scores):
        breakdown = calculate_premium(score, tier=record["tier"])
        results.append(RiskOutput(
            risk_score      = breakdown.risk_score,
            weekly_premium  = breakdown.weekly_premium,
            base_premium    = breakdown.base_premium,
            risk_loading    = breakdown.risk_loading,
            tier_floor_bump = breakdown.tier_floor_bump,
        ))

    return results