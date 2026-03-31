from fastapi import APIRouter
from app.database import supabase
from app.schemas import SendOTPRequest, VerifyOTPRequest, ok, err

router = APIRouter()


@router.post("/send-otp")
def send_otp(body: SendOTPRequest):
    try:
        supabase.auth.sign_in_with_otp({"phone": body.phone})
        return ok()
    except Exception as e:
        return err(str(e))


@router.post("/verify-otp")
def verify_otp(body: VerifyOTPRequest):
    try:
        response = supabase.auth.verify_otp({
            "phone": body.phone,
            "token": body.otp,
            "type": "sms",
        })
        return ok({
            "access_token": response.session.access_token,
            "user_id": str(response.user.id),
        })
    except Exception as e:
        return err(str(e))
