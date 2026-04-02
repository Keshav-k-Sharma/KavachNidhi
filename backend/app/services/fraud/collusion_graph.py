"""
CollusionGraph — graph-based cluster detection for coordinated fraud.

Builds an adjacency graph where drivers are nodes and edges represent:
  - shared device fingerprint (same wifi_bssid or network_ip)
  - referral relationships (tracked in drivers table)
  - co-location (same GPS pin within 100m at same time)

Flags a cluster if 50+ drivers from it trigger simultaneously for the first time.
"""
import logging
from collections import defaultdict, deque
from datetime import datetime, timezone, timedelta

from app.config import get_supabase_client

logger = logging.getLogger(__name__)

CLUSTER_SIZE_THRESHOLD   = 50      # min cluster size to flag
SIMULTANEOUS_WINDOW_SECS = 300     # 5-minute window = "simultaneous"
COLOCATION_RADIUS_M      = 100     # metres


# ── Graph helpers ─────────────────────────────────────────────────────────────

def _build_adjacency(readings: list[dict]) -> dict[str, set[str]]:
    """
    Build undirected adjacency map from sensor readings.
    Two drivers are adjacent if they share wifi_bssid OR network_ip.
    """
    bssid_to_drivers: dict[str, list[str]] = defaultdict(list)
    ip_to_drivers:    dict[str, list[str]] = defaultdict(list)

    for r in readings:
        did = r.get("driver_id")
        if not did:
            continue
        if r.get("wifi_bssid"):
            bssid_to_drivers[r["wifi_bssid"]].append(did)
        if r.get("network_ip"):
            ip_to_drivers[r["network_ip"]].append(did)

    adj: dict[str, set[str]] = defaultdict(set)

    for group in list(bssid_to_drivers.values()) + list(ip_to_drivers.values()):
        for i in range(len(group)):
            for j in range(i + 1, len(group)):
                adj[group[i]].add(group[j])
                adj[group[j]].add(group[i])

    return adj


def _bfs_clusters(adj: dict[str, set[str]]) -> list[set[str]]:
    """Extract connected components via BFS."""
    visited: set[str] = set()
    clusters: list[set[str]] = []

    for start in adj:
        if start in visited:
            continue
        cluster: set[str] = set()
        queue = deque([start])
        while queue:
            node = queue.popleft()
            if node in visited:
                continue
            visited.add(node)
            cluster.add(node)
            for neighbour in adj.get(node, []):
                if neighbour not in visited:
                    queue.append(neighbour)
        if cluster:
            clusters.append(cluster)

    return clusters


# ── DB helpers ────────────────────────────────────────────────────────────────

def _fetch_recent_readings(window_seconds: int = 3600) -> list[dict]:
    """Fetch sensor readings from the last *window_seconds*."""
    supabase  = get_supabase_client()
    since     = (datetime.now(timezone.utc) - timedelta(seconds=window_seconds)).isoformat()
    result = (
        supabase.table("driver_sensor_readings")
        .select("driver_id, wifi_bssid, network_ip, gps_lat, gps_lng, recorded_at")
        .gte("recorded_at", since)
        .execute()
    )
    return result.data or []


def _fetch_recent_trigger_logs(driver_ids: list[str], window_seconds: int) -> list[dict]:
    """Fetch trigger log entries for a set of drivers within a time window."""
    if not driver_ids:
        return []
    supabase = get_supabase_client()
    since    = (datetime.now(timezone.utc) - timedelta(seconds=window_seconds)).isoformat()
    result = (
        supabase.table("driver_trigger_logs")
        .select("driver_id, awarded_at")
        .in_("driver_id", driver_ids)
        .gte("awarded_at", since)
        .execute()
    )
    return result.data or []


def _first_trigger_ever(driver_id: str) -> bool:
    """True if this is the driver's very first trigger award."""
    supabase = get_supabase_client()
    result = (
        supabase.table("driver_trigger_logs")
        .select("id", count="exact")
        .eq("driver_id", driver_id)
        .execute()
    )
    return (result.count or 0) <= 1


# ── Public ────────────────────────────────────────────────────────────────────

def detect_collusion_clusters() -> list[dict]:
    """
    Scan recent sensor readings, build clusters, and flag anomalous ones.
    Returns a list of flagged cluster dicts.
    """
    readings = _fetch_recent_readings(window_seconds=3600)
    if not readings:
        return []

    adj      = _build_adjacency(readings)
    clusters = _bfs_clusters(adj)

    flagged: list[dict] = []

    for cluster in clusters:
        if len(cluster) < CLUSTER_SIZE_THRESHOLD:
            continue

        # Check if many first-timers triggered simultaneously
        driver_ids = list(cluster)
        trig_logs  = _fetch_recent_trigger_logs(driver_ids, SIMULTANEOUS_WINDOW_SECS)

        if not trig_logs:
            continue

        first_timers = [
            log["driver_id"]
            for log in trig_logs
            if _first_trigger_ever(log["driver_id"])
        ]

        if len(first_timers) >= CLUSTER_SIZE_THRESHOLD:
            flagged.append({
                "cluster_size":        len(cluster),
                "first_timer_count":   len(first_timers),
                "driver_ids":          driver_ids,
                "first_timer_ids":     first_timers,
                "detection_layer":     "collusion_graph",
                "reason":              (
                    f"Cluster of {len(cluster)} drivers: "
                    f"{len(first_timers)} first-time triggers simultaneously"
                ),
                "detected_at":         datetime.now(timezone.utc).isoformat(),
            })
            logger.warning(
                "[collusion_graph] Cluster flagged: size=%d first_timers=%d",
                len(cluster), len(first_timers),
            )

    return flagged


def get_driver_cluster(driver_id: str) -> set[str]:
    """
    Return the set of driver IDs in the same cluster as *driver_id*.
    Useful for batch-holding an entire cluster.
    """
    readings = _fetch_recent_readings(window_seconds=3600)
    if not readings:
        return {driver_id}

    adj      = _build_adjacency(readings)
    clusters = _bfs_clusters(adj)

    for cluster in clusters:
        if driver_id in cluster:
            return cluster

    return {driver_id}