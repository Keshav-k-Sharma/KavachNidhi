
import logging
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger

from app.services.risk.risk_calculator import recalculate_all

logger = logging.getLogger(__name__)

_scheduler: BackgroundScheduler | None = None


def _run_nightly_recalculation() -> None:
    logger.info("[risk cron] Starting nightly risk score recalculation …")
    try:
        result = recalculate_all()
        logger.info("[risk cron] Done — %s", result)
    except Exception as exc:
        logger.error("[risk cron] Recalculation failed: %s", exc)


def start_risk_scheduler() -> None:
    """Start the background scheduler. Call once on app startup."""
    global _scheduler
    if _scheduler and _scheduler.running:
        return

    _scheduler = BackgroundScheduler()
    _scheduler.add_job(
        _run_nightly_recalculation,
        trigger=CronTrigger(hour=2, minute=0),   # 2 AM UTC daily
        id="risk_score_nightly",
        replace_existing=True,
    )
    _scheduler.start()
    logger.info("[risk cron] Scheduler started — nightly job at 02:00 UTC")


def stop_risk_scheduler() -> None:
    """Shut down the scheduler cleanly on app teardown."""
    global _scheduler
    if _scheduler and _scheduler.running:
        _scheduler.shutdown(wait=False)
        logger.info("[risk cron] Scheduler stopped")