from typing import Any, Optional
from pydantic import BaseModel


# ── Standard response wrapper ──────────────────────────────────────────────────

class Response(BaseModel):
    success: bool
    data: Any = None
    error: Optional[str] = None


def ok(data: Any = None) -> dict:
    return {"success": True, "data": data, "error": None}


def err(message: str) -> dict:
    return {"success": False, "data": None, "error": message}


# ── Auth ───────────────────────────────────────────────────────────────────────

class SendOTPRequest(BaseModel):
    phone: str          # e.g. "+919876543210"


class VerifyOTPRequest(BaseModel):
    phone: str
    otp: str


# ── Drivers ───────────────────────────────────────────────────────────────────

class DriverRegisterRequest(BaseModel):
    name: str
    zone_id: str        # UUID of city_zones row — city derived from this
    upi_id: Optional[str] = None


class DriverProfileUpdateRequest(BaseModel):
    name: Optional[str] = None
    zone_id: Optional[str] = None
    upi_id: Optional[str] = None


# ── KYC ───────────────────────────────────────────────────────────────────────
# No request body — file upload uses multipart/form-data (UploadFile)


# ── Subscriptions ─────────────────────────────────────────────────────────────

class SubscribeRequest(BaseModel):
    tier: str           # 'basic' | 'plus' | 'max'


class UpgradeRequest(BaseModel):
    tier: str           # must be higher than current tier


class CancelRequest(BaseModel):
    reason: Optional[str] = None
