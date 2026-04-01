from app.database import supabase


def _normalize_india_phone_to_e164(phone: str) -> str:
    """Accept 10-digit local or 12-digit with leading 91; return E.164 for Supabase."""
    s = phone.strip().replace(" ", "")
    digits = "".join(c for c in s if c.isdigit())
    if len(digits) == 10:
        return f"+91{digits}"
    if len(digits) == 12 and digits.startswith("91"):
        return f"+{digits}"
    raise ValueError(
        "Invalid Indian mobile number; send 10 digits without country code "
        "(e.g. 9876543210)"
    )


def send_otp(phone: str) -> None:
    e164 = _normalize_india_phone_to_e164(phone)
    supabase.auth.sign_in_with_otp({"phone": e164})


def verify_otp(phone: str, otp: str) -> dict:
    e164 = _normalize_india_phone_to_e164(phone)
    response = supabase.auth.verify_otp({
        "phone": e164,
        "token": otp,
        "type": "sms",
    })
    return {
        "access_token": response.session.access_token,
        "user_id": str(response.user.id),
    }
