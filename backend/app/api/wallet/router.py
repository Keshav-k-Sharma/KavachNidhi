from fastapi import APIRouter, Depends, HTTPException

from app.api.deps import get_driver_id
from app.database import supabase

router = APIRouter(prefix="/wallet", tags=["Wallet"])


def _to_float(value):
    if value is None:
        return 0.0
    if isinstance(value, (int, float)):
        return float(value)
    if isinstance(value, str):
        try:
            return float(value)
        except ValueError:
            return 0.0
    return 0.0


def _normalize_wallet_payload(wallet: dict) -> dict:
    shield = _to_float(wallet.get("shield_credits"))
    pending = _to_float(
        wallet.get("pending_credits") or wallet.get("pending_validation_credits")
    )
    cleared = _to_float(wallet.get("cleared_credits") or wallet.get("cleared_balance"))

    merged = dict(wallet)
    merged["shield_credits"] = shield
    merged["pending_credits"] = pending
    merged["cleared_credits"] = cleared
    return merged


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

        return {
            "success": True,
            "data": _normalize_wallet_payload(wallet.data),
            "error": None,
        }

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
