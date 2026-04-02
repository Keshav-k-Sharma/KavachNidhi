# KavachNidhi — Flutter Frontend

> **The Income Shield for India's Gig Workers**  
> Parametric micro-insurance delivered in seconds, not claims.

---

## What This Project Is

KavachNidhi is a mobile-first parametric income protection platform for delivery partners, auto-rickshaw drivers, and daily-wage logistics workers across India. Unlike traditional insurance, there are **no claims** — payouts are triggered automatically by objective data signals (cyclone warnings, dense fog, gridlock) and disbursed via UPI every Sunday at 6 PM.

This repository contains the full **Flutter frontend + FastAPI backend** for KavachNidhi. The UI is designed in **Figma first**, then implemented screen-by-screen in Flutter.

---

## Repo Structure

```
KavachNidhi/                    ← branch: development
├── frontend/                   ← Flutter app (this is what we're building)
├── backend/                    ← Python FastAPI microservices
├── .gitignore
└── README.md
```

> **Active branch:** `development` — all work branches off from here.  
> `main` is reserved for production-ready releases only.

---

## Tech Stack


| Layer             | Tool                                                                     |
| ----------------- | ------------------------------------------------------------------------ |
| UI Design         | Figma (design system + all screens)                                      |
| Frontend          | Flutter (Dart) — iOS & Android unified codebase                          |
| State Management  | Riverpod                                                                 |
| Navigation        | Go Router                                                                |
| API Communication | Dio + Retrofit                                                           |
| Local Storage     | Hive                                                                     |
| Maps / GPS        | Google Maps Flutter Plugin                                               |
| Payments UI       | Razorpay Flutter SDK                                                     |
| Notifications     | Firebase Cloud Messaging                                                 |
| KYC               | Manual Aadhaar photo verification                                        |
| Analytics         | Firebase Analytics                                                       |
| Backend           | Python FastAPI (async microservices)                                     |
| Databases         | InfluxDB (sensor/time-series) + PostgreSQL (transactions + audit ledger) |
| Payments Backend  | Razorpay (UPI payouts + premium collection)                              |
| Infrastructure    | Render / Vercel                                                          |


---

## Flutter Project Structure

```
frontend/
│
├── lib/
│   ├── main.dart
│   ├── app.dart                  # App root, theme, router setup
│   │
│   ├── core/
│   │   ├── theme/                # Color palette, typography, spacing
│   │   ├── router/               # Go Router route definitions
│   │   ├── network/              # Dio client, interceptors, API base
│   │   ├── utils/                # Date helpers, formatters, validators
│   │   └── constants/            # API endpoints, trigger thresholds
│   │
│   ├── features/
│   │   ├── onboarding/           # Splash, language select, intro slides
│   │   ├── auth/                 # Phone OTP login
│   │   ├── kyc/                  # Aadhaar photo upload + manual verification
│   │   ├── home/                 # Main dashboard (shield status, credits)
│   │   ├── earnings/             # 90-day profile, peak windows, platform source
│   │   ├── subscription/         # Plan selection (Basic / Plus / Max)
│   │   ├── triggers/             # CycloneGuard, FogBlock, GridlockGain screens
│   │   ├── wallet/               # Nidhi Wallet, shield credits, history
│   │   ├── payouts/              # Sunday settlement history, UPI details
│   │   ├── notifications/        # In-app notification feed
│   │   └── settings/             # Profile, privacy consent, language, support
│   │
│   └── shared/
│       ├── widgets/              # Reusable UI components (cards, buttons, badges)
│       ├── models/               # Data models (Driver, Trigger, Payout, etc.)
│       └── providers/            # Riverpod global providers
│
├── assets/
│   ├── images/
│   ├── icons/
│   ├── fonts/
│   └── lottie/                   # Animations (payout success, trigger active)
│
└── test/
    ├── unit/
    └── widget/
```

---

## Figma Design Status

All screens are designed in Figma before Flutter implementation.


