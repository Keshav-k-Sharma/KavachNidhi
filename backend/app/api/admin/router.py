from fastapi import APIRouter, Header, HTTPException
from app.database import supabase,db
from app.api.wallet.router import get_driver_id

router = APIRouter(prefix="/admin", tags=["Admin"])


@router.get("/stats")
def get_stats(authorization: str = Header(...)):
    try:
        get_driver_id(authorization)

        total_drivers = db.table("drivers") \
            .select("id", count="exact") \
            .execute()

        total_paid = db.table("settlement_runs") \
            .select("total_amount") \
            .eq("status", "completed") \
            .execute()

        active_triggers = db.table("trigger_events") \
            .select("id", count="exact") \
            .gte("expires_at", "now()") \
            .execute()

        total_amount_paid = sum(
            row["total_amount"] for row in total_paid.data
        ) if total_paid.data else 0

        return {"success": True, "data": {
            "total_drivers": total_drivers.count,
            "total_amount_paid": total_amount_paid,
            "active_triggers": active_triggers.count,
        }, "error": None}

    except HTTPException as e:
        raise e
    except Exception as e:
        return {"success": False, "data": None, "error": str(e)}


@router.get("/fraud-queue")
def get_fraud_queue(authorization: str = Header(...), page: int = 1, limit: int = 20):
    try:
        get_driver_id(authorization)

        offset = (page - 1) * limit

        queue = db.table("fraud_review_queue") \
            .select("*, fraud_flags(reason, detection_layer, severity)") \
            .eq("status", "pending") \
            .order("created_at", desc=True) \
            .range(offset, offset + limit - 1) \
            .execute()

        return {"success": True, "data": queue.data, "error": None}

    except HTTPException as e:
        raise e
    except Exception as e:
        return {"success": False, "data": None, "error": str(e)}