from fastapi import FastAPI
from contextlib import asynccontextmanager
from app.services.settlements.cron_service import start_scheduler, stop_scheduler
from app.api.wallet.router import router as wallet_router
from app.api.payments.router import router as payments_router
from app.api.settlements.router import router as settlements_router

@asynccontextmanager
async def lifespan(app: FastAPI):
    start_scheduler()
    yield
    stop_scheduler()


app = FastAPI()

app.include_router(wallet_router)
app.include_router(payments_router)
app.include_router(settlements_router)


@app.get("/")
def root():
    return {"success": True, "data": "KavachNidhi backend is live", "error": None}