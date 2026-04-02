"""
KavachNidhi — AJ's Integration Test Script
==========================================
Tests everything AJ owns: weather APIs, traffic API,
KavachBrain tick, risk scoring, and fraud detection layers.

Run from backend/ directory:
    python test_my_stuff.py

No server needed. No JWT. No teammates.
"""
import os
import sys
from dotenv import load_dotenv
load_dotenv()

# ── Colour helpers ────────────────────────────────────────────────────────────

GREEN  = "\033[92m"
RED    = "\033[91m"
YELLOW = "\033[93m"
CYAN   = "\033[96m"
BOLD   = "\033[1m"
RESET  = "\033[0m"

def ok(msg):    print(f"  {GREEN}✓ {msg}{RESET}")
def fail(msg):  print(f"  {RED}✗ {msg}{RESET}")
def info(msg):  print(f"  {YELLOW}→ {msg}{RESET}")
def header(msg):print(f"\n{BOLD}{CYAN}{'─'*50}\n  {msg}\n{'─'*50}{RESET}")


# ── 1. ENV VARS ───────────────────────────────────────────────────────────────

header("1. Environment Variables")

required_vars = [
    "OPENWEATHERMAP_API_KEY",
    "TOMTOM_API_KEY",
    "SUPABASE_URL",
    "SUPABASE_SERVICE_ROLE_KEY",
]
env_ok = True
for var in required_vars:
    val = os.getenv(var, "")
    if val:
        ok(f"{var} = {val[:8]}{'*' * 8}  (set)")
    else:
        fail(f"{var} is NOT set — check your .env")
        env_ok = False

if not env_ok:
    print(f"\n{RED}Some env vars are missing. Load your .env first:{RESET}")
    print("  export $(cat .env | xargs)  # Linux/Mac")
    print("  or run: python -m dotenv run python test_my_stuff.py")
    sys.exit(1)


# ── 2. OPENWEATHERMAP — FOG CHECK ─────────────────────────────────────────────

header("2. OpenWeatherMap API — Fog (Delhi)")

try:
    from app.services.kavachbrain.fog_block import check_fog
    reading = check_fog("Delhi")
    ok(f"API responded — visibility={reading.visibility_m}m  source={reading.source}")
    info(f"In fog time window (04–10 IST): {reading.in_time_window}")
    info(f"Fog triggered: {reading.triggered}  severity={reading.severity}")
    if reading.source == "openweathermap":
        ok("Real OpenWeatherMap data received")
    else:
        fail("Got mock data — check USE_MOCK_WEATHER=false in .env")
except Exception as e:
    fail(f"Fog check failed: {e}")


# ── 3. OPENWEATHERMAP — CYCLONE CHECK ─────────────────────────────────────────

header("3. OpenWeatherMap API — Cyclone (Mumbai)")

try:
    from app.services.kavachbrain.cyclone_guard import check_cyclone
    reading = check_cyclone("Mumbai")
    ok(f"API responded — wind={reading.wind_kmh} km/h  alert={reading.has_alert}  source={reading.source}")
    info(f"Cyclone triggered: {reading.triggered}  severity={reading.severity}")
    if reading.source == "openweathermap":
        ok("Real OpenWeatherMap data received")
    else:
        fail("Got mock data — check USE_MOCK_WEATHER=false in .env")
except Exception as e:
    fail(f"Cyclone check failed: {e}")


# ── 4. TOMTOM — TRAFFIC CHECK ─────────────────────────────────────────────────

header("4. TomTom API — Traffic (Bangalore)")

try:
    from app.services.kavachbrain.traffic_block import check_traffic
    reading = check_traffic("Bangalore")
    ok(f"API responded — current={reading.current_speed} km/h  free_flow={reading.free_flow_speed} km/h  source={reading.source}")
    info(f"Ratio: {reading.ratio}  (trigger if < 0.3)")
    info(f"Traffic triggered: {reading.triggered}  delay={reading.delay_minutes} min")
    if reading.source == "tomtom":
        ok("Real TomTom data received")
    else:
        fail("Got mock data — check USE_MOCK_TRAFFIC=false in .env")
except Exception as e:
    fail(f"Traffic check failed: {e}")


# ── 5. RISK SCORING ───────────────────────────────────────────────────────────

header("5. Risk Scoring — ML Pipeline")

try:
    from app.services.risk.inference.service import get_pricing

    test_cases = [
        {"zone_risk": 0.2, "trigger_frequency": 0.1, "avg_payout": 60.0,  "tier": 0.2, "label": "Low risk  (basic)"},
        {"zone_risk": 0.5, "trigger_frequency": 0.4, "avg_payout": 120.0, "tier": 0.5, "label": "Mid risk  (plus)"},
        {"zone_risk": 0.9, "trigger_frequency": 0.8, "avg_payout": 180.0, "tier": 1.0, "label": "High risk (max)"},
    ]

    for case in test_cases:
        label = case.pop("label")
        result = get_pricing(case)
        ok(f"{label} → risk_score={result['risk_score']}  premium=₹{result['weekly_premium']}")

except FileNotFoundError:
    fail("risk_model.pkl not found — run: python -m app.services.risk.train.train_model")
except Exception as e:
    fail(f"Risk scoring failed: {e}")


# ── 6. FRAUD — MOCK LAYER TEST ────────────────────────────────────────────────

header("6. Fraud Detection — Layer Logic (no DB needed)")

try:
    from app.services.kavachbrain.fog_block import _is_fog_window
    from app.services.kavachbrain.traffic_block import _severity as traffic_severity
    from app.services.kavachbrain.cyclone_guard import _severity as cyclone_severity

    # Test severity functions directly
    ok(f"Cyclone severity at 75 km/h  = {cyclone_severity(75.0):.3f}  (expect > 0)")
    ok(f"Cyclone severity at 40 km/h  = {cyclone_severity(40.0):.3f}  (expect 0.0)")
    ok(f"Traffic severity ratio=0.1   = {traffic_severity(0.1):.3f}  (expect > 0)")
    ok(f"Traffic severity ratio=0.5   = {traffic_severity(0.5):.3f}  (expect 0.0)")
    info(f"Fog time window active right now: {_is_fog_window()}")

except Exception as e:
    fail(f"Fraud layer logic test failed: {e}")


# ── 7. KAVACHBRAIN — SINGLE TICK (needs DB) ───────────────────────────────────

header("7. KavachBrain — Single Tick (requires Supabase)")

run_tick = input(f"\n  {YELLOW}Run a full KavachBrain tick against your Supabase DB? (y/n): {RESET}").strip().lower()

if run_tick == "y":
    try:
        from app.services.kavachbrain.engine import _run_tick
        info("Running tick — watch for FIRED events in output below …")
        print()
        _run_tick()
        print()
        ok("Tick completed without crashing")
        info("Check your Supabase sensor_events and trigger_events tables to confirm writes")
    except Exception as e:
        fail(f"Tick failed: {e}")
else:
    info("Skipped — run manually: from app.services.kavachbrain.engine import _run_tick; _run_tick()")


# ── Summary ───────────────────────────────────────────────────────────────────

print(f"\n{BOLD}{'─'*50}")
print(f"  Done. Fix any ✗ lines above.")
print(f"{'─'*50}{RESET}\n")