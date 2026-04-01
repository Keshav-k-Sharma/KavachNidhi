from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

from app.config import settings
from app.database import supabase

security = HTTPBearer()


def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    try:
        response = supabase.auth.get_user(credentials.credentials)
        return response.user
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid or expired token")


def _admin_phones() -> set[str]:
    raw = settings.ADMIN_PHONES or ""
    return {p.strip() for p in raw.split(",") if p.strip()}


def require_admin(user=Depends(get_current_user)):
    """Restrict routes to callers whose phone is listed in ADMIN_PHONES (E.164)."""
    phone = getattr(user, "phone", None) or ""
    if phone not in _admin_phones():
        raise HTTPException(status_code=403, detail="Admin access required")
    return user


def get_driver_id(user=Depends(get_current_user)) -> str:
    """Resolve Supabase-authenticated user to a `drivers.id` by matching phone."""
    phone = getattr(user, "phone", None)
    if not phone:
        raise HTTPException(status_code=401, detail="User phone not available")

    driver = (
        supabase.table("drivers")
        .select("id")
        .eq("phone", phone)
        .single()
        .execute()
    )

    if not driver.data:
        raise HTTPException(status_code=404, detail="Driver not found")

    return driver.data["id"]
