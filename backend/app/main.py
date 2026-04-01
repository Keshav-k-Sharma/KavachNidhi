from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from app.services.settlements.cron_service import start_scheduler, stop_scheduler
from app.services.risk.cron_service import start_risk_scheduler, stop_risk_scheduler  

from app.api.auth.router import router as auth_router
from app.api.drivers.router import router as drivers_router
from app.api.kyc.router import router as kyc_router
from app.api.subscriptions.router import router as subscriptions_router
from app.api.wallet.router import router as wallet_router
from app.api.payments.router import router as payments_router
from app.api.settlements.router import router as settlements_router
from app.api.audit.router import router as audit_router
from app.api.admin.router import router as admin_router
from app.api.risk import router as risk_router 


@asynccontextmanager
async def lifespan(app: FastAPI):
    start_scheduler()
    start_risk_scheduler()  
    yield
    stop_scheduler()
    stop_risk_scheduler()  


app = FastAPI(title="KavachNidhi", version="0.1.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router,          prefix="/auth",          tags=["Auth"])
app.include_router(drivers_router,       prefix="/drivers",       tags=["Drivers"])
app.include_router(kyc_router,           prefix="/kyc",           tags=["KYC"])
app.include_router(subscriptions_router, prefix="/subscriptions", tags=["Subscriptions"])
app.include_router(wallet_router)
app.include_router(payments_router)
app.include_router(settlements_router)
app.include_router(audit_router)
app.include_router(admin_router)
app.include_router(risk_router)  


@app.get("/health")
def health():
    return {"status": "ok"}