"""
CycloneGuard — checks OpenWeatherMap for storm/cyclone alerts.
Triggers when wind_speed > 60 km/h OR an official alert exists for a coastal city.
"""
import logging
import httpx
from dataclasses import dataclass

from app.config import settings

logger = logging.getLogger(__name__)

OWM_API_KEY = settings.OPENWEATHERMAP_API_KEY
USE_MOCK    = settings.USE_MOCK_WEATHER

OWM_CURRENT_URL    = "https://api.openweathermap.org/data/2.5/weather"
WIND_THRESHOLD_KMH = 60.0


@dataclass
class CycloneReading:
    city:      str
    wind_kmh:  float
    has_alert: bool
    severity:  float    # 0.0–1.0
    triggered: bool
    source:    str


# ── Mock ──────────────────────────────────────────────────────────────────────

class MockWeatherService:
    def get_wind_speed(self, city: str) -> float:
        return 75.0

    def has_storm_alert(self, city: str) -> bool:
        return True


_mock = MockWeatherService()


# ── Real API ──────────────────────────────────────────────────────────────────

def _fetch_wind_speed(city: str) -> tuple[float, bool]:
    """Returns (wind_speed_kmh, has_alert)."""
    try:
        resp = httpx.get(
            OWM_CURRENT_URL,
            params={"q": city, "appid": OWM_API_KEY, "units": "metric"},
            timeout=10,
        )
        resp.raise_for_status()
        data = resp.json()

        wind_ms  = data.get("wind", {}).get("speed", 0.0)
        wind_kmh = wind_ms * 3.6

        alerts    = data.get("alerts", [])
        has_alert = any(
            "storm" in a.get("event", "").lower() or
            "cyclone" in a.get("event", "").lower()
            for a in alerts
        )
        return wind_kmh, has_alert

    except Exception as exc:
        logger.warning("[cyclone_guard] API error for city=%s: %s", city, exc)
        return 0.0, False


def _severity(wind_kmh: float) -> float:
    """Normalise wind speed to 0–1 severity. Caps at 150 km/h."""
    if wind_kmh <= WIND_THRESHOLD_KMH:
        return 0.0
    return min(1.0, (wind_kmh - WIND_THRESHOLD_KMH) / (150.0 - WIND_THRESHOLD_KMH))


# ── Public ────────────────────────────────────────────────────────────────────

def check_cyclone(city: str) -> CycloneReading:
    """Check whether a cyclone trigger should fire for *city*."""
    if USE_MOCK:
        wind_kmh  = _mock.get_wind_speed(city)
        has_alert = _mock.has_storm_alert(city)
        source    = "mock"
    else:
        wind_kmh, has_alert = _fetch_wind_speed(city)
        source = "openweathermap"

    triggered = (wind_kmh > WIND_THRESHOLD_KMH) or has_alert
    severity  = _severity(wind_kmh) if not has_alert else max(_severity(wind_kmh), 0.8)

    return CycloneReading(
        city      = city,
        wind_kmh  = round(wind_kmh, 2),
        has_alert = has_alert,
        severity  = round(severity, 4),
        triggered = triggered,
        source    = source,
    )


def check_cyclones_for_cities(cities: list[str]) -> list[CycloneReading]:
    return [check_cyclone(city) for city in cities]