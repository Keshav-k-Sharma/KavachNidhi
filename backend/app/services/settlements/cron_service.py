from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from app.services.settlements.settlement_service import run_settlement
from app.services.payments.premium_service import collect_weekly_premiums

scheduler = AsyncIOScheduler()


def start_scheduler():
    # Monday 6:00 AM IST (00:30 UTC) — charge weekly premiums
    scheduler.add_job(
        collect_weekly_premiums,
        trigger=CronTrigger(
            day_of_week="mon",
            hour=0,
            minute=30,
            timezone="UTC",
        ),
        id="monday_premium_collection",
        name="Monday Premium Collection",
        replace_existing=True,
    )

    # Sunday 6:30 PM IST (13:00 UTC) — pay out shield credits to drivers
    scheduler.add_job(
        run_settlement,
        trigger=CronTrigger(
            day_of_week="sun",
            hour=12,
            minute=30,
            timezone="UTC",
        ),
        id="sunday_settlement",
        name="Sunday Settlement Run",
        replace_existing=True,
    )

    scheduler.start()
    print("Scheduler started — premium collection every Monday 6 AM IST, settlement every Sunday 6 PM IST")


def stop_scheduler():
    scheduler.shutdown()
