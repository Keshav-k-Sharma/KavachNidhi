from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from app.services.settlements.settlement_service import run_settlement

scheduler = AsyncIOScheduler()

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
    scheduler.start()
    print("Scheduler started — settlement runs every Sunday at 6:30 PM IST")

def stop_scheduler():
    scheduler.shutdown()