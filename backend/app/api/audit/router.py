from fastapi import APIRouter, Depends, HTTPException

from app.api.deps import get_driver_id
from app.database import supabase
from app.services.audit.ledger_service import verify_entry

router = APIRouter(prefix="/audit", tags=["Audit"])


@router.get("/ledger")
def get_ledger(
    driver_id: str = Depends(get_driver_id),
    page: int = 1,
    limit: int = 20,
):
    try:
        offset = (page - 1) * limit

        entries = (
            supabase.table("audit_ledger")
            .select("*")
            .eq("driver_id", driver_id)
            .order("created_at", desc=True)
            .range(offset, offset + limit - 1)
            .execute()
        )

        return {"success": True, "data": entries.data, "error": None}

    except HTTPException as e:
        raise e
    except Exception as e:
        return {"success": False, "data": None, "error": str(e)}


@router.get("/verify/{entry_id}")
def verify_ledger_entry(entry_id: str, driver_id: str = Depends(get_driver_id)):
    try:
        result = verify_entry(entry_id)
        entry = result.get("entry") if isinstance(result, dict) else None
        if result.get("valid") and entry:
            entry_driver = entry.get("driver_id")
            if entry_driver and str(entry_driver) != str(driver_id):
                raise HTTPException(
                    status_code=403,
                    detail="Not authorized to verify this entry",
                )
        return {"success": True, "data": result, "error": None}

    except HTTPException as e:
        raise e
    except Exception as e:
        return {"success": False, "data": None, "error": str(e)}
