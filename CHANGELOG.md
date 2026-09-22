# DeenFlow Comprehensive Audit & Remediation Changelog

All changes made during the multi-phase audit and remediation of **DeenFlow** (Islamic Digital Wellbeing & Social Media Blocker).

---

## [1.0.0+1] - 2026-09-21

### Summary of Accomplishments
- **Static Analysis**: Resolved all 38 issues on `flutter analyze`. Verified `No issues found! (ran in 4.9s)`.
- **Automated Tests**: 20/20 unit, localization, and cross-device responsive widget tests passing.
- **20-Screen Portfolio**: Completed all 20 specified UI screens with responsive layout wrapping, authentic Arabic typography, and Bengali localization.
- **Cross-Device Robustness**: Created `ResponsiveLayout` with `ResponsiveContext` and `ResponsiveScaffoldBody`. Tested without overflow across 320dp phones up to 840dp+ tablets and 200% system text scale.
- **Speech & Unlock Resilience**: Hardened speech recognition lifecycle with state machines, `mounted` guards, background auto-teardown (`WidgetsBindingObserver`), dynamic threshold from storage, and persistent timestamp calculations that survive backgrounding and process termination.
- **Platform Manifests**: Configured Android app name to `DeenFlow`, updated iOS `Info.plist` with `DeenFlow` display name and mandatory microphone (`NSMicrophoneUsageDescription`) & speech recognition (`NSSpeechRecognitionUsageDescription`) descriptions.

---

### File-by-File Details

#### 1. Core & Responsive Architecture
- `lib/core/responsive/responsive_layout.dart` (NEW)
  - Added `ScreenType` enum (`compact`, `medium`, `expanded`).
  - Added `ResponsiveContext` extension on `BuildContext` for dynamic breakpoints (`screenWidth`, `isTablet`, `responsiveSize()`).
  - Added `ResponsiveScaffoldBody` with `maxContentWidth: 560` (or custom), automatic `SafeArea`, padding tokens, and scroll handling that protects `ScrollView` children from illegal `IntrinsicHeight` nesting.
- `lib/core/constants/app_spacing.dart` (NEW)
  - Defined standard 4dp/8dp grid tokens: `xs: 4`, `s: 8`, `m: 16`, `l: 24`, `xl: 32`, `xxl: 48`.
  - Defined minimum touch target: `minTouchTarget: 48.0` (WCAG AAA compliant).
- `lib/core/widgets/glowing_action_button.dart`
  - Replaced deprecated `.withOpacity()` with `.withValues(alpha: ...)`.
  - Removed unreachable switch `default:` clause on exhaustive `GlowingButtonState` enum.
- `lib/core/widgets/progress_ring.dart`
  - Replaced deprecated `.withOpacity()` with `.withValues(alpha: ...)`.
  - Modernized null-aware element collections.
- `lib/core/routes/app_routes.dart` & `lib/core/routes/app_pages.dart`
  - Registered new routes:
    - `/intention-complete` (`Routes.intentionComplete`) -> `IntentionCompleteView` (Screen 7)
    - `/retry-result` (`Routes.retryResult`) -> `RetryResultView` (Screen 13)
    - `/end-screen` (`Routes.endScreen`) -> `EndScreenView` (Screen 20)

#### 2. New Screen Views Added (Completing the 20-Screen Portfolio)
- `lib/features/intention/views/intention_complete_view.dart` (NEW - Screen 7)
  - Completed Intention confirmation screen with glowing emerald badge, selected deed summary, and smooth navigation to recitation.
- `lib/features/unlock/views/retry_result_view.dart` (NEW - Screen 13)
  - Dedicated screen for scores below passing threshold (< 80%).
  - Provides constructive Tajweed feedback, detailed score breakdown, and "Try Again" / "Review Deed" actions.
- `lib/features/onboarding/views/end_screen.dart` (NEW - Screen 20)
  - Final onboarding completion screen with glowing flame/leaf icon, motivational tagline, and direct entry point to dashboard.

