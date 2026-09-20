# FocusDeen (my-appr)

[![FocusDeen CI/CD Pipeline](https://github.com/Souravsanyal1/my-appr/actions/workflows/ci_cd.yml/badge.svg)](https://github.com/Souravsanyal1/my-appr/actions/workflows/ci_cd.yml)

> **Mindful Screen Time for the Believer**  
> An Islamic mindfulness and digital focus application built with Flutter (GetX), Android Kotlin Native Services, and Firebase.

---

## 📌 Overview

FocusDeen helps users overcome mindless screen addiction and protect their spiritual focus through intentional app usage limits, mindful Quranic reflection unlock mechanisms, and strict boundary enforcement.

---

## 🌟 Core Features

### Phase 1: Flutter Architecture & UI
- **GetX Architecture**: Clean separation with controllers, services, models, and bindings.
- **Islamic Mindful Luxury Aesthetic**: Dark teal/emerald surfaces (`#091413`, `#112320`) paired with metallic gold accents (`#D4AF37`) and typography powered by Google Fonts Outfit.
- **Onboarding Flow**: Multi-step onboarding explaining the spiritual philosophy with interactive system permissions checklist.
- **Dashboard UI**: Daily Focus Score dial, screen time aggregation, active limits overview, and active temporary unlock timers.
- **App Selection Screen**: Search, filter, and multi-select installed apps with high-performance Base64 icon rendering.
- **Local Storage**: Persistent configuration for limits, selected packages, unlock sessions, and security PIN using `GetStorage`.

### Phase 2: Android Native Monitoring Layer
- **UsageStatsService (`UsageStatsManager`)**: Reads foreground usage time per app accurately from midnight today.
- **FocusAccessibilityService (`AccessibilityService`)**: Real-time foreground app change detection via `TYPE_WINDOW_STATE_CHANGED`.
- **NotificationService**: Android notifications channel (`focus_deen_warnings`) alerting users when approaching their daily limit (e.g. 5 minutes remaining).
- **Communication Channels**:
  - `FocusDeenMethodChannel` (`com.focusdeen.app/methods`): Methods for installed apps, usage metrics, permission queries/intents, limit syncing, and closing apps.
  - `FocusDeenEventChannel` (`com.focusdeen.app/events`): Real-time event streams for foreground transitions, warnings, and block triggers.

### Phase 3: Limits, Warning, Blocking, Temporary Unlock & Security
- **Per-App Custom Limits**: Preset configs for Instagram (30m daily, 5m warning, Block mode), TikTok (20m daily, 5m warning, Block mode), Facebook (45m daily, 10m warning, Warning mode).
- **Branded Blocked Screen**:
  - `TIME'S UP` FocusDeen custom screen.
  - Usage tracker (`X / Y minutes`).
  - Islamic reflection reminder.
  - Actions: `[ Learn to Unlock ]`, `[ Start Focus Session ]`, `[ Close App ]`.
- **Temporary Unlock Engine**:
  - Tiered unlock durations (70–79% → 5 min, 80–89% → 10 min, 90%+ → 15 min).
  - Controlled unlock session tracking with persistent expiration timestamp that recovers across app restarts.
  - Ready for Phase 5 Quranic pronunciation scoring integration.
- **Strict Mode & PIN Security**:
  - 4-digit PIN protection.
  - Salted SHA-256 hash storage (no raw PIN).
  - Lockout protection against brute-force attempts.
  - Protects limit updates, security settings, and app unlock bypass.

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (v3.19.0 or higher)
- Android SDK (API level 23+)
- Java 17

### Installation
```bash
# Clone the repository
git clone https://github.com/Souravsanyal1/my-appr.git
cd my-appr

# Install Flutter dependencies
flutter pub get

# Run on connected Android device
flutter run
```

---

## ⚙️ CI/CD Pipeline (GitHub Actions)

The project includes an automated Continuous Integration & Continuous Delivery workflow located in [`.github/workflows/ci_cd.yml`](.github/workflows/ci_cd.yml):

* **Code Quality**: Runs `flutter analyze` across all Dart/Flutter files.
* **Automated Tests**: Runs `flutter test --coverage` and saves coverage reports.
* **Android Build**: Compiles `flutter build apk --release` and uploads the artifact for direct testing.
* **Web Build**: Compiles `flutter build web --release` and stores web bundle artifacts.
* **Trigger Events**: Runs automatically on every push to `main`, on Pull Requests, and manually via `workflow_dispatch`.

