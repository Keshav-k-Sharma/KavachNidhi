"""
SensorFusion — 6-layer GPS spoof detection.

Layer 1 — Accelerometer: no movement 4h while GPS says "in transit"
Layer 2 — Gyroscope: no orientation changes consistent with vehicle motion
Layer 3 — Wi-Fi triangulation: cell tower location 4+ km off GPS pin
Layer 4 — Network IP: GPS city ≠ IP geolocation city
Layer 5 — Mock Location API: Android dev mode + mock location enabled → immediate quarantine
Layer 6 — Velocity: teleported 3+ km in 45 seconds → invalidated

Rules:
  - Layer 5 alone → QUARANTINED
  - 2+ other layers → HELD + fraud_flag created → review queue
"""
import logging
import math
from datetime import datetime, timezone, timedelta
from dataclasses import dataclass, field

logger = logging.getLogger(__name__)

# ── Thresholds ─────────────────────────────────────────────────────────────────

ACCEL_IDLE_THRESHOLD       = 0.15    # m/s² — below this = "stationary"
ACCEL_IDLE_DURATION_H      = 4.0     # hours
GYRO_IDLE_THRESHOLD        = 0.05    # rad/s — below this = "no rotation"
WIFI_MISMATCH_KM           = 4.0     # km — max allowed GPS vs Wi-Fi drift
VELOCITY_TELEPORT_KM       = 3.0     # km
VELOCITY_TELEPORT_SECONDS  = 45.0    # seconds


@dataclass
class FusionResult:
    driver_id:        str
    session_id:       str
    layers_flagged:   list[str] = field(default_factory=list)
    mock_location:    bool = False
    verdict:          str = "clean"     # 'clean' | 'held' | 'quarantined' | 'invalidated'
    severity:         str = "low"       # 'low' | 'medium' | 'high'
    reason:           str = ""


# ── Haversine distance ────────────────────────────────────────────────────────

def _haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    R = 6371.0
    d_lat = math.radians(lat2 - lat1)
    d_lon = math.radians(lon2 - lon1)
    a = (
        math.sin(d_lat / 2) ** 2
        + math.cos(math.radians(lat1))
        * math.cos(math.radians(lat2))
        * math.sin(d_lon / 2) ** 2
    )
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


# ── Individual layer checks ───────────────────────────────────────────────────

def _layer1_accelerometer(readings: list[dict]) -> bool:
    """
    True (flagged) if accelerometer shows no movement for 4h
    but GPS reports the driver as "in transit" (velocity > 5 km/h).
    """
    if not readings:
        return False

    now = datetime.now(timezone.utc)
    cutoff = now - timedelta(hours=ACCEL_IDLE_DURATION_H)
    window = [
        r for r in readings
        if _parse_ts(r.get("recorded_at")) >= cutoff
    ]
    if not window:
        return False

    accel_magnitudes = []
    gps_moving = []
    for r in window:
        acc = r.get("accelerometer") or {}
        x, y, z = acc.get("x", 0), acc.get("y", 0), acc.get("z", 0)
        mag = math.sqrt(x**2 + y**2 + z**2)
        accel_magnitudes.append(mag)
        gps_moving.append((r.get("velocity_kmh") or 0) > 5.0)

    if not accel_magnitudes:
        return False

    avg_accel   = sum(accel_magnitudes) / len(accel_magnitudes)
    ever_moving = any(gps_moving)

    return avg_accel < ACCEL_IDLE_THRESHOLD and ever_moving


def _layer2_gyroscope(readings: list[dict]) -> bool:
    """
    True (flagged) if gyroscope shows no rotation while GPS has velocity > 5 km/h.
    """
    if not readings:
        return False

    gyro_magnitudes = []
    gps_moving      = []
    for r in readings[-20:]:   # last 20 readings
        gyro = r.get("gyroscope") or {}
        x, y, z = gyro.get("x", 0), gyro.get("y", 0), gyro.get("z", 0)
        mag = math.sqrt(x**2 + y**2 + z**2)
        gyro_magnitudes.append(mag)
        gps_moving.append((r.get("velocity_kmh") or 0) > 5.0)

    if not gyro_magnitudes:
        return False

    avg_gyro    = sum(gyro_magnitudes) / len(gyro_magnitudes)
    ever_moving = any(gps_moving)

    return avg_gyro < GYRO_IDLE_THRESHOLD and ever_moving


def _layer3_wifi(readings: list[dict], wifi_lat: float | None, wifi_lon: float | None) -> bool:
    """
    True (flagged) if Wi-Fi triangulated location is 4+ km away from GPS pin.
    """
    if wifi_lat is None or wifi_lon is None:
        return False

    recent = readings[-1] if readings else None
    if not recent:
        return False

    gps_lat = recent.get("gps_lat")
    gps_lon = recent.get("gps_lng")
    if gps_lat is None or gps_lon is None:
        return False

    distance = _haversine_km(gps_lat, gps_lon, wifi_lat, wifi_lon)
    return distance >= WIFI_MISMATCH_KM


