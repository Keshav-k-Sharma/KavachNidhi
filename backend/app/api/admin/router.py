from fastapi import APIRouter, Depends, HTTPException

from app.api.deps import require_admin
from app.database import supabase

router = APIRouter(prefix="/admin", tags=["Admin"])


@router.get("/stats")
def get_stats(_admin=Depends(require_admin)):
    try:
        total_drivers = supabase.table("drivers").select("id", count="exact").execute()

        total_paid = (
            supabase.table("settlement_runs")
            .select("total_amount")
            .eq("status", "completed")
            .execute()
        )

        active_triggers = (
            supabase.table("trigger_events")
            .select("id", count="exact")
            .gte("expires_at", "now()")
            .execute()
        )

        total_amount_paid = (
            sum(row["total_amount"] for row in total_paid.data) if total_paid.data else 0
        )

        return {
            "success": True,
            "data": {
                "total_drivers": total_drivers.count,
                "total_amount_paid": total_amount_paid,
                "active_triggers": active_triggers.count,
            },
            "error": None,
        }

    except HTTPException as e:
        raise e
    except Exception as e:
        return {"success": False, "data": None, "error": str(e)}


@router.get("/fraud-queue")
def get_fraud_queue(
    _admin=Depends(require_admin),
    page: int = 1,
    limit: int = 20,
):
    try:
        offset = (page - 1) * limit

        queue = (
            supabase.table("fraud_review_queue")
            .select("*, fraud_flags(reason, detection_layer, severity)")
            .eq("status", "pending")
            .order("created_at", desc=True)
            .range(offset, offset + limit - 1)
            .execute()
        )

        return {"success": True, "data": queue.data, "error": None}

    except HTTPException as e:
        raise e
    except Exception as e:
        return {"success": False, "data": None, "error": str(e)}
