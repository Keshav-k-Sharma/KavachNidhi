<div align="center">

# 🛡️ KavachNidhi
### India's First Parametric Income Insurance for Gig Workers

**What if your income had a seatbelt?**

</div>

---

## 📌 What · Why · How

| | |
|---|---|
| **⚡ What** | Parametric income insurance that pays gig workers automatically when weather or traffic kills their earnings |
| **💡 Why** | A cyclone shuts down Chennai. A driver loses ₹800 staying home safely. Traditional insurance needs 3 forms and 2 weeks. We pay in seconds. |
| **⚙️ How** | Real-time data triggers replace manual claims. No forms. No calls. Shield Credits accumulate through the week and hit your UPI every Sunday at 6 PM. |

---

## 🛡️ The Three Shields

> We insure a driver's **time and environment** — not accidents, not health. The things nobody else covers.

<table>
<tr>
<td align="center" width="33%">

### 🌀 CycloneGuard
**Up to ₹300 per event**

IMD issues a coastal storm warning → every driver registered in that city gets a pre-emptive payout before the storm hits.

`No GPS` · `No check-in` · `Just money`

</td>
<td align="center" width="33%">

### 🌫️ FogBlock
**₹80–120 per morning shift**

Visibility drops below 200m during 4–10 AM → the entire morning shift is compensated. North India, Nov–Feb only.

`Nobody should risk their life for a ₹40 delivery`

</td>
<td align="center" width="33%">

### 🚦 TrafficBlock
**₹2/min · max ₹120/day**

Google Maps + TomTom confirm deep red + delivery platform confirms delay → ₹2 per minute of wasted time.

`No GPS required` · `Platform data does it`

</td>
</tr>
</table>

---

## 📱 The App

<div align="center">

| Dashboard | Subscriptions | Earnings Profile | Wallet & History |
|:---------:|:-------------:|:----------------:|:----------------:|
| <img width="430" height="1498" alt="Dashboard" src="https://github.com/user-attachments/assets/e8d9d09c-b5ba-4adc-9279-13552c52e1eb" />| <img width="430" height="2328" alt="Subscriptions" src="https://github.com/user-attachments/assets/1a254452-4992-4316-a44a-be2887763e35" /> | <img width="430" height="1593" alt="Earnings Profile" src="https://github.com/user-attachments/assets/89e06b04-3dff-4d3d-9f02-536ece19d366" /> | <img width="430" height="1316" alt="Wallet   History" src="https://github.com/user-attachments/assets/84493773-5eeb-42ce-a500-7fd9311c0e4c" /> |
| 📡 Live sensor alerts · Shield Credits · weekly countdown | 📋 Pick tier · UPI AutoPay · NACH mandate | 📊 90-day baseline · peak windows · DPDP toggles | 🧾 Audit ledger · disbursements · fraud flags |

</div>

---

## 🧠 KavachBrain — The AI Engine

> Not a rule engine. Not a cron job. A continuous ML system that evaluates every enrolled driver every 60 seconds.

```
🔄 Every 60 seconds →
  📍 Pull city zone → fetch IMD + weather + traffic readings
  ⚡ Run all 3 trigger modules
  ✅ Threshold crossed? → TriggerEvent → Shield Credits added instantly
  🔒 Log to immutable Audit Ledger
  🔁 Repeat forever
```
---

## 💳 Tiers
 
<table>
<tr>
<td align="center" width="33%">
 
### 🔵 Kavach Basic
**₹50 / week**
 
`Weekly cap: ₹400`
 
🌀 CycloneGuard ✅
🌫️ FogBlock ❌
🚦  ❌
 
📈 Severity: 1.0x
💸 Settlement: Sunday
 
</td>
<td align="center" width="33%">
 
### 🟠 Kavach Plus ⭐
**₹70 / week**
 
`Weekly cap: ₹700`
 
🌀 CycloneGuard ✅
🌫️ FogBlock ✅
🚦 TrafficBlock ❌
 
📈 Severity: 1.0x
💸 Settlement: Instant wallet
 
</td>
<td align="center" width="33%">
 
### 🟡 Kavach Max
**₹90 / week**
 
`Weekly cap: ₹1,000`
 
