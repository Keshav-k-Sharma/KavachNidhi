"""
FogBlock — checks visibility via OpenWeatherMap.
Triggers when visibility < 200 m AND local IST time is between 04:00–10:00.
Only fires for fog-eligible (northern) cities.
"""
import logging
from datetime import datetime, timezone, timedelta
from dataclasses import dataclass

import httpx

from app.config import settings

logger = logging.getLogger(__name__)

OWM_API_KEY = settings.OPENWEATHERMAP_API_KEY
USE_MOCK    = settings.USE_MOCK_WEATHER

OWM_CURRENT_URL      = "https://api.openweathermap.org/data/2.5/weather"
VISIBILITY_THRESHOLD = 200.0   # metres
IST              = timezone(timedelta(hours=5, minutes=30))
FOG_WINDOW_START = 4    # 04:00 IST
FOG_WINDOW_END   = 10   # 10:00 IST


@dataclass
class FogReading:
    city:           str
    visibility_m:   float
    in_time_window: bool
    severity:       float   # 0.0–1.0
    triggered:      bool
    source:         str


# ── Mock ──────────────────────────────────────────────────────────────────────

class MockWeatherService:
    def get_visibility(self, city: str) -> float:
        return 150.0   # below threshold → triggers FogBlock


_mock = MockWeatherService()


# ── Helpers ───────────────────────────────────────────────────────────────────

def _is_fog_window() -> bool:
    """True if current IST time is between 04:00 and 10:00."""
    now_ist = datetime.now(IST)
    return FOG_WINDOW_START <= now_ist.hour < FOG_WINDOW_END


def _fetch_visibility(city: str) -> float:
    """Returns visibility in metres from OWM, or 9999 on error."""
    try:
        resp = httpx.get(
            OWM_CURRENT_URL,
            params={"q": city, "appid": OWM_API_KEY, "units": "metric"},
            timeout=10,
        )
        resp.raise_for_status()
        data = resp.json()
        return float(data.get("visibility", 9999))
    except Exception as exc:
        logger.warning("[fog_block] API error for city=%s: %s", city, exc)
        return 9999.0


def _severity(visibility_m: float) -> float:
    """0 m → 1.0, 200 m → 0.0 (linear)."""
    if visibility_m >= VISIBILITY_THRESHOLD:
        return 0.0
    return round(1.0 - (visibility_m / VISIBILITY_THRESHOLD), 4)


# ── Public ────────────────────────────────────────────────────────────────────

def check_fog(city: str) -> FogReading:
    """Check whether a fog trigger should fire for *city*."""
    if USE_MOCK:
        visibility_m = _mock.get_visibility(city)
        source       = "mock"
    else:
        visibility_m = _fetch_visibility(city)
        source       = "openweathermap"

    in_window = _is_fog_window()
    triggered = (visibility_m < VISIBILITY_THRESHOLD) and in_window

    return FogReading(
        city           = city,
        visibility_m   = round(visibility_m, 2),
        in_time_window = in_window,
        severity       = _severity(visibility_m),
        triggered      = triggered,
        source         = source,
    )


def check_fog_for_cities(cities: list[str]) -> list[FogReading]:
    return [check_fog(city) for city in cities]