#### 3. Unlock Flow & Recitation Hardening
- `lib/features/unlock/views/active_unlock_view.dart` (Screen 14)
  - Replaced naive countdown decrementing with persistent timestamp difference calculation: `(expiresAt - DateTime.now().millisecondsSinceEpoch) / 1000`.
  - Added `WidgetsBindingObserver` to re-sync countdown instantly when the app is resumed from background.
  - Replaced deprecated `.withOpacity()` with `.withValues(alpha: ...)`.
  - Wrapped content in `ResponsiveScaffoldBody`.
- `lib/features/unlock/views/recording_view.dart` (Screen 10)
  - Added `WidgetsBindingObserver` to safely cancel recording and reset state if the user switches apps or receives an incoming phone call.
  - Added bilingual title, transliteration, Bengali pronunciation, and Arabic rendering.
  - Wrapped in `ResponsiveScaffoldBody`.
- `lib/features/unlock/views/analysis_view.dart` (Screen 11)
  - Added `mounted` guards before state updates or navigation.
  - Connected passing threshold dynamically to `StorageService` (`unlock_threshold`, default 80%).
  - Automatically routes to `/retry-result` when score < threshold, or `/result` when score >= threshold.
- `lib/features/unlock/views/result_view.dart` (Screen 12)
  - Wrapped in `ResponsiveScaffoldBody`.
  - Added bilingual Bengali & English score badges and unlock tier explanations.
- `lib/features/unlock/views/unlock_success_view.dart` (Screen 15)
  - Wrapped in `ResponsiveScaffoldBody`.
  - Replaced `.withOpacity()` with `.withValues(alpha: ...)`.
- `lib/features/unlock/views/unlock_screen.dart`
  - Replaced deprecated `.withOpacity()` with `.withValues(alpha: ...)`.

#### 4. Learning, Settings, Dashboard, and Onboarding
- `lib/features/settings/views/settings_screen.dart` (Screen 18)
  - Replaced deprecated `activeColor` with `activeThumbColor` across all switches.
  - Replaced deprecated `.withOpacity()` with `.withValues(alpha: ...)`.
  - Wrapped in `ResponsiveScaffoldBody(scrollable: false)`.
- `lib/features/statistics/views/statistics_screen.dart` (Screen 17)
  - Replaced `.withOpacity()` with `.withValues(alpha: ...)`.
  - Fixed multiple underscore warnings (`__` -> `_`).
- `lib/features/learning/views/deed_detail_view.dart`, `deeds_library_view.dart`, `learning_catalog_screen.dart`, `learning_mode_view.dart`, `lesson_detail_screen.dart`
  - Replaced all `.withOpacity()` calls with `.withValues(alpha: ...)`.
- `lib/features/dashboard/views/dashboard_screen.dart` & `home_screen.dart`
  - Replaced deprecated `.withOpacity()` with `.withValues(alpha: ...)`.
- `lib/features/onboarding/views/splash_screen.dart`, `welcome_screen.dart`, `choose_apps_screen.dart`
  - Replaced deprecated `.withOpacity()` with `.withValues(alpha: ...)`.
  - Fixed multiple underscore warnings.

#### 5. Platform Manifests & Privacy Declarations
- `android/app/src/main/AndroidManifest.xml`
  - Updated application label to `DeenFlow`.
- `ios/Runner/Info.plist`
  - Updated `CFBundleDisplayName` to `DeenFlow`.
  - Updated `CFBundleName` to `deenflow`.
  - Added `NSMicrophoneUsageDescription` explaining microphone access for recitation coaching.
  - Added `NSSpeechRecognitionUsageDescription` explaining speech recognition for recitation evaluation.

#### 6. Authentic Tilawat Audio Playback & Native Media Streaming
- `android/app/src/main/AndroidManifest.xml`
  - Added `INTERNET`, `ACCESS_NETWORK_STATE`, and `MODIFY_AUDIO_SETTINGS` permissions.
  - Added `android.intent.action.TTS_SERVICE` query intent for Android 11+ visibility.
- `android/app/src/main/kotlin/com/focusdeen/focus_deen/channels/FocusDeenMethodChannel.kt`
  - Added native `android.media.MediaPlayer` integration with `AudioAttributes.USAGE_MEDIA` and `AudioAttributes.CONTENT_TYPE_SPEECH`.
  - Added `playAudio` and `stopAudio` channel methods.
  - Added volume boost (`1.0f`) on `AudioManager.STREAM_MUSIC` and smart `fallbackPhonetic` synthesis when Arabic voice packs are missing on real OEM devices.