| Screen              | Figma        | Flutter     |
| ------------------- | ------------ | ----------- |
| Home Dashboard      | ✅ Done       | 🔲 To build |
| Subscriptions       | ✅ Done       | 🔲 To build |
| Earnings Profile    | ✅ Done       | 🔲 To build |
| Wallet & History    | ✅ Done       | 🔲 To build |
| Onboarding / Splash | 🔲 To design | 🔲 To build |
| Phone OTP Auth      | 🔲 To design | 🔲 To build |
| Aadhaar KYC         | 🔲 To design | 🔲 To build |
| CycloneGuard detail | 🔲 To design | 🔲 To build |
| FogBlock detail     | 🔲 To design | 🔲 To build |
| GridlockGain detail | 🔲 To design | 🔲 To build |
| Settings            | 🔲 To design | 🔲 To build |
| Notifications       | 🔲 To design | 🔲 To build |


**Figma file:** *(paste link here)*  
**Brand Colors:**

- Shield Blue: `#1A4FBA` — primary actions, active status
- Nidhi Gold: `#F4A800` — credits, payouts, earnings
- Alert Red: `#E53935` — cyclone warnings, urgent alerts
- Fog Grey: `#90A4AE` — FogBlock indicator, inactive states
- Safe Green: `#2E7D32` — cleared credits, successful payouts
- Background: `#F5F7FA`

---

## App Screens Overview

### Onboarding & Auth

- Splash Screen
- Language Selection (Hindi / English / Tamil / Telugu)
- 3-slide Intro Carousel
- Phone Number Entry + OTP Verification
- Aadhaar KYC via manual photo upload

### Home Dashboard *(Figma done)*

- Active shield status (active / inactive)
- Current week's Shield Credits (pending + cleared)
- Live trigger status cards (CycloneGuard / FogBlock / GridlockGain)
- Sunday settlement countdown + projected amount
- Quick-subscribe CTA if not enrolled

### Subscription Flow *(Figma done)*

- Plan comparison: Kavach Basic ₹50 / Plus ₹70 / Max ₹90
- Plan detail (triggers covered, weekly shield cap)
- UPI AutoPay setup
- Subscription confirmation

### Trigger Status Screens

- **CycloneGuard** — IMD alert banner, city coverage, pre-emptive payout preview
- **FogBlock** — visibility gauge, fog zone indicator, morning shift credit status
- **GridlockGain** — live speed indicator, gridlock timer, per-minute credit counter

### Earnings Profile *(Figma done)*

- 90-day baseline visualization
- Peak earning windows (day-of-week + time-of-day)
- Platform data source (Swiggy / Zomato / Dunzo)
- DPDP consent toggles

### Wallet & History *(Figma done)*

- Nidhi Wallet balance
- Shield Credits ledger (pending → cleared → paid)
- Weekly payout breakdown
- UPI details management

### Settings

- Driver profile (name, city, vehicle type)
- Data privacy & consent toggles (DPDP Act 2023)
- Notification preferences
- Language switcher
- Help & Support / Data deletion request

---

## Task Division

Work is split into two parallel tracks. **Suhas** owns the app foundation: onboarding/auth/KYC, the home dashboard, **trigger detail screens** (live gauges, timers, polling), and the **earnings profile** charts. **Niranjana** owns subscription, wallet, payouts, notifications, and settings — substantial flows with clearer list/form patterns. Both collaborate on Figma consistency and PR reviews.

---

### 👤 Suhas — Foundation, Auth, Home, Triggers & Earnings

**Figma (remaining)**

- Onboarding / Splash screen
- Language selector screen
- Phone OTP auth screens
- Aadhaar KYC screen (photo upload flow)
- CycloneGuard, FogBlock, GridlockGain detail screens (gauges, banners, live counters)
- Component library audit — ensure all existing Figma screens use consistent tokens

**Flutter**


| Area                                             | Scope                                                                                                                                                                                       |
| ------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Project setup                                    | Flutter init inside `frontend/`, configure Riverpod, Go Router, Dio, folder structure                                                                                                       |
| `core/theme/`                                    | Color palette, text styles, spacing constants from Figma tokens                                                                                                                             |
| `core/router/`                                   | All named routes, navigation guards (auth check, KYC check)                                                                                                                                 |
| `core/network/`                                  | Dio base client, auth interceptor, error handling                                                                                                                                           |
| `features/onboarding/`                           | Splash, language selector, 3-slide intro carousel with Lottie                                                                                                                               |
| `features/auth/`                                 | Phone entry, OTP screen, resend timer, auth state provider                                                                                                                                  |
| `features/kyc/`                                  | Aadhaar photo capture/upload, camera permissions, compression, KYC status polling, success/failure states                                                                                   |
| `features/home/`                                 | Main dashboard layout, shield status card, credits summary, live trigger status cards, Sunday countdown, bottom nav bar                                                                     |
| `features/triggers/`                             | Trigger hub, CycloneGuard / FogBlock / GridlockGain detail UIs, visibility gauge, live gridlock timer + per-minute credit counter, IMD-style alert banners, trigger polling + optimistic UI |
| `features/earnings/` *(or nested under `home/`)* | 90-day baseline chart, peak earning heatmaps (day × time), platform source selector, consent toggles wired to state                                                                         |
| `shared/widgets/`                                | KavachCard, ShieldBadge, CreditPill, PrimaryButton, SecondaryButton, LoadingOverlay, ErrorState, chart/skeleton wrappers as needed                                                          |
| `shared/models/`                                 | `Driver`, `Subscription`, `ShieldCredit`, `TriggerEvent` models                                                                                                                             |