def _layer4_ip_city(gps_city: str | None, ip_city: str | None) -> bool:
    """
    True (flagged) if IP-geolocated city does not match GPS city.
    Simple case-insensitive string match.
    """
    if not gps_city or not ip_city:
        return False
    return gps_city.strip().lower() != ip_city.strip().lower()


def _layer5_mock_location(readings: list[dict]) -> bool:
    """True if any reading has mock_location = True."""
    return any(r.get("mock_location") is True for r in readings)


def _layer6_velocity(readings: list[dict]) -> bool:
    """
    True (flagged/invalidated) if driver teleported 3+ km in 45 seconds.
    """
    if len(readings) < 2:
        return False

    for i in range(len(readings) - 1):
        r1, r2 = readings[i], readings[i + 1]
        t1, t2 = _parse_ts(r1.get("recorded_at")), _parse_ts(r2.get("recorded_at"))
        if t1 is None or t2 is None:
            continue

        dt_seconds = abs((t2 - t1).total_seconds())
        if dt_seconds == 0 or dt_seconds > VELOCITY_TELEPORT_SECONDS:
            continue

        lat1, lon1 = r1.get("gps_lat"), r1.get("gps_lng")
        lat2, lon2 = r2.get("gps_lat"), r2.get("gps_lng")
        if any(v is None for v in [lat1, lon1, lat2, lon2]):
            continue

        dist_km = _haversine_km(lat1, lon1, lat2, lon2)
        if dist_km >= VELOCITY_TELEPORT_KM:
            return True

    return False


def _parse_ts(ts: str | None) -> datetime | None:
    if not ts:
        return None
    try:
        return datetime.fromisoformat(ts.replace("Z", "+00:00"))
    except ValueError:
        return None


# ── Public ────────────────────────────────────────────────────────────────────

def run_sensor_fusion(
    driver_id:  str,
    session_id: str,
    readings:   list[dict],
    wifi_lat:   float | None = None,
    wifi_lon:   float | None = None,
    gps_city:   str | None   = None,
    ip_city:    str | None   = None,
) -> FusionResult:
    """
    Run all 6 fraud detection layers against the given sensor readings.
    Returns a FusionResult with verdict and layers_flagged.
    """
    result = FusionResult(driver_id=driver_id, session_id=session_id)

    # Layer 5 — immediate quarantine (checked first)
    if _layer5_mock_location(readings):
        result.layers_flagged.append("mock_location")
        result.mock_location = True
        result.verdict   = "quarantined"
        result.severity  = "high"
        result.reason    = "Mock location / Android developer mode detected"
        logger.warning(
            "[sensor_fusion] QUARANTINE driver=%s session=%s (mock location)",
            driver_id, session_id,
        )
        return result

    # Layer 6 — velocity teleport → invalidated
    if _layer6_velocity(readings):
        result.layers_flagged.append("velocity")
        result.verdict  = "invalidated"
        result.severity = "medium"
        result.reason   = f"GPS teleport detected (>{VELOCITY_TELEPORT_KM} km in <{VELOCITY_TELEPORT_SECONDS}s)"
        logger.warning(
            "[sensor_fusion] INVALIDATED driver=%s session=%s (velocity teleport)",
            driver_id, session_id,
        )
        return result

    # Layers 1–4 — accumulate flags
    if _layer1_accelerometer(readings):
        result.layers_flagged.append("accelerometer")
    if _layer2_gyroscope(readings):
        result.layers_flagged.append("gyroscope")
    if _layer3_wifi(readings, wifi_lat, wifi_lon):
        result.layers_flagged.append("wifi_triangulation")
    if _layer4_ip_city(gps_city, ip_city):
        result.layers_flagged.append("ip_mismatch")

    n_flags = len(result.layers_flagged)

    if n_flags == 0:
        result.verdict  = "clean"
        result.severity = "low"
    elif n_flags == 1:
        # Single soft flag — note but don't hold
        result.verdict  = "clean"
        result.severity = "low"
        result.reason   = f"Minor anomaly on layer: {result.layers_flagged[0]}"
    else:
        # 2+ layers → hold and send to review queue
        result.verdict  = "held"
        result.severity = "high" if n_flags >= 3 else "medium"
        result.reason   = (
            f"{n_flags} fraud layers triggered: "
            + ", ".join(result.layers_flagged)
        )
        logger.warning(
            "[sensor_fusion] HELD driver=%s session=%s layers=%s",
            driver_id, session_id, result.layers_flagged,
        )

    return result