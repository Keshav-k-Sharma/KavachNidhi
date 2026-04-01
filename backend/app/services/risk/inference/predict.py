
import os
import pickle
import logging
import numpy as np
from typing import Union

logger = logging.getLogger(__name__)



_MODEL_PATH = os.path.join(os.path.dirname(__file__), "..", "models", "risk_model.pkl")

FEATURE_ORDER = ["zone_risk", "trigger_frequency", "avg_payout", "tier"]


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

    logger.info(f"[predict] Loaded risk model from {abs_path}")
    return _model


# ── Public API ────────────────────────────────────────────────────────────────

def predict_risk_score(
    zone_risk: float,
    trigger_frequency: float,
    avg_payout: float,
    tier: float,
) -> float:
    model = _load_model()
    features = np.array([[zone_risk, trigger_frequency, avg_payout, tier]], dtype=float)
    raw = float(model.predict(features)[0])
    return float(np.clip(raw, 0.0, 1.0))


def predict_risk_scores_batch(
    records: list[dict],
) -> list[float]:
    
    model = _load_model()
    matrix = np.array(
        [[r[f] for f in FEATURE_ORDER] for r in records], dtype=float
    )
    raw = model.predict(matrix)
    return [float(np.clip(v, 0.0, 1.0)) for v in raw]