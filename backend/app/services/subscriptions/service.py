from app.database import db

TIERS = {
    "basic": {"base_rate": 50.00, "cap_amount": 400.00},
    "plus":  {"base_rate": 70.00, "cap_amount": 700.00},
    "max":   {"base_rate": 90.00, "cap_amount": 1000.00},
}

TIER_ORDER = ["basic", "plus", "max"]


def get_tiers() -> list:
    return [
        {
            "tier": tier,
            "base_rate": info["base_rate"],
            "cap_amount": info["cap_amount"],
        }
        for tier, info in TIERS.items()
    ]


def _get_risk_score(driver_id: str) -> float:
    try:
        result = db.table("risk_scores").select("score").eq("driver_id", driver_id).limit(1).execute()
        if result.data:
            return result.data[0]["score"]
    except Exception:
        pass
    return 0.5


def _calculate_premium(base_rate: float, risk_score: float) -> float:
    return round(base_rate * (1 + risk_score * 0.5), 2)


def subscribe(driver_id: str, tier: str) -> dict:
    if tier not in TIERS:
        raise ValueError(f"Invalid tier '{tier}'. Must be one of: basic, plus, max")

    existing = db.table("subscriptions").select("id").eq("driver_id", driver_id).eq("status", "active").limit(1).execute()
    if existing.data:
        raise ValueError("Driver already has an active subscription")

    risk_score = _get_risk_score(driver_id)
    base_rate = TIERS[tier]["base_rate"]
    cap_amount = TIERS[tier]["cap_amount"]
    actual_premium = _calculate_premium(base_rate, risk_score)

    sub = db.table("subscriptions").insert({
        "driver_id": driver_id,
        "tier": tier,
        "status": "active",
        "base_rate": base_rate,
        "cap_amount": cap_amount,
        "actual_premium": actual_premium,
        "mandate_status": "pending",
    }).execute().data[0]

    db.table("subscription_history").insert({
        "driver_id": driver_id,
        "subscription_id": sub["id"],
        "action": "subscribed",
        "new_tier": tier,
    }).execute()

    return sub


def get_active_subscription(driver_id: str) -> dict | None:
    result = db.table("subscriptions").select("*").eq("driver_id", driver_id).eq("status", "active").limit(1).execute()
    return result.data[0] if result.data else None


def upgrade(driver_id: str, new_tier: str) -> dict:
    if new_tier not in TIERS:
        raise ValueError(f"Invalid tier '{new_tier}'. Must be one of: basic, plus, max")

    sub = get_active_subscription(driver_id)
    if not sub:
        raise ValueError("No active subscription found")

    if TIER_ORDER.index(new_tier) <= TIER_ORDER.index(sub["tier"]):
        raise ValueError(f"New tier '{new_tier}' must be higher than current tier '{sub['tier']}'")

    risk_score = _get_risk_score(driver_id)
    base_rate = TIERS[new_tier]["base_rate"]
    cap_amount = TIERS[new_tier]["cap_amount"]
    actual_premium = _calculate_premium(base_rate, risk_score)

    updated = db.table("subscriptions").update({
        "tier": new_tier,
        "base_rate": base_rate,
        "cap_amount": cap_amount,
        "actual_premium": actual_premium,
    }).eq("id", sub["id"]).execute().data[0]

    db.table("subscription_history").insert({
        "driver_id": driver_id,
        "subscription_id": sub["id"],
        "action": "upgraded",
        "old_tier": sub["tier"],
        "new_tier": new_tier,
    }).execute()

    return updated


def cancel(driver_id: str, reason: str | None = None) -> dict:
    sub = get_active_subscription(driver_id)
    if not sub:
        raise ValueError("No active subscription found")

    updated = db.table("subscriptions").update({
        "status": "cancelled",
    }).eq("id", sub["id"]).execute().data[0]

    db.table("subscription_history").insert({
        "driver_id": driver_id,
        "subscription_id": sub["id"],
        "action": "cancelled",
        "old_tier": sub["tier"],
    }).execute()

    return updated


def get_history(driver_id: str) -> list:
    result = db.table("subscription_history").select("*").eq("driver_id", driver_id).order("created_at", desc=True).execute()
    return result.data
