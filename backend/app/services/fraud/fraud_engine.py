"""
FraudEngine — orchestrates SensorFusion + CollusionGraph.

On a new sensor reading:
  1. Run 6-layer sensor fusion
  2. If held/quarantined → write fraud_flag + fraud_review_queue
  3. Update driver_trigger_logs.status accordingly

Periodic colluion scan (called by KavachBrain engine):
  1. detect_collusion_clusters()
  2. Batch-hold the cluster → fraud_flags + review queue entries
"""
import logging
from datetime import datetime, timezone, timedelta

from app.config import get_supabase_client
from app.services.fraud.sensor_fusion  import run_sensor_fusion, FusionResult
from app.services.fraud.collusion_graph import detect_collusion_clusters

logger = logging.getLogger(__name__)


# ── DB writes ─────────────────────────────────────────────────────────────────

def _write_fraud_flag(
    driver_id:       str,
    trigger_log_id:  str | None,
    reason:          str,
    detection_layer: str,
    severity:        str,
    auto_action:     str,
) -> str:
    """Insert a fraud_flags row. Returns the new flag id."""
    supabase = get_supabase_client()
    result = supabase.table("fraud_flags").insert({
        "driver_id":       driver_id,
        "trigger_log_id":  trigger_log_id,
        "reason":          reason,
        "detection_layer": detection_layer,
        "severity":        severity,
        "auto_action":     auto_action,
        "created_at":      datetime.now(timezone.utc).isoformat(),
    }).execute()
    return result.data[0]["id"]


def _write_review_queue(fraud_flag_id: str, driver_id: str) -> None:
    """Insert a fraud_review_queue row (24h expiry)."""
    supabase   = get_supabase_client()
    expires_at = (datetime.now(timezone.utc) + timedelta(hours=24)).isoformat()
    supabase.table("fraud_review_queue").insert({
        "fraud_flag_id": fraud_flag_id,
        "driver_id":     driver_id,
        "status":        "pending",
        "expires_at":    expires_at,
        "created_at":    datetime.now(timezone.utc).isoformat(),
    }).execute()


def _update_trigger_log_status(
    driver_id:     str,
    fraud_flag_id: str,
    new_status:    str,   # 'held' | 'rejected'
) -> None:
    """Update the most recent trigger log for this driver."""
    supabase = get_supabase_client()
    # Fetch the latest trigger log
    result = (
        supabase.table("driver_trigger_logs")
        .select("id")
        .eq("driver_id", driver_id)
        .order("awarded_at", desc=True)
        .limit(1)
        .execute()
    )
    if not result.data:
        return
    log_id = result.data[0]["id"]
    supabase.table("driver_trigger_logs").update({
        "status":       new_status,
        "fraud_flag_id": fraud_flag_id,
    }).eq("id", log_id).execute()


def _verdict_to_auto_action(verdict: str) -> str:
    return {
        "held":        "held",
        "quarantined": "quarantined",
        "invalidated": "blocked",
    }.get(verdict, "held")


# ── Sensor reading entry point ────────────────────────────────────────────────

