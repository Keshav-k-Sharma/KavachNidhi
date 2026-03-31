from fastapi import APIRouter
from app.schemas import SendOTPRequest, VerifyOTPRequest, ok, err
from app.services.auth import service

router = APIRouter()


@router.post("/send-otp")
def send_otp(body: SendOTPRequest):
    try:
        service.send_otp(body.phone)
        return ok()
    except Exception as e:
        return err(str(e))


@router.post("/verify-otp")
def verify_otp(body: VerifyOTPRequest):
    try:
        data = service.verify_otp(body.phone, body.otp)
        return ok(data)
    except Exception as e:
        return err(str(e))
