"""
TrafficBlock — checks TomTom Traffic Flow API for deep congestion.
Triggers when current_speed < 0.3 × free_flow_speed.
Eligible tier: max only. Payout: ₹2/min of delay, max ₹120/day.
"""
import logging
import httpx
from dataclasses import dataclass

from app.config import settings

logger = logging.getLogger(__name__)

TOMTOM_API_KEY = settings.TOMTOM_API_KEY
USE_MOCK       = settings.USE_MOCK_TRAFFIC

TOMTOM_FLOW_URL  = "https://api.tomtom.com/traffic/services/4/flowSegmentData/absolute/10/json"
CONGESTION_RATIO = 0.3
PAYOUT_PER_MINUTE = 2.0
MAX_DAILY_PAYOUT  = 120.0


@dataclass
class TrafficReading:
    city:            str
    current_speed:   float   # km/h
    free_flow_speed: float   # km/h
    ratio:           float   # current / free_flow
    delay_minutes:   float
    severity:        float   # 0.0–1.0
    triggered:       bool
    source:          str


# ── Mock ──────────────────────────────────────────────────────────────────────

class MockTrafficService:
    def get_flow(self, city: str) -> tuple[float, float]:
        return 10.0, 60.0   # ratio = 0.167 → deep red


_mock = MockTrafficService()


# ── City coordinates ──────────────────────────────────────────────────────────

CITY_COORDS: dict[str, tuple[float, float]] = {
    "Mumbai":    (19.0760, 72.8777),
    "Delhi":     (28.6139, 77.2090),
    "Bangalore": (12.9716, 77.5946),
    "Chennai":   (13.0827, 80.2707),
    "Hyderabad": (17.3850, 78.4867),
    "Kolkata":   (22.5726, 88.3639),
    "Pune":      (18.5204, 73.8567),
    "Ahmedabad": (23.0225, 72.5714),
}


# ── Helpers ───────────────────────────────────────────────────────────────────

def _fetch_flow(city: str) -> tuple[float, float]:
    """Returns (current_speed_kmh, free_flow_speed_kmh)."""
    coords = CITY_COORDS.get(city)
    if not coords:
        logger.warning("[traffic_block] No coordinates for city=%s", city)
        return 999.0, 999.0

    lat, lon = coords
    try:
        resp = httpx.get(
            TOMTOM_FLOW_URL,
            params={"point": f"{lat},{lon}", "unit": "KMPH", "thickness": 2, "key": TOMTOM_API_KEY},
            timeout=10,
        )
        resp.raise_for_status()
        fd        = resp.json().get("flowSegmentData", {})
        current   = float(fd.get("currentSpeed",  999))
        free_flow = float(fd.get("freeFlowSpeed", 999))
        return current, free_flow
    except Exception as exc:
        logger.warning("[traffic_block] TomTom API error for city=%s: %s", city, exc)
        return 999.0, 999.0


def _severity(ratio: float) -> float:
    if ratio >= CONGESTION_RATIO:
        return 0.0
    return round(1.0 - (ratio / CONGESTION_RATIO), 4)


def _delay_minutes(current: float, free_flow: float, segment_km: float = 5.0) -> float:
    if current <= 0 or free_flow <= 0:
        return 0.0
    free_time    = (segment_km / free_flow) * 60
    current_time = (segment_km / current)  * 60
    return max(0.0, round(current_time - free_time, 2))


def _payout(delay_minutes: float) -> float:
    return min(delay_minutes * PAYOUT_PER_MINUTE, MAX_DAILY_PAYOUT)


# ── Public ────────────────────────────────────────────────────────────────────

def check_traffic(city: str) -> TrafficReading:
    if USE_MOCK:
        current, free_flow = _mock.get_flow(city)
        source = "mock"
    else:
        current, free_flow = _fetch_flow(city)
        source = "tomtom"

    ratio     = (current / free_flow) if free_flow > 0 else 1.0
    triggered = ratio < CONGESTION_RATIO
    delay     = _delay_minutes(current, free_flow) if triggered else 0.0

    return TrafficReading(
        city            = city,
        current_speed   = round(current, 2),
        free_flow_speed = round(free_flow, 2),
        ratio           = round(ratio, 4),
        delay_minutes   = delay,
        severity        = _severity(ratio),
        triggered       = triggered,
        source          = source,
    )


def check_traffic_for_cities(cities: list[str]) -> list[TrafficReading]:
    return [check_traffic(city) for city in cities]


def compute_traffic_payout(delay_minutes: float) -> float:
    return _payout(delay_minutes)