- `lib/core/constants/channel_constants.dart` & `lib/core/services/native_bridge_service.dart`
  - Added `playAudio` and `stopAudio` bridge calls and asynchronous playback event listeners.
- `lib/features/learning/models/learning_lesson_model.dart` & `lib/features/learning/repositories/learning_repository.dart`
  - Added `audioUrl` field with authentic EveryAyah and Islamic Network CDN MP3 recitation URLs (Mishary Rashid Alafasy) for Daily Dhikr, Takbir, and Short Surahs.
- `lib/features/learning/views/learning_mode_view.dart` & `lib/features/learning/views/lesson_detail_screen.dart`
  - Wired audio buttons to play genuine recitation audio with dynamic state tracking and synchronized play/stop actions.

#### 7. App Icons & Search in "What should we protect?"
- `lib/core/widgets/app_icon_widget.dart` (NEW)
  - Created reusable `AppIconWidget` to render high-resolution on-device icons via `Image.memory` with smooth rounded corners.
  - Added branded visual fallbacks for TikTok, Instagram, Facebook, YouTube, Snapchat, Reddit, WhatsApp, Twitter/X, Telegram, Discord, and system apps.
- `android/app/src/main/AndroidManifest.xml`
  - Added `android.permission.QUERY_ALL_PACKAGES` permission for Android 11+ package visibility.
- `lib/features/onboarding/views/choose_apps_screen.dart`
  - Replaced single-letter placeholder with `AppIconWidget`.
  - Added real-time search bar for installed apps and full Bengali localization.
- `lib/features/app_selection/controllers/app_selection_controller.dart`
  - Curated installed app sorting to prioritize popular distracting social apps at the top.
- `lib/features/dashboard/views/home_screen.dart`
  - Upgraded dashboard protected app pills with real brand icons.

#### 8. Verification & Automated Tests
- `test/widget_test.dart`
  - Expanded test suite from 16 to 20 automated tests:
    - Screen breakpoint classification (compact, medium, expanded).
    - Compact screen rendering at 320x568 (iPhone SE) without overflow.
    - Tablet constraint test verifying 700dp max content width.
    - Accessibility test verifying 200% system font scaling without `RenderFlex` exceptions.

---

## [1.1.0] - 2026-09-21

### Full "App Lock / Timed Unlock / Auto Re-lock" System & Real Data Elimination

#### 1. Real Dynamic Data Integration (Eliminated All Fake Data)
- **HomeScreen (`home_screen.dart`)**:
  - Replaced hardcoded progress ring ratio (`0.33`) and deeds text (`2 / 6`) with real dynamic calculation based on completed and total deeds recorded in `StorageService`.
  - Replaced hardcoded app pills (`TikTok`, `Instagram`, `Facebook`, `YouTube`) with the user's actual selected protected packages list from `storage.getMonitoredPackages()`, including an interactive "Edit" / "Add" chip leading to App Selection.
  - Dynamically bound the "Next Deed" access duration to the user's configured unlock duration (`storage.getDefaultUnlockDurationMinutes()`).
- **ProgressView (`progress_view.dart`)**:
  - Replaced hardcoded `7 DAY STREAK` with live streak computation (`storage.getStreakDays()`).
  - Replaced static Monday-Sunday checkmarks with live ISO weekly active day tracking (`storage.getWeeklyActiveDays()`).
  - Replaced static `42` Total Deeds and `37` Completed with live totals (`storage.getTotalDeedsCount()`, `storage.getCompletedDeedsCount()`).
  - Replaced hardcoded `87%` Average Score with rolling calculation of recorded pronunciation test scores (`storage.getAverageScore()`).
  - Replaced hardcoded `11h 20m` Unlocked Time with accumulated unlock minutes formatted cleanly in hours and minutes (`storage.getUnlockedMinutesTotal()`).
