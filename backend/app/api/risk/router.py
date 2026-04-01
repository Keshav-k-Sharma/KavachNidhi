import logging
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException

from app.api.deps import get_current_user
from app.services.risk.risk_calculator import get_risk_score, recalculate_driver, recalculate_all
from app.schemas import ok, err

router = APIRouter(prefix="/risk", tags=["risk"])
logger = logging.getLogger(__name__)


@router.get("/score/{driver_id}")
def read_risk_score(driver_id: UUID, user=Depends(get_current_user)):
    """
    Admin view — get full risk score breakdown for any driver by ID.
    Regular drivers should use GET /drivers/risk-score for their own score.
    """
    try:
        cached = get_risk_score(str(driver_id))
        if not cached:
            raise HTTPException(
                status_code=404,
                detail="Risk score not yet calculated for this driver.",
            )
        return ok(cached)
    except HTTPException:
        raise
    except Exception as e:
        return err(str(e))


@router.post("/recalculate")
def force_recalculate(driver_id: UUID | None = None, user=Depends(get_current_user)):
    """
    Force recalculate risk scores.
    Pass ?driver_id=<uuid> for a single driver, omit for all active drivers.
    """
    try:
        if driver_id:
            result = recalculate_driver(str(driver_id))
        else:
            result = recalculate_all()
        return ok(result)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error("[risk router] recalculate error: %s", e)
        return err(str(e))