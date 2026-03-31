from fastapi import APIRouter, Header, HTTPException
from app.database import supabase,db

router = APIRouter(prefix="/wallet", tags=["Wallet"])


def get_driver_id(authorization: str = Header(...)) -> str:
    token = authorization.replace("Bearer ", "")
    response = supabase.auth.get_user(token)
    if not response.user:
        raise HTTPException(status_code=401, detail="Invalid token")

    driver = db.table("drivers") \
        .select("id") \
        .eq("phone", response.user.phone) \
        .single() \
        .execute()

    if not driver.data:
        raise HTTPException(status_code=404, detail="Driver not found")

    return driver.data["id"]


@router.get("/balance")
def get_balance(authorization: str = Header(...)):
    try:
        driver_id = get_driver_id(authorization)

        wallet = db.table("wallets") \
            .select("*") \
            .eq("driver_id", driver_id) \
            .single() \
            .execute()

        if not wallet.data:
            raise HTTPException(status_code=404, detail="Wallet not found")

        return {"success": True, "data": wallet.data, "error": None}

    except HTTPException as e:
        raise e
    except Exception as e:
        return {"success": False, "data": None, "error": str(e)}


@router.get("/transactions")
def get_transactions(authorization: str = Header(...), page: int = 1, limit: int = 20):
    try:
        driver_id = get_driver_id(authorization)

        offset = (page - 1) * limit

        transactions = db.table("wallet_transactions") \
            .select("*") \
            .eq("driver_id", driver_id) \
            .order("created_at", desc=True) \
            .range(offset, offset + limit - 1) \
            .execute()

        return {"success": True, "data": transactions.data, "error": None}

    except HTTPException as e:
        raise e
    except Exception as e:
        return {"success": False, "data": None, "error": str(e)}


@router.put("/upi")
def update_upi(upi_data: dict, authorization: str = Header(...)):
    try:
        driver_id = get_driver_id(authorization)

        upi_id = upi_data.get("upi_id")
        if not upi_id:
            raise HTTPException(status_code=400, detail="upi_id is required")

        result = db.table("drivers") \
            .update({"upi_id": upi_id}) \
            .eq("id", driver_id) \
            .execute()

        return {"success": True, "data": result.data[0], "error": None}

    except HTTPException as e:
        raise e
    except Exception as e:
        return {"success": False, "data": None, "error": str(e)}
