
from dataclasses import dataclass

# ── Config ────────────────────────────────────────────────────────────────────

TIER_BASE_RATES: dict[float, float] = {
    0.2: 50.0,   
    0.5: 70.0,   
    1.0: 90.0,   
}

RISK_MULTIPLIER: float = 0.5   

MIN_PREMIUM_INR: float = 50.0
MAX_PREMIUM_INR: float = 135.0  


# ── Breakdown dataclass ───────────────────────────────────────────────────────

@dataclass
class PricingBreakdown:
    risk_score:     float   
    base_rate:      float   
    risk_loading:   float   
    weekly_premium: float   


# ── Core function ─────────────────────────────────────────────────────────────

def calculate_premium(risk_score: float, tier: float = 0.2) -> PricingBreakdown:
    
    risk_score = max(0.0, min(1.0, risk_score))
    base_rate  = TIER_BASE_RATES.get(tier, TIER_BASE_RATES[0.2])

    risk_loading  = base_rate * RISK_MULTIPLIER * risk_score
    raw_premium   = base_rate + risk_loading
    final_premium = max(MIN_PREMIUM_INR, min(MAX_PREMIUM_INR, raw_premium))

    return PricingBreakdown(
        risk_score     = round(risk_score, 4),
        base_rate      = round(base_rate, 2),
        risk_loading   = round(risk_loading, 2),
        weekly_premium = round(final_premium, 2),
    )