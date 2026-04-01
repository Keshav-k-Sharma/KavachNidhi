
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.services.risk.risk_calculator import recalculate_driver, recalculate_all

router = APIRouter(prefix="/risk", tags=["risk"])


@router.get("/score/{driver_id}")
async def get_risk_score(driver_id: UUID, db: AsyncSession = Depends(get_db)):
    try:
        result = await recalculate_driver(driver_id, db)
        return result
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Risk calculation failed: {e}")


@router.post("/recalculate")
async def force_recalculate(db: AsyncSession = Depends(get_db)):
    result = await recalculate_all(db)
    return result