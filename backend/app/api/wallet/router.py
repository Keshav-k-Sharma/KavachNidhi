from fastapi import APIRouter, Depends, HTTPException

from app.api.deps import get_driver_id
from app.database import supabase

router = APIRouter(prefix="/wallet", tags=["Wallet"])


@router.get("/balance")
def get_balance(driver_id: str = Depends(get_driver_id)):
    try:
        wallet = (
            supabase.table("wallets")
            .select("*")
            .eq("driver_id", driver_id)
            .single()
            .execute()
        )

        if not wallet.data:
            raise HTTPException(status_code=404, detail="Wallet not found")

        return {"success": True, "data": wallet.data, "error": None}

    except HTTPException as e:
        raise e
    except Exception as e:
        return {"success": False, "data": None, "error": str(e)}


@router.get("/transactions")
def get_transactions(
    driver_id: str = Depends(get_driver_id),
    page: int = 1,
    limit: int = 20,
):
    try:
        offset = (page - 1) * limit

        transactions = (
            supabase.table("wallet_transactions")
            .select("*")
            .eq("driver_id", driver_id)
            .order("created_at", desc=True)
            .range(offset, offset + limit - 1)
            .execute()
        )

        return {"success": True, "data": transactions.data, "error": None}

    except HTTPException as e:
        raise e
    except Exception as e:
        return {"success": False, "data": None, "error": str(e)}


@router.put("/upi")
def update_upi(upi_data: dict, driver_id: str = Depends(get_driver_id)):
    try:
        upi_id = upi_data.get("upi_id")
        if not upi_id:
            raise HTTPException(status_code=400, detail="upi_id is required")

        result = (
            supabase.table("drivers")
            .update({"upi_id": upi_id})
            .eq("id", driver_id)
            .execute()
        )

        return {"success": True, "data": result.data[0], "error": None}

    except HTTPException as e:
        raise e
    except Exception as e:
        return {"success": False, "data": None, "error": str(e)}
