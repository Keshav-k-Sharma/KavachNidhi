from fastapi import APIRouter, Header, HTTPException, Request
from app.database import supabase
from app.services.payments.razorpay_service import get_razorpay_service
from app.api.wallet.router import get_driver_id

router = APIRouter(prefix="/payments", tags=["Payments"])


@router.post("/mandate/create")
def create_mandate(authorization: str = Header(...)):
    try:
        driver_id = get_driver_id(authorization)

        subscription = supabase.table("subscriptions") \
            .select("*") \
            .eq("driver_id", driver_id) \
            .eq("status", "active") \
            .single() \
            .execute()

        if not subscription.data:
            raise HTTPException(status_code=404, detail="No active subscription found")

        razorpay = get_razorpay_service()
        rz_subscription = razorpay.create_subscription(
            plan_id=subscription.data["razorpay_sub_id"] or "plan_mock_001"
        )

        mandate = supabase.table("razorpay_mandates").upsert({
            "driver_id": driver_id,
            "razorpay_sub_id": rz_subscription["id"],
            "status": "pending",
            "method": "upi",
        }).execute()

        return {"success": True, "data": mandate.data[0], "error": None}

    except HTTPException as e:
        raise e
    except Exception as e:
        return {"success": False, "data": None, "error": str(e)}


@router.get("/mandate/status")
def get_mandate_status(authorization: str = Header(...)):
    try:
        driver_id = get_driver_id(authorization)

        mandate = supabase.table("razorpay_mandates") \
            .select("*") \
            .eq("driver_id", driver_id) \
            .single() \
            .execute()

        if not mandate.data:
            raise HTTPException(status_code=404, detail="No mandate found")

        return {"success": True, "data": mandate.data, "error": None}

    except HTTPException as e:
        raise e
    except Exception as e:
        return {"success": False, "data": None, "error": str(e)}


@router.get("/history")
def get_payment_history(authorization: str = Header(...), page: int = 1, limit: int = 20):
    try:
        driver_id = get_driver_id(authorization)

        offset = (page - 1) * limit

        payments = supabase.table("premium_payments") \
            .select("*") \
            .eq("driver_id", driver_id) \
            .order("created_at", desc=True) \
            .range(offset, offset + limit - 1) \
            .execute()

        return {"success": True, "data": payments.data, "error": None}

    except HTTPException as e:
        raise e
    except Exception as e:
        return {"success": False, "data": None, "error": str(e)}


@router.post("/webhook")
async def razorpay_webhook(request: Request):
    try:
        payload = await request.body()
        signature = request.headers.get("x-razorpay-signature", "")

        razorpay = get_razorpay_service()
        is_valid = razorpay.verify_webhook_signature(payload, signature)

        if not is_valid:
            raise HTTPException(status_code=400, detail="Invalid webhook signature")

        event = await request.json()
        event_type = event.get("event")

        if event_type == "subscription.charged":
            payment = event["payload"]["payment"]["entity"]
            driver_mandate = supabase.table("razorpay_mandates") \
                .select("driver_id") \
                .eq("razorpay_sub_id", payment.get("subscription_id")) \
                .single() \
                .execute()

            if driver_mandate.data:
                driver_id = driver_mandate.data["driver_id"]
                supabase.table("premium_payments").insert({
                    "driver_id": driver_id,
                    "amount": payment["amount"] / 100,
                    "razorpay_payment_id": payment["id"],
                    "status": "success",
                    "week_start": payment.get("created_at", ""),
                    "subscription_id": payment.get("subscription_id", ""),
                }).execute()

        return {"success": True, "data": "Webhook processed", "error": None}

    except HTTPException as e:
        raise e
    except Exception as e:
        return {"success": False, "data": None, "error": str(e)}