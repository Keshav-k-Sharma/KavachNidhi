from fastapi import FastAPI
from contextlib import asynccontextmanager
from app.services.settlements.cron_service import start_scheduler, stop_scheduler


@asynccontextmanager
async def lifespan(app: FastAPI):
    start_scheduler()
    yield
    stop_scheduler()

app = FastAPI()

@app.get("/")
def root():
    return {"success": True, "data": "KavachNidhi backend is live", "error": None}