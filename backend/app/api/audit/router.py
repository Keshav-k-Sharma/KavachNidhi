from fastapi import APIRouter, Header, HTTPException
from app.database import supabase
from app.services.audit.ledger_service import verify_entry
from app.api.wallet.router import get_driver_id

router = APIRouter(prefix="/audit", tags=["Audit"])


@router.get("/ledger")
def get_ledger(authorization: str = Header(...), page: int = 1, limit: int = 20):
    try:
        driver_id = get_driver_id(authorization)

        offset = (page - 1) * limit

        entries = supabase.table("audit_ledger") \
            .select("*") \
            .eq("driver_id", driver_id) \
            .order("created_at", desc=True) \
            .range(offset, offset + limit - 1) \
            .execute()

        return {"success": True, "data": entries.data, "error": None}

    except HTTPException as e:
        raise e
    except Exception as e:
        return {"success": False, "data": None, "error": str(e)}


@router.get("/verify/{entry_id}")
def verify_ledger_entry(entry_id: str, authorization: str = Header(...)):
    try:
        get_driver_id(authorization)
        result = verify_entry(entry_id)
        return {"success": True, "data": result, "error": None}

    except HTTPException as e:
        raise e
    except Exception as e:
        return {"success": False, "data": None, "error": str(e)}