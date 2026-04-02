from datetime import date, datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Request

from app.api.deps import get_driver_id
from app.config import settings
from app.database import supabase
from app.services.payments.razorpay_service import get_razorpay_service

router = APIRouter(prefix="/payments", tags=["Payments"])


@router.post("/mandate/create")
def create_mandate(driver_id: str = Depends(get_driver_id)):
    """
    Creates a Razorpay order for mandate setup.
    Returns order_id + key_id to the frontend which then opens Razorpay checkout
    with recurring=1 for UPI AutoPay mandate setup.
    """
    try:
        sub = supabase.table("subscriptions") \
            .select("id, actual_premium, base_rate, mandate_status") \
            .eq("driver_id", driver_id) \
            .eq("status", "active") \
            .single() \
            .execute()

        if not sub.data:
            raise HTTPException(status_code=404, detail="No active subscription found")

        if sub.data["mandate_status"] == "active":
            raise HTTPException(status_code=400, detail="Mandate already active")

        amount_paise = int(float(sub.data["actual_premium"]) * 100)
        # Max amount shown to driver in UPI AutoPay screen (base_rate at max risk_score=1.0)
        max_amount_paise = int(float(sub.data["base_rate"]) * 1.5 * 100)

        razorpay_svc = get_razorpay_service()
        order = razorpay_svc.create_order(
            amount_paise=amount_paise,
            receipt=f"mandate_{driver_id[:8]}",
            notes={"driver_id": driver_id, "type": "mandate_setup"},
        )

        supabase.table("razorpay_mandates").upsert({
            "driver_id": driver_id,
            "razorpay_order_id": order["id"],
            "status": "pending",
            "method": "upi",
        }, on_conflict="driver_id").execute()

        return {
            "success": True,
            "data": {
                "order_id": order["id"],
                "amount": amount_paise,
                "max_amount": max_amount_paise,
                "currency": "INR",
                "key_id": settings.RAZORPAY_KEY_ID,
            },
            "error": None,
        }

    except HTTPException as e:
        raise e
    except Exception as e:
        return {"success": False, "data": None, "error": str(e)}


@router.get("/mandate/status")
def get_mandate_status(driver_id: str = Depends(get_driver_id)):
    try:
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
def get_payment_history(
    driver_id: str = Depends(get_driver_id),
    page: int = 1,
    limit: int = 20,
):
    try:
        offset = (page - 1) * limit
        payments = supabase.table("premium_payments") \
            .select("*") \
            .eq("driver_id", driver_id) \
            .order("created_at", desc=True) \
            .range(offset, offset + limit - 1) \
            .execute()

        return {"success": True, "data": payments.data, "error": None}

    except Exception as e:
        return {"success": False, "data": None, "error": str(e)}


@router.post("/webhook")
async def razorpay_webhook(request: Request):
    try:
        payload = await request.body()
        signature = request.headers.get("x-razorpay-signature", "")

        razorpay_svc = get_razorpay_service()

        if not razorpay_svc.verify_webhook_signature(payload, signature):
            raise HTTPException(status_code=400, detail="Invalid webhook signature")

        event = await request.json()
        event_type = event.get("event")
        payment = event.get("payload", {}).get("payment", {}).get("entity", {})

        if event_type == "payment.authorized":
            _handle_payment_authorized(payment, razorpay_svc)

        elif event_type == "payment.captured":
            _handle_payment_captured(payment)

        elif event_type == "payment.failed":
            _handle_payment_failed(payment)

        return {"success": True, "data": "Webhook processed", "error": None}

    except HTTPException as e:
        raise e
    except Exception as e:
        return {"success": False, "data": None, "error": str(e)}


# ── internal webhook handlers ──────────────────────────────────────────────────

