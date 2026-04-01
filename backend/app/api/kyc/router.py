from fastapi import APIRouter, Depends, UploadFile, File, Form
from app.api.deps import get_current_user
from app.schemas import ok, err
from app.services.kyc import service

router = APIRouter()


@router.post("/upload")
def upload(
    document_type: str = Form(...),
    file: UploadFile = File(...),
    user=Depends(get_current_user),
):
    try:
        kyc = service.upload_document(str(user.id), document_type, file)
        return ok(kyc)
    except Exception as e:
        return err(str(e))


@router.get("/status")
def status(user=Depends(get_current_user)):
    try:
        docs = service.get_kyc_status(str(user.id))
        return ok(docs)
    except Exception as e:
        return err(str(e))
