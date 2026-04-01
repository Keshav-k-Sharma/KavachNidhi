import hashlib
import json
from datetime import datetime, timezone
from app.database import supabase


def compute_hash(entry: dict, prev_hash: str) -> str:
    payload = json.dumps({**entry, "prev_hash": prev_hash}, sort_keys=True)
    return hashlib.sha256(payload.encode()).hexdigest()


def get_last_entry() -> dict | None:
    result = supabase.table("audit_ledger") \
        .select("*") \
        .order("created_at", desc=True) \
        .limit(1) \
        .execute()

    if result.data:
        return result.data[0]
    return None


def append(entry_type: str, driver_id: str | None, amount: float | None, reference_id: str | None, description: str) -> dict:
    last_entry = get_last_entry()
    prev_hash = last_entry["entry_hash"] if last_entry else "0" * 64

    entry = {
        "entry_type": entry_type,
        "driver_id": str(driver_id) if driver_id else None,
        "amount": float(amount) if amount else None,
        "reference_id": str(reference_id) if reference_id else None,
        "description": description,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }

    entry_hash = compute_hash(entry, prev_hash)

    result = supabase.table("audit_ledger").insert({
        **entry,
        "entry_hash": entry_hash,
        "prev_hash": prev_hash,
    }).execute()

    return result.data[0]


def verify_entry(entry_id: str) -> dict:
    result = supabase.table("audit_ledger") \
        .select("*") \
        .eq("id", entry_id) \
        .single() \
        .execute()

    if not result.data:
        return {"valid": False, "reason": "Entry not found"}

    entry = result.data

    check = {
        "entry_type": entry["entry_type"],
        "driver_id": entry["driver_id"],
        "amount": entry["amount"],
        "reference_id": entry["reference_id"],
        "description": entry["description"],
        "created_at": entry["created_at"],
    }

    expected_hash = compute_hash(check, entry["prev_hash"])

    if expected_hash != entry["entry_hash"]:
        return {"valid": False, "reason": "Hash mismatch — entry may have been tampered with"}

    return {"valid": True, "entry": entry}