def _handle_payment_authorized(payment: dict, razorpay_svc):
    """
    Fires when driver completes UPI AutoPay mandate setup.
    Saves the token, marks mandate as active, captures first premium.
    """
    order_id = payment.get("order_id")
    payment_id = payment.get("id")
    token_id = payment.get("token_id")
    amount_paise = payment.get("amount")

    mandate = supabase.table("razorpay_mandates") \
        .select("driver_id") \
        .eq("razorpay_order_id", order_id) \
        .single() \
        .execute()

    if not mandate.data:
        return

    driver_id = mandate.data["driver_id"]
    now = datetime.now(timezone.utc).isoformat()

    supabase.table("razorpay_mandates").update({
        "razorpay_token_id": token_id,
        "razorpay_payment_id": payment_id,
        "status": "active",
        "updated_at": now,
    }).eq("razorpay_order_id", order_id).execute()

    supabase.table("subscriptions").update({
        "mandate_status": "active",
        "updated_at": now,
    }).eq("driver_id", driver_id).eq("status", "active").execute()

    # Capture first week's premium (triggers payment.captured)
    if amount_paise:
        razorpay_svc.capture_payment(payment_id, amount_paise)


def _handle_payment_captured(payment: dict):
    """
    Fires after a payment is captured (first setup payment + all recurring charges).
    Records the premium payment.
    """
    payment_id = payment.get("id")
    token_id = payment.get("token_id")
    order_id = payment.get("order_id")
    amount = payment.get("amount", 0) / 100

    driver_id = _driver_from_token_or_order(token_id, order_id)
    if not driver_id:
        return

    sub = supabase.table("subscriptions") \
        .select("id") \
        .eq("driver_id", driver_id) \
        .eq("status", "active") \
        .single() \
        .execute()

    if not sub.data:
        return

    week_start = date.today().isoformat()

    # If a pending row already exists (created by weekly cron), update it
    existing = supabase.table("premium_payments") \
        .select("id") \
        .eq("driver_id", driver_id) \
        .eq("week_start", week_start) \
        .eq("status", "pending") \
        .limit(1) \
        .execute()

    if existing.data:
        supabase.table("premium_payments").update({
            "razorpay_payment_id": payment_id,
            "status": "success",
        }).eq("id", existing.data[0]["id"]).execute()
    else:
        supabase.table("premium_payments").insert({
            "driver_id": driver_id,
            "subscription_id": sub.data["id"],
            "amount": amount,
            "razorpay_payment_id": payment_id,
            "status": "success",
            "week_start": week_start,
        }).execute()


def _handle_payment_failed(payment: dict):
    """
    Fires when a payment fails (mandate setup or recurring charge).
    """
    payment_id = payment.get("id")
    token_id = payment.get("token_id")
    order_id = payment.get("order_id")

    driver_id = _driver_from_token_or_order(token_id, order_id)
    if not driver_id:
        return

    week_start = date.today().isoformat()

    # Update any pending premium_payment row for this week
    supabase.table("premium_payments").update({
        "razorpay_payment_id": payment_id,
        "status": "failed",
    }).eq("driver_id", driver_id) \
      .eq("week_start", week_start) \
      .eq("status", "pending") \
      .execute()

    # If the mandate was never activated (setup failure), mark it halted
    mandate = supabase.table("razorpay_mandates") \
        .select("status") \
        .eq("driver_id", driver_id) \
        .single() \
        .execute()

    if mandate.data and mandate.data["status"] == "pending":
        supabase.table("razorpay_mandates").update({
            "status": "halted",
            "updated_at": datetime.now(timezone.utc).isoformat(),
        }).eq("driver_id", driver_id).execute()

        supabase.table("subscriptions").update({
            "mandate_status": "failed",
            "updated_at": datetime.now(timezone.utc).isoformat(),
        }).eq("driver_id", driver_id).eq("status", "active").execute()


def _driver_from_token_or_order(token_id: str | None, order_id: str | None) -> str | None:
    """Resolve driver_id from token_id (recurring) or order_id (first payment)."""
    if token_id:
        result = supabase.table("razorpay_mandates") \
            .select("driver_id") \
            .eq("razorpay_token_id", token_id) \
            .single() \
            .execute()
        if result.data:
            return result.data["driver_id"]

    if order_id:
        result = supabase.table("razorpay_mandates") \
            .select("driver_id") \
            .eq("razorpay_order_id", order_id) \
            .single() \
            .execute()
        if result.data:
            return result.data["driver_id"]

    return None