def process_sensor_reading(
    driver_id:  str,
    session_id: str,
    readings:   list[dict],
    wifi_lat:   float | None = None,
    wifi_lon:   float | None = None,
    gps_city:   str | None   = None,
    ip_city:    str | None   = None,
) -> dict:
    """
    Called when a new sensor reading batch arrives from the Flutter app.
    Runs fusion, writes fraud records if needed.
    Returns a summary dict.
    """
    fusion: FusionResult = run_sensor_fusion(
        driver_id  = driver_id,
        session_id = session_id,
        readings   = readings,
        wifi_lat   = wifi_lat,
        wifi_lon   = wifi_lon,
        gps_city   = gps_city,
        ip_city    = ip_city,
    )

    if fusion.verdict == "clean":
        return {
            "driver_id":    driver_id,
            "verdict":      "clean",
            "action_taken": None,
        }

    # Determine detection layer label for DB
    layer_label = (
        "mock_location" if fusion.mock_location
        else fusion.layers_flagged[0] if len(fusion.layers_flagged) == 1
        else "gps_spoof"
    )
    auto_action = _verdict_to_auto_action(fusion.verdict)

    # Write fraud_flag
    flag_id = _write_fraud_flag(
        driver_id       = driver_id,
        trigger_log_id  = None,   # linked later when we match to a log
        reason          = fusion.reason,
        detection_layer = layer_label,
        severity        = fusion.severity,
        auto_action     = auto_action,
    )

    # Update trigger log status
    if fusion.verdict in ("held", "quarantined"):
        _update_trigger_log_status(driver_id, flag_id, "held")
    elif fusion.verdict == "invalidated":
        _update_trigger_log_status(driver_id, flag_id, "rejected")

    # Queue for human review (except clean invalidations)
    if fusion.verdict in ("held", "quarantined"):
        _write_review_queue(flag_id, driver_id)

    logger.warning(
        "[fraud_engine] %s driver=%s layers=%s flag_id=%s",
        fusion.verdict.upper(), driver_id, fusion.layers_flagged, flag_id,
    )

    return {
        "driver_id":     driver_id,
        "verdict":       fusion.verdict,
        "action_taken":  auto_action,
        "fraud_flag_id": flag_id,
        "layers":        fusion.layers_flagged,
        "reason":        fusion.reason,
    }


# ── Collusion scan (called periodically by KavachBrain engine) ────────────────

def run_collusion_scan() -> dict:
    """
    Detect colluding clusters and batch-hold their members.
    Returns summary of clusters flagged.
    """
    clusters = detect_collusion_clusters()
    total_flagged = 0

    for cluster in clusters:
        driver_ids = cluster["driver_ids"]
        reason     = cluster["reason"]

        for driver_id in driver_ids:
            try:
                flag_id = _write_fraud_flag(
                    driver_id       = driver_id,
                    trigger_log_id  = None,
                    reason          = reason,
                    detection_layer = "collusion_graph",
                    severity        = "high",
                    auto_action     = "held",
                )
                _update_trigger_log_status(driver_id, flag_id, "held")
                _write_review_queue(flag_id, driver_id)
                total_flagged += 1
            except Exception as exc:
                logger.error(
                    "[fraud_engine] collusion hold failed for driver=%s: %s",
                    driver_id, exc,
                )

    logger.info(
        "[fraud_engine] Collusion scan done — clusters=%d drivers_flagged=%d",
        len(clusters), total_flagged,
    )
    return {"clusters_detected": len(clusters), "drivers_flagged": total_flagged}


# ── Admin review ──────────────────────────────────────────────────────────────

def apply_review_decision(flag_id: str, approved: bool, reviewer_notes: str = "") -> dict:
    """
    Process an admin review decision.
    approved=True  → release held credits (set trigger_log to 'awarded')
    approved=False → reject credits permanently
    """
    supabase = get_supabase_client()

    # Fetch flag
    flag_result = (
        supabase.table("fraud_flags")
        .select("driver_id, trigger_log_id")
        .eq("id", flag_id)
        .maybe_single()
        .execute()
    )
    if not flag_result.data:
        raise ValueError(f"Fraud flag {flag_id} not found")

    driver_id      = flag_result.data["driver_id"]
    trigger_log_id = flag_result.data.get("trigger_log_id")

    new_log_status = "awarded" if approved else "rejected"

    # Update trigger log if linked
    if trigger_log_id:
        supabase.table("driver_trigger_logs").update({
            "status": new_log_status,
        }).eq("id", trigger_log_id).execute()

    # Update review queue
    supabase.table("fraud_review_queue").update({
        "status":         "approved" if approved else "rejected",
        "reviewer_notes": reviewer_notes,
        "reviewed_at":    datetime.now(timezone.utc).isoformat(),
    }).eq("fraud_flag_id", flag_id).execute()

    logger.info(
        "[fraud_engine] Review decision: flag=%s driver=%s approved=%s",
        flag_id, driver_id, approved,
    )

    return {
        "flag_id":    flag_id,
        "driver_id":  driver_id,
        "decision":   "approved" if approved else "rejected",
        "log_status": new_log_status,
    }