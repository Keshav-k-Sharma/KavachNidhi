from fastapi import APIRouter, Depends
from app.api.deps import get_current_user
from app.schemas import DriverRegisterRequest, DriverProfileUpdateRequest, ok, err
from app.services.drivers import service

router = APIRouter()


@router.post("/register")
def register(body: DriverRegisterRequest, user=Depends(get_current_user)):
    try:
        driver = service.register_driver(
            user_id=str(user.id),
            phone=user.phone,
            name=body.name,
            zone_id=body.zone_id,
            upi_id=body.upi_id,
        )
        return ok(driver)
    except Exception as e:
        return err(str(e))


@router.get("/me")
def get_me(user=Depends(get_current_user)):
    try:
        driver = service.get_driver(str(user.id))
        return ok(driver)
    except Exception as e:
        return err(str(e))


@router.put("/profile")
def update_profile(body: DriverProfileUpdateRequest, user=Depends(get_current_user)):
    try:
        driver = service.update_driver(str(user.id), body)
        return ok(driver)
    except Exception as e:
        return err(str(e))


@router.get("/risk-score")
def get_risk_score(user=Depends(get_current_user)):
    try:
        score = service.get_risk_score(str(user.id))
        return ok({"risk_score": score})
    except Exception as e:
        return err(str(e))
