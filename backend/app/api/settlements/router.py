from fastapi import APIRouter, Header, HTTPException
from app.database import supabase
from app.services.settlements.settlement_service import run_settlement, get_driver_credits
from app.api.wallet.router import get_driver_id

router = APIRouter(prefix="/settlements", tags=["Settlements"])


@router.get("/next")
def get_next_settlement(authorization: str = Header(...)):
    try:
        driver_id = get_driver_id(authorization)
        credits = get_driver_credits(driver_id)

        return {"success": True, "data": {
            "estimated_amount": credits,
            "settlement_day": "Sunday",
            "settlement_time": "6:30 PM IST"
        }, "error": None}

    except HTTPException as e:
        raise e
    except Exception as e:
        return {"success": False, "data": None, "error": str(e)}


@router.get("/history")
def get_settlement_history(authorization: str = Header(...), page: int = 1, limit: int = 20):
    try:
        driver_id = get_driver_id(authorization)

        offset = (page - 1) * limit

        payouts = supabase.table("payouts") \
            .select("*, settlement_runs(triggered_at, run_type)") \
            .eq("driver_id", driver_id) \
            .order("created_at", desc=True) \
            .range(offset, offset + limit - 1) \
            .execute()

        return {"success": True, "data": payouts.data, "error": None}

    except HTTPException as e:
        raise e
    except Exception as e:
        return {"success": False, "data": None, "error": str(e)}


@router.post("/run")
def manual_settlement_run(authorization: str = Header(...)):
    try:
        driver_id = get_driver_id(authorization)
        result = run_settlement(run_type="manual")
        return {"success": True, "data": result, "error": None}

    except HTTPException as e:
        raise e
    except Exception as e:
        return {"success": False, "data": None, "error": str(e)}