- **ProfileView (`profile_view.dart`)**:
  - Replaced hardcoded `30m` Daily Goal, `3 Apps` Protected, and `7 Days` Streak with dynamic data from `StorageService`.
  - Replaced hardcoded `80%` score threshold text with live setting from `storage.getMinimumPassingScore()`.
- **StorageService (`storage_service.dart`)**:
  - Added real persistence for `total_deeds_count`, `completed_deeds_count`, `unlocked_minutes_total`, `pronunciation_scores` (sliding window of last 50 scores), `streak_days`, `last_active_date_str`, `weekly_active_days`, and `recordDeedAttempt()`.

#### 2. Flutter AppBlocker Abstraction Layer (`lib/core/blocker/`)
- `app_blocker.dart`: Pure abstract interface defining `getInstalledApps()`, `setProtectedApps()`, `unlock()`, `lockNow()`, `getUnlockedUntil()`, `checkPermissions()`, `openPermissionSettings()`, and `events` stream.
- `blocker_models.dart`: Added `InstalledAppInfo`, `BlockerPermission` enum, `PermissionStatusSet`, `BlockerEvent`, and typed exceptions (`BlockerException`, `PermissionMissingException`, `ServiceNotRunningException`, `UnsupportedPlatformException`).
- `android_app_blocker.dart`: MethodChannel (`com.focusdeen.app/methods`) and EventChannel (`com.focusdeen.app/events`) implementation with typed exception handling.
- `ios_app_blocker.dart`: Screen Time & FamilyControls contract with graceful degradation on unapproved environments.
- `unsupported_app_blocker.dart`: Safe fallback for desktop and web.
- `blocker_service.dart`: GetX service managing singleton injection based on current platform.

#### 3. Android Native Kotlin Layer
- `RelockScheduler.kt`: Exact alarm scheduling via `AlarmManager.setExactAndAllowWhileIdle` with Android 12+ (`API 31+`) `canScheduleExactAlarms()` compliance and pending intent flags.
- `RelockReceiver.kt`: Exact broadcast receiver triggered when an unlock window elapses. Verifies if the expired package is currently in the foreground, immediately kicks to home via `GLOBAL_ACTION_HOME`, emits a lock notification, and brings DeenFlow to the front with `route=/blocked`.
- `BootReceiver.kt`: Captures `BOOT_COMPLETED` and `MY_PACKAGE_REPLACED` to query active unlock sessions from persistent storage and reschedule alarms.
- `AppMonitorService.kt`: Added clock-tamper protection checking `SystemClock.elapsedRealtime()` alongside wall-clock timestamps.
- `FocusDeenMethodChannel.kt`: Implemented `launchApp` to seamlessly open the target protected app upon recitation completion.
- `MainActivity.kt`: Updated `handleRouteIntent` to support both `blocked_pkg` and `packageName` intent extras.
- `AndroidManifest.xml`: Declared `RECEIVE_BOOT_COMPLETED` and `SCHEDULE_EXACT_ALARM` permissions; registered `RelockReceiver` and `BootReceiver`.

#### 4. Permission Onboarding UI (`permission_setup_screen.dart`)
- Added dedicated `PermissionSetupScreen` between App Selection and Daily Goal.
- Live status indicators re-checked on `AppLifecycleState.resumed` for Accessibility Service, Display Over Other Apps, Notifications, and Battery Optimization.
- Prominent Google Play disclosure dialog before requesting Accessibility Service with clear "Agree & Enable" and "No thanks" options.
- Device-specific guidance card for Xiaomi (MIUI/HyperOS), Samsung (OneUI), and Oppo (ColorOS) autostart settings.

#### 5. iOS Swift Layer
- `Runner.entitlements`: Added `com.apple.developer.family-controls` entitlement and `group.com.focusdeen.app` App Group.
- `DeenFlowBlockerPlugin.swift`: Integrated `FamilyControls` and `ManagedSettings` authorization and temporary shield clearing.
- `AppDelegate.swift`: Registered `DeenFlowBlockerPlugin`.

#### 6. Expanded Automated Tests
- Added `FakeAppBlocker` unit tests validating protected app synchronization, timed unlocks, and `BlockerEvent` broadcast emissions. Total automated tests increased from 20 to 24 (100% passing).

