from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.auth.router import router as auth_router
from app.api.drivers.router import router as drivers_router
from app.api.kyc.router import router as kyc_router
from app.api.subscriptions.router import router as subscriptions_router

app = FastAPI(title="KavachNidhi", version="0.1.0")

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


@app.get("/health")
def health():
    return {"status": "ok"}
