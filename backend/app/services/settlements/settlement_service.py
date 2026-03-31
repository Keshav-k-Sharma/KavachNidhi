from datetime import datetime, timezone
from app.database import db
from app.services.payments.razorpay_service import get_razorpay_service
from app.services.audit.ledger_service import append as ledger_append


def get_driver_credits(driver_id: str) -> float:
    result = db.table("driver_trigger_logs") \
        .select("credits_awarded") \
        .eq("driver_id", driver_id) \
        .eq("status", "awarded") \
        .execute()

    if not result.data:
        return 0.0

    total = sum(row["credits_awarded"] for row in result.data)
    return float(total)


def get_active_drivers() -> list:
    result = db.table("subscriptions") \
        .select("driver_id, drivers(upi_id)") \
        .eq("status", "active") \
        .execute()

    return result.data if result.data else []


def create_settlement_run(run_type: str) -> dict:
    result = db.table("settlement_runs").insert({
        "run_type": run_type,
        "status": "running",
        "triggered_at": datetime.now(timezone.utc).isoformat(),
        "total_drivers": 0,
        "total_amount": 0.0,
    }).execute()

    return result.data[0]


def update_settlement_run(run_id: str, total_drivers: int, total_amount: float, status: str):
    db.table("settlement_runs").update({
        "total_drivers": total_drivers,
        "total_amount": total_amount,
        "status": status,
        "completed_at": datetime.now(timezone.utc).isoformat(),
    }).eq("id", run_id).execute()


def settle_driver(driver_id: str, upi_id: str, amount: float, run_id: str):
    razorpay = get_razorpay_service()

    amount_paise = int(amount * 100)
    payout_response = razorpay.create_payout(upi_id, amount_paise, driver_id)

    payout_result = db.table("payouts").insert({
        "driver_id": driver_id,
        "settlement_run_id": run_id,
        "amount": amount,
        "upi_id": upi_id,
        "razorpay_payout_id": payout_response.get("id"),
        "status": "processed",
        "processed_at": datetime.now(timezone.utc).isoformat(),
    }).execute()

    db.table("wallets").update({
        "shield_credits": 0.0,
        "last_settled_at": datetime.now(timezone.utc).isoformat(),
        "last_settlement_amount": amount,
    }).eq("driver_id", driver_id).execute()

    db.table("wallet_transactions").insert({
        "driver_id": driver_id,
        "type": "settlement",
        "amount": amount,
        "description": f"Sunday settlement — ₹{amount} sent to {upi_id}",
    }).execute()

    ledger_append(
        entry_type="settlement",
        driver_id=driver_id,
        amount=amount,
        reference_id=payout_result.data[0]["id"],
        description=f"Settlement payout to {upi_id}"
    )
    db.table("driver_trigger_logs").update({
    "status": "settled"
    }).eq("driver_id", driver_id).eq("status", "awarded").execute()


def run_settlement(run_type: str = "scheduled") -> dict:
    run = create_settlement_run(run_type)
    run_id = run["id"]

    drivers = get_active_drivers()

    total_amount = 0.0
    total_drivers = 0
    failed = []

    for driver in drivers:
        driver_id = driver["driver_id"]
        upi_id = driver.get("drivers", {}).get("upi_id")

        if not upi_id:
            failed.append({"driver_id": driver_id, "reason": "No UPI ID"})
            continue

        credits = get_driver_credits(driver_id)

        if credits <= 0:
            continue

        try:
            settle_driver(driver_id, upi_id, credits, run_id)
            total_amount += credits
            total_drivers += 1
        except Exception as e:
            failed.append({"driver_id": driver_id, "reason": str(e)})

    update_settlement_run(run_id, total_drivers, total_amount, "completed")

    return {
        "run_id": run_id,
        "total_drivers": total_drivers,
        "total_amount": total_amount,
        "failed": failed,
    }