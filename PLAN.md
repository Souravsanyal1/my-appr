# DeenFlow Implementation & Traceability Plan (PLAN.md)

This document establishes the component-by-component traceability table and migration plan for the **App Lock / Timed Unlock / Auto Re-lock** system.

---

## 1. Component Traceability Table

| Component | Status | Evidence (file:line) | What I will do | Risk |
|---|:---:|---|---|---|
| **AppBlocker Interface** | `[CREATE]` | `lib/core/blocker/app_blocker.dart` (new) | Define clean abstract class with `getInstalledApps`, `setProtectedApps`, `unlock`, `lockNow`, `getUnlockedUntil`, `checkPermissions`, `events`. | Low (clean Dart abstraction). |
| **AndroidAppBlocker** | `[CREATE]` | `lib/core/blocker/android_app_blocker.dart` (new) | Bridge to MethodChannel `"com.focusdeen.focus_deen/channel"` and EventChannel `"com.focusdeen.focus_deen/events"` with typed errors. | Low (adapts existing native channels). |
| **IosAppBlocker** | `[CREATE]` | `lib/core/blocker/ios_app_blocker.dart` (new) | Implement iOS FamilyControls/ManagedSettings contract with graceful non-simulated fallback. | Low (clear hardware boundary). |
| **UnsupportedAppBlocker** | `[CREATE]` | `lib/core/blocker/unsupported_app_blocker.dart` (new) | Provide safe no-op implementation for web and desktop environments. | None. |
| **Epoch-Based Time Source** | `[UPGRADE]` | `lib/features/unlock/views/active_unlock_view.dart:61` | Replace any running countdown counters with epoch millis comparison (`unlockedUntil - now`), resyncing on `AppLifecycleState.resumed`. | Low (ensures tamper-proof time). |
| **Direct Deed Intent Routing** | `[UPGRADE]` | `android/.../MainActivity.kt:44` & `lib/main.dart:60` | When a blocked app is intercepted, receive `blocked_pkg` and route directly to the deed recitation flow instead of generic blocked screen. | Low (streamlines UX). |
| **BlockerAccessibilityService** | `[UPGRADE]` | `android/.../FocusAccessibilityService.kt:10` | Advance `FocusAccessibilityService` with debounce (~1.5s), ignore system UI/launcher/keyboard, fallback chain with home action. | Low (improves responsiveness). |
| **BlockerStore (Native)** | `[UPGRADE]` | `android/.../AppMonitorService.kt:25` | Persist protected packages, `unlockedUntil` timestamp, and `elapsedRealtime` (to catch manual clock tampering) in `SharedPreferences`. | Low (rock-solid persistence). |
| **RelockScheduler & Receiver** | `[CREATE]` | `android/.../receivers/RelockReceiver.kt` (new) | Implement exact alarm (`setExactAndAllowWhileIdle`) to trigger automatic re-lock the second the unlock period expires, even inside the app. | Medium (OEM alarm restrictions handled gracefully). |
| **BootReceiver** | `[CREATE]` | `android/.../receivers/BootReceiver.kt` (new) | Re-arm relock alarms and restart monitoring service upon device reboot (`BOOT_COMPLETED`). | Low (standard Android pattern). |
| **BlockerForegroundService** | `[CREATE]` | `android/.../services/BlockerForegroundService.kt` (new) | Lightweight persistent notification showing remaining unlock time and keeping service priority high. | Low (Android 14 compliant). |
| **Permission Setup & Disclosure** | `[CREATE]` | `lib/features/onboarding/views/permission_setup_screen.dart` (new) | Add permission onboarding step with Google Play compliant prominent disclosure before sending user to accessibility settings. | Low (Google Play requirement). |
| **Real Progress & Statistics Store** | `[FIX]` | `lib/features/statistics/views/progress_view.dart:39` | **Replace all hardcoded fake data (7 day streak, 42 deeds, 11h 20m) with real live records from `DailyStatsModel` and `StorageService`**. | Low (solves user request directly). |
| **Real Profile Summary Stats** | `[FIX]` | `lib/features/settings/views/profile_view.dart:92` | Replace static 30m / 3 apps / 7 days with live monitored apps count, real configured daily goal, and real streak. | Low (eliminates mock data). |
| **Configurable Min Score & Duration** | `[UPGRADE]` | `lib/features/settings/views/settings_screen.dart:1` | Ensure settings drive unlock duration (15/30/45/60 min) and minimum score (default 80%), persisted and read dynamically. | Low (improves customization). |
| **Emergency Unlock** | `[CREATE]` | `lib/features/unlock/views/emergency_unlock_dialog.dart` (new) | Safe 2-minute emergency unlock pass with daily usage limit so user is never trapped in an urgent situation. | Low (UX safety net). |

---

## 2. Data Safety & Migration Plan

Existing user data is stored in `GetStorage` under key names:
- `monitored_packages` (`List<String>`)
- `app_limits` (`List<Map>`)
- `security_pin_hash` (`String`)
- `selected_language` (`String`)
- `unlock_sessions` (`List<Map>`)

### Migration Strategy:
1. **Preserve Existing Keys**: No existing storage keys will be renamed or deleted.
2. **New Keys with Sane Defaults**:
   - `unlock_duration_minutes`: integer, defaults to `30`.
   - `minimum_score_threshold`: integer, defaults to `80`.
   - `daily_stats_history`: list of maps, initialized from current date if empty.
   - `streak_count`: integer, computed dynamically from active days.
3. **Backward Compatibility**: If an existing user has saved `monitored_packages`, they are automatically synced to the native `BlockerStore` on first launch.