🌀 CycloneGuard ✅
🌫️ FogBlock ✅
🚦 TrafficBlock ✅
 
📈 Severity: **1.2x**
💸 Settlement: Priority + Instant
 
</td>
</tr>
</table>
 
> 📅 Deducted every Monday via UPI AutoPay or NACH. No subscription = no coverage that week.
 
---

### 📐 Premium Pricing Model

Premiums aren't flat — they're risk-loaded per driver.

```
Weekly Premium = Base Rate × (1 + risk_score × 0.5)
```

`risk_score` is a weighted composite between 0 and 1:

```
risk_score = (location_risk × 0.4) + (trigger_frequency × 0.4) + (tier_risk × 0.2)
```

| 🔢 Component | 📋 What it measures |
|---|---|
| `📍 location_risk` | Driver's city zone — coastal cyclone belt scores higher than inland |
| `📊 trigger_frequency` | How often events actually fired for this driver in the last 90 days |
| `🎚️ tier_risk` | Subscription tier exposure — Max unlocks TrafficBlock which fires far more often |

> ⚠️ A risk score of 1.0 = 1.5× the base rate. Weights are seeded manually at launch and retrained against real loss ratios after the Phase 1 pilot.

---

## 🔐 Anti-Fraud System

> Automatic payouts are a fraud magnet. We designed against it from day one.

### 🛰️ GPS Anti-Spoofing — 6-Layer Sensor Fusion
GPS is never trusted alone. Every location claim is cross-checked simultaneously:

```
📱 Accelerometer       → No movement for 4 hours while GPS says "in transit"   FLAGGED
🔄 Gyroscope           → No orientation change consistent with a vehicle        FLAGGED
📶 Wi-Fi triangulation → Cell towers 4km off from GPS pin                       FLAGGED
🌐 Network IP          → GPS says Chennai. IP says Hyderabad.                   FLAGGED
🚫 Mock Location API   → Android dev mode + mock locations enabled              QUARANTINED
💨 Velocity check      → Teleported 3km in 45 seconds                          INVALIDATED
```

> GPS spoofers change coordinates. They don't change physics.

### 🕸️ Collusion Detection — Graph Analysis
KavachBrain builds a live social graph of driver relationships — referral chains, shared device networks, co-location history.

- 👥 200 drivers from the same cluster trigger simultaneously for the first time → statistically impossible → **cluster held**
- ⏱️ Max 5 trigger payouts per driver per 7-day window before manual review kicks in
- 🔗 High referral overlap + high co-location frequency = elevated collusion risk score

### ⚖️ The UX Balance
Flagged ≠ Rejected. A driver whose phone dropped signal in a storm goes into a **24-hour human review queue** — not a denial. We catch syndicates. We don't punish bad weather.

```
✅ Legitimate driver, signal dropped in storm     → 24h review → PAID
❌ Single GPS spoofer                             → Sensor fusion → BLOCKED
❌ Coordinated ring, 200 simultaneous triggers    → Graph analysis → CLUSTER HELD
❌ Fog alert in Chennai in June                   → Historical baseline → QUARANTINED
```

---

## 🏗️ Architecture

![WhatsApp Image 2026-03-19 at 22 38 39](https://github.com/user-attachments/assets/02667f7c-5450-42c8-8a0d-efc497739c61)

**⚙️ Stack**

```
📱 Mobile          Flutter (iOS + Android · unified codebase)
🖥️  Backend         Python FastAPI · microservices · BackgroundTasks async processing
🤖 AI / ML         PyTorch · scikit-learn · served as internal FastAPI modules
🕸️  Fraud graph     6-layer sensor fusion · graph-based collusion detection
🗄️  Databases       InfluxDB (time-series sensor data) · PostgreSQL (transactions + audit ledger)
💳 Payments        Razorpay · weekly premium collection + bulk UPI payouts
🪪 KYC             manual verification with an Aadhar photograph
📒 Audit ledger    Cryptographic hash-chain table in PostgreSQL · append-only · tamper-evident
☁️  Infrastructure  Render / Vercel (FastAPI backend) 
```

---

<div align="center">

**🛡️ KavachNidhi** — A bad week of weather shouldn't mean a bad week of life.

*reach.keshavks@gmail.com*

</div>
