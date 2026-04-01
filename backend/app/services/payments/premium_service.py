from datetime import date, timezone, datetime

from app.database import supabase
from app.services.payments.razorpay_service import get_razorpay_service


def collect_weekly_premiums() -> dict:
    """
    Called by the Monday cron.
    For every driver with an active subscription + active mandate,
    creates a Razorpay order and triggers a recurring UPI AutoPay charge.
    A pending premium_payment row is inserted; the webhook updates it to success/failed.
    """
    week_start = date.today().isoformat()

    # Get active subscriptions with active mandates, join drivers for phone
    subs = supabase.table("subscriptions") \
        .select("id, driver_id, actual_premium, drivers(phone)") \
        .eq("status", "active") \
        .eq("mandate_status", "active") \
        .execute()

    if not subs.data:
        return {"success": 0, "failed": []}

    # Build token lookup map
    mandate_rows = supabase.table("razorpay_mandates") \
        .select("driver_id, razorpay_token_id") \
        .eq("status", "active") \
        .execute()

    token_map = {
        m["driver_id"]: m["razorpay_token_id"]
        for m in (mandate_rows.data or [])
        if m.get("razorpay_token_id")
    }

    razorpay_svc = get_razorpay_service()
    success = 0
    failed = []

    for sub in subs.data:
        driver_id = sub["driver_id"]
        token_id = token_map.get(driver_id)
        phone = (sub.get("drivers") or {}).get("phone")

        if not token_id:
            failed.append({"driver_id": driver_id, "reason": "No active mandate token"})
            continue

        if not phone:
            failed.append({"driver_id": driver_id, "reason": "No phone on record"})
            continue

        amount = float(sub["actual_premium"])
        amount_paise = int(amount * 100)

        try:
            order = razorpay_svc.create_order(
                amount_paise=amount_paise,
                receipt=f"prem_{driver_id[:8]}_{week_start}",
                notes={"driver_id": driver_id, "type": "weekly_premium", "week": week_start},
            )

            razorpay_svc.create_recurring_payment(
                amount_paise=amount_paise,
                order_id=order["id"],
                token_id=token_id,
                phone=phone,
                description=f"KavachNidhi premium — {week_start}",
            )

            # Insert pending row; webhook will mark it success/failed
            supabase.table("premium_payments").insert({
                "driver_id": driver_id,
                "subscription_id": sub["id"],
                "amount": amount,
                "week_start": week_start,
                "status": "pending",
            }).execute()

            success += 1

        except Exception as e:
            failed.append({"driver_id": driver_id, "reason": str(e)})

    return {"success": success, "failed": failed}
