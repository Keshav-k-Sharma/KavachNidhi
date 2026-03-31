from fastapi import APIRouter, Depends
from app.api.deps import get_current_user
from app.schemas import SubscribeRequest, UpgradeRequest, CancelRequest, ok, err
from app.services.subscriptions import service

router = APIRouter()


@router.get("/tiers")
def get_tiers():
    return ok(service.get_tiers())


@router.post("/subscribe")
def subscribe(body: SubscribeRequest, user=Depends(get_current_user)):
    try:
        sub = service.subscribe(str(user.id), body.tier)
        return ok(sub)
    except Exception as e:
        return err(str(e))


@router.get("/me")
def get_me(user=Depends(get_current_user)):
    try:
        sub = service.get_active_subscription(str(user.id))
        return ok(sub)
    except Exception as e:
        return err(str(e))


@router.put("/upgrade")
def upgrade(body: UpgradeRequest, user=Depends(get_current_user)):
    try:
        sub = service.upgrade(str(user.id), body.tier)
        return ok(sub)
    except Exception as e:
        return err(str(e))


@router.delete("/cancel")
def cancel(body: CancelRequest, user=Depends(get_current_user)):
    try:
        sub = service.cancel(str(user.id), body.reason)
        return ok(sub)
    except Exception as e:
        return err(str(e))


@router.get("/history")
def get_history(user=Depends(get_current_user)):
    try:
        history = service.get_history(str(user.id))
        return ok(history)
    except Exception as e:
        return err(str(e))
