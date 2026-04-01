from fastapi import UploadFile
from app.database import db
from app.config import settings


def upload_document(driver_id: str, document_type: str, file: UploadFile) -> dict:
    path = f"{driver_id}/{document_type}"
    file_bytes = file.file.read()

    # Upload to storage (upsert so re-uploading same doc type overwrites)
    db.storage.from_(settings.SUPABASE_STORAGE_BUCKET).upload(
        path,
        file_bytes,
        {"content-type": file.content_type, "upsert": "true"},
    )

    # Upsert KYC row — one row per driver per document_type
    result = db.table("driver_kyc").upsert({
        "driver_id": driver_id,
        "document_type": document_type,
        "document_url": path,
        "status": "pending",
        "rejection_reason": None,
        "reviewed_at": None,
    }, on_conflict="driver_id,document_type").execute()

    return result.data[0]


def get_kyc_status(driver_id: str) -> list:
    result = db.table("driver_kyc").select("*").eq("driver_id", driver_id).execute()
    return result.data
