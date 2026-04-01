"""
Run from the repo root:
    python -m app.services.risk.train.train_model

The trained model is saved to:
    app/services/risk/models/risk_model.pkl
"""

import os
import pickle
import numpy as np
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_error, r2_score

# ── Paths ───────────────────────────────────────────────────────────────────

MODELS_DIR = os.path.join(os.path.dirname(__file__), "..", "models")
MODEL_PATH = os.path.join(MODELS_DIR, "risk_model.pkl")

# ── Synthetic data config ─────────────────────────────────────────────────────

N_SAMPLES = 10_000
RANDOM_SEED = 42
NOISE_STD = 0.03         


def generate_synthetic_data(n_samples: int = N_SAMPLES, seed: int = RANDOM_SEED):
    
    rng = np.random.default_rng(seed)

    zone_risk          = rng.uniform(0.0, 1.0, n_samples)
    trigger_frequency  = rng.uniform(0.0, 1.0, n_samples)
    avg_payout         = rng.uniform(50.0, 200.0, n_samples)
    tier               = rng.choice([0.2, 0.5, 1.0], size=n_samples)

    noise = rng.normal(0, NOISE_STD, n_samples)

    risk_score = (
        0.5 * zone_risk
        + 0.3 * trigger_frequency
        + 0.2 * (avg_payout / 200.0)
        + noise
    )
    risk_score = np.clip(risk_score, 0.0, 1.0)

    X = np.column_stack([zone_risk, trigger_frequency, avg_payout, tier])
    y = risk_score
    return X, y


def train(n_samples: int = N_SAMPLES, seed: int = RANDOM_SEED) -> RandomForestRegressor:

    print(f"[train] Generating {n_samples} synthetic samples …")
    X, y = generate_synthetic_data(n_samples, seed)

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=seed
    )

    model = RandomForestRegressor(
        n_estimators=200,
        max_depth=12,
        min_samples_leaf=5,
        n_jobs=-1,
        random_state=seed,
    )

    print("[train] Fitting RandomForestRegressor …")
    model.fit(X_train, y_train)

    y_pred = model.predict(X_test)
    mae = mean_absolute_error(y_test, y_pred)
    r2  = r2_score(y_test, y_pred)
    print(f"[train] MAE={mae:.4f}  R²={r2:.4f}")

    os.makedirs(MODELS_DIR, exist_ok=True)
    with open(MODEL_PATH, "wb") as f:
        pickle.dump(model, f)
    print(f"[train] Model saved → {MODEL_PATH}")

    return model


if __name__ == "__main__":
    train()