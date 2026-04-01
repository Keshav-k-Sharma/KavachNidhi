
import os
import pickle
import logging
import numpy as np

logger = logging.getLogger(__name__)

# ── Model path ────────────────────────────────────────────────────────────────

_MODEL_PATH = os.path.join(os.path.dirname(__file__), "..", "models", "risk_model.pkl")

# Feature column order — must match train_model.py exactly
FEATURE_ORDER = ["zone_risk", "trigger_frequency", "avg_payout", "tier"]

# ── Normalisation constants  ─────────────────────

AVG_PAYOUT_MIN  = 50.0
AVG_PAYOUT_RANGE = 150.0   # 200 - 50

TIER_MIN   = 0.2
TIER_RANGE = 0.8            # 1.0 - 0.2

# ── Model loading — lazy singleton ────────────────────────────────────────────

_model = None


def _load_model():
    global _model
    if _model is not None:
        return _model

    abs_path = os.path.abspath(_MODEL_PATH)
    if not os.path.exists(abs_path):
        raise FileNotFoundError(
            f"risk_model.pkl not found at {abs_path}. "
            "Run `python -m app.services.risk.train.train_model` first."
        )

    with open(abs_path, "rb") as f:
        _model = pickle.load(f)

    logger.info("[predict] Loaded risk model from %s", abs_path)
    return _model


# ── Normalisation helpers ─────────────────────────────────────────────────────

def _normalise(zone_risk: float, trigger_frequency: float,
               avg_payout: float, tier: float) -> list[float]:
    
    avg_payout_norm = (avg_payout - AVG_PAYOUT_MIN) / AVG_PAYOUT_RANGE
    tier_norm       = (tier - TIER_MIN) / TIER_RANGE
    return [
        float(np.clip(zone_risk, 0.0, 1.0)),
        float(np.clip(trigger_frequency, 0.0, 1.0)),
        float(np.clip(avg_payout_norm, 0.0, 1.0)),
        float(np.clip(tier_norm, 0.0, 1.0)),
    ]


# ── Public API ────────────────────────────────────────────────────────────────

def predict_risk_score(zone_risk: float, trigger_frequency: float,
                       avg_payout: float, tier: float) -> float:
    
    model    = _load_model()
    features = np.array([_normalise(zone_risk, trigger_frequency, avg_payout, tier)])
    raw      = float(model.predict(features)[0])
    return float(np.clip(raw, 0.0, 1.0))


def predict_risk_scores_batch(records: list[dict]) -> list[float]:
    
    model  = _load_model()
    matrix = np.array(
        [_normalise(r["zone_risk"], r["trigger_frequency"],
                    r["avg_payout"], r["tier"]) for r in records]
    )
    raw = model.predict(matrix)
    return [float(np.clip(v, 0.0, 1.0)) for v in raw]