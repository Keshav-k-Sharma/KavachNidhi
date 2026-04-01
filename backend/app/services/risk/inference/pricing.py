

from dataclasses import dataclass



BASE_PREMIUM_INR: float = 70.0      # ₹ flat base per week
RISK_MULTIPLIER: float  = 0.20      # each 1.0 of risk adds 20 % on top of base

# Tier floor — ensure higher-tier drivers always pay at least a bit more
TIER_FLOOR: dict[float, float] = {
    0.2: 0.0,    # basic  — no floor adjustment
    0.5: 5.0,    # plus   — ₹5 floor bump
    1.0: 12.0,   # max    — ₹12 floor bump
}

# Hard bounds (guardrails for edge cases)
MIN_PREMIUM_INR: float = 50.0
MAX_PREMIUM_INR: float = 200.0



@dataclass
class PricingBreakdown:
    risk_score:      float   
    base_premium:    float   
    risk_loading:    float   
    tier_floor_bump: float   
    weekly_premium:  float   



def calculate_premium(risk_score: float, tier: float = 0.2) -> PricingBreakdown:
    risk_score = max(0.0, min(1.0, risk_score))  

    base         = BASE_PREMIUM_INR
    risk_loading = base * RISK_MULTIPLIER * risk_score
    floor_bump   = TIER_FLOOR.get(tier, 0.0)

    raw_premium = base + risk_loading + floor_bump
    final       = max(MIN_PREMIUM_INR, min(MAX_PREMIUM_INR, raw_premium))

    return PricingBreakdown(
        risk_score      = round(risk_score, 4),
        base_premium    = round(base, 2),
        risk_loading    = round(risk_loading, 2),
        tier_floor_bump = round(floor_bump, 2),
        weekly_premium  = round(final, 2),
    )