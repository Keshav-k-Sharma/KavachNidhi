from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from app.services.settlements.settlement_service import run_settlement
from app.services.payments.razorpay_service import get_razorpay_service
from app.database import db

scheduler = AsyncIOScheduler()


def process_pending_mandates():
    pending = db.table("subscriptions") \
        .select("*") \
        .eq("mandate_status", "pending") \
        .execute()

    if not pending.data:
        return

    for sub in pending.data:
        try:
            razorpay = get_razorpay_service()
            rz_sub = razorpay.create_subscription(plan_id=sub.get("razorpay_sub_id") or "plan_mock_001")
            db.table("subscriptions").update({
                "mandate_status": "active",
            }).eq("id", sub["id"]).execute()
            db.table("razorpay_mandates").upsert({
                "driver_id": sub["driver_id"],
                "razorpay_sub_id": rz_sub["id"],
                "status": "active",
                "method": "upi",
            }).execute()
        except Exception:
            db.table("subscriptions").update({
                "mandate_status": "failed",
            }).eq("id", sub["id"]).execute()


def start_scheduler():
    scheduler.add_job(
        run_settlement,
        trigger=CronTrigger(
            day_of_week="sun",
            hour=12,
            minute=30,
            timezone="UTC"
        ),
        id="sunday_settlement",
        name="Sunday Settlement Run",
        replace_existing=True,
    )
    scheduler.add_job(
        process_pending_mandates,
        "interval",
        seconds=60,
        id="pending_mandates",
        name="Process Pending Mandates",
        replace_existing=True,
    )
    scheduler.start()
    print("Scheduler started — settlement runs every Sunday at 6:30 PM IST")


def stop_scheduler():
    scheduler.shutdown()