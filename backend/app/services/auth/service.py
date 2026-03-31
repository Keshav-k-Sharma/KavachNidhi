from app.database import supabase


def send_otp(phone: str) -> None:
    supabase.auth.sign_in_with_otp({"phone": phone})


def verify_otp(phone: str, otp: str) -> dict:
    response = supabase.auth.verify_otp({
        "phone": phone,
        "token": otp,
        "type": "sms",
    })
    return {
        "access_token": response.session.access_token,
        "user_id": str(response.user.id),
    }