**Milestones**

- Week 1: Figma component library audit + onboarding/auth/KYC + trigger detail screens designed
- Week 2: Flutter project scaffolded, theme + router + network layer done
- Week 3: Auth & KYC screens in Flutter (mock data)
- Week 4: Home Dashboard + trigger detail screens in Flutter (mock data)
- Week 5: Earnings profile visualizations + full onboarding → home → trigger flow end-to-end

---

### 👤 Niranjana — Subscription, Wallet, Payouts, Notifications & Settings

**Figma (remaining)**

- Notifications screen
- Settings screen (privacy toggles, language, support)
- User flow diagram: trigger event → shield credit → Sunday payout

**Flutter**


| Area                      | Scope                                                                                                    |
| ------------------------- | -------------------------------------------------------------------------------------------------------- |
| `features/subscription/`  | Plan comparison screen, plan detail, UPI AutoPay setup, confirmation screen, subscription state provider |
| `features/wallet/`        | Wallet balance card, Shield Credits ledger (pending / cleared / paid), empty states                      |
| `features/payouts/`       | Payout history list, weekly settlement detail, UPI account management                                    |
| `features/notifications/` | Notification feed, FCM integration                                                                       |
| `features/settings/`      | Profile edit, DPDP privacy toggles, language switcher, data deletion flow, help & support                |
| `shared/models/`          | `Payout`, `Notification`, `PrivacyConsent` models                                                        |
| `shared/providers/`       | Subscription provider, payout history provider, wallet balance provider, notification inbox provider     |


**Milestones**

- Week 1: Notifications + Settings screens in Figma; align on payout/wallet list patterns with Suhas’s models
- Week 2: Subscription flow in Flutter (mock data)
- Week 3: Wallet + Payouts in Flutter (mock data)
- Week 4: Settings + Notifications in Flutter
- Week 5: Polish, FCM wiring, and cross-flow QA with Suhas’s home/trigger screens

---

## Shared Responsibilities


| Task                                | Owner                            |
| ----------------------------------- | -------------------------------- |
| Weekly Figma consistency check      | Suhas & Niranjana — every Monday |
| Mock data JSON schema               | Agree together before Week 2     |
| API contract alignment with backend | Both together                    |
| PR reviews                          | Each reviews the other's PRs     |
| Widget tests for own screens        | Each person                      |


---

## Getting Started

```bash
# Clone the repo
git clone https://github.com/Keshav-k-Sharma/KavachNidhi.git
cd KavachNidhi
git checkout development

# Flutter setup
cd frontend
flutter pub get
flutter run

# Optional: point at a local backend (default is production https://kavachnidhi.onrender.com)
# flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000

# Run tests
flutter test
```

**Linux (Android builds):** If your default JDK is 25+, Gradle can fail while parsing the Java version. Use JDK 21 for the session, then run the app:

```bash
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export PATH="$JAVA_HOME/bin:$PATH"
flutter run
```

**Flutter:** 3.22+ (Dart 3.4+) · **Min SDK:** Android 6.0 (API 23) / iOS 14

---

## Branching Strategy

```
development               ← integration branch (all PRs merge here)
├── feat/Suhas-onboarding-auth
├── feat/Suhas-home-triggers-earnings
├── feat/Niranjana-subscription
└── feat/Niranjana-wallet-payouts-settings
```

Branch naming: `feat/<firstname>-<feature>` (e.g. `feat/Suhas-kyc`, `feat/Niranjana-wallet`) · One PR per feature · Squash merge into `development`.

---

