from app.database import db as supabase
from app.schemas import DriverProfileUpdateRequest


def register_driver(user_id: str, phone: str, name: str, zone_id: str, upi_id: str | None = None) -> dict:
    data = {
        "id": user_id,
        "phone": phone,
        "name": name,
        "zone_id": zone_id,
    }
    if upi_id:
        data["upi_id"] = upi_id

    result = supabase.table("drivers").insert(data).execute()
    return result.data[0]


def get_driver(user_id: str) -> dict:
    result = supabase.table("drivers").select("*").eq("id", user_id).single().execute()
    return result.data


def update_driver(user_id: str, body: DriverProfileUpdateRequest) -> dict:
    updates = body.model_dump(exclude_none=True)
    if not updates:
        return get_driver(user_id)
    result = supabase.table("drivers").update(updates).eq("id", user_id).execute()
    return result.data[0]


def get_risk_score(user_id: str) -> float:
    result = supabase.table("risk_scores").select("score").eq("driver_id", user_id).maybe_single().execute()
    if result.data:
        return result.data["score"]
    return 0.5
