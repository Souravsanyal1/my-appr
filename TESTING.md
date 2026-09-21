# DeenFlow Verification & Testing Checklist

This document details the automated test coverage, manual QA test scripts, verification matrix, and OEM-specific test procedures for DeenFlow's App Lock, Timed Unlock, and Auto Re-lock system.

---

## 1. Automated Test Suite (Flutter)

Run tests via terminal:
```bash
flutter test
```

### Coverage Breakdown (24/24 Passing)
| Test Category | Description | Status |
|---------------|-------------|--------|
| **AppLimitModel Tests** | Serialization, deserialization, and `copyWith` mutations | PASSED |
| **UnlockSessionModel Tests** | Exact expiration timestamp calculation and `isExpired` checks | PASSED |
| **FocusSessionModel Tests** | Islamic Pomodoro focus session serialization and state | PASSED |
| **DhikrModel Tests** | Tasbih count, target limits, and Dhikr serialization | PASSED |
| **Learning Repository Tests** | Verified Islamic deeds, Arabic texts, references, and lesson models | PASSED |
| **Pronunciation Analyzer Tests**| Audio duration evaluation, passing vs failing scoring thresholds | PASSED |
| **ScheduleModel Tests** | Daytime and overnight restriction schedule matching | PASSED |
| **DailyStats & Achievement Tests**| Streak calculation, achievements unlocking logic, and daily stats | PASSED |
| **Bengali Localization Tests** | Authentic Bengali pronunciation, titles, translations, and category mappings | PASSED |
| **Responsive Layout Tests** | Screen breakpoints, 320dp phones, 700dp tablet constraints, 200% font scaling | PASSED |
| **WelcomeScreen Widget Tests** | Render check on compact 360x640 and ultra-compact 320x568 screens without overflow | PASSED |
| **AppBlocker Abstraction Tests**| `FakeAppBlocker` sets protected apps, unlocks, gets active unlock map, locks now | PASSED |
| **BlockerEvent Stream Tests** | Validates broadcast stream emissions for `unlocked` and `relocked` events | PASSED |

---

## 2. Kotlin Native Verification (Android)

Native tests and logic verification for `AppMonitorService`, `RelockScheduler`, and `RelockReceiver`:
- **Clock Tamper Protection**: `isTemporarilyUnlocked(packageName)` checks both wall-clock (`System.currentTimeMillis()`) and elapsed realtime (`SystemClock.elapsedRealtime()`). If the user rolls the system clock back, the unlock session is invalidated immediately.
- **Exact Relock Alarms**: `RelockScheduler.scheduleRelock` uses `AlarmManager.setExactAndAllowWhileIdle` (with API 31+ `canScheduleExactAlarms` compatibility) to trigger `RelockReceiver` even in Doze mode.
- **Reboot Rescheduling**: `BootReceiver` captures `ACTION_BOOT_COMPLETED` and `ACTION_MY_PACKAGE_REPLACED`, reading unexpired sessions from `SharedPreferences` and rescheduling exact alarms.

---

## 3. Manual Testing Checklist (Physical Android Device)

### Test Case 1: Open Protected App While Locked
1. Open DeenFlow, select **TikTok** (or Instagram) as protected in App Selection.
2. Ensure DeenFlow's Accessibility Service is enabled.
3. Switch to phone home launcher, tap **TikTok**.
4. **Expected**: TikTok immediately closes (`GLOBAL_ACTION_HOME`), and DeenFlow comes to the front showing the Islamic Deed screen (e.g., "Astaghfirullah 3 times").

### Test Case 2: Deed Recitation & Passing Score Unlock
1. On Deed screen, tap **Start** -> **Listen Pronunciation** -> **Record Recitation**.
2. Recite for at least 3-4 seconds clearly.
3. View Analysis screen: Score should be $\ge 80\%$.
4. Tap **Open App** on the Success screen.
5. **Expected**: The protected app launches without getting blocked, and the unlock timer begins.

### Test Case 3: Automatic Relock Inside the App
1. Unlock an app for 15 minutes (or test with 1 minute debug duration).
2. Remain inside the protected app until the timer elapses.
3. **Expected**: When the alarm fires, `RelockReceiver` detects the expired package is in the foreground, closes it immediately via `GLOBAL_ACTION_HOME`, sends a lock notification, and brings DeenFlow back to the deed screen.

### Test Case 4: Device Reboot State Restoration
1. Unlock an app for 30 minutes.
2. Restart the phone immediately.
3. Upon booting up, verify that `BootReceiver` reschedules the relock alarm.
4. Try opening the protected app before the 30 minutes expire: App should still be accessible.
5. Wait until the 30 minutes expire: App should lock automatically.

### Test Case 5: Revoked Accessibility Warning
1. With DeenFlow open on the Home screen, open Android Settings and turn OFF DeenFlow Accessibility Service.
2. Return to DeenFlow.
3. **Expected**: A prominent warning banner appears on the Home screen: "Enable App Lock Service / লক কাজ করতে পারমিশন দিন" with a one-tap button to open Accessibility settings.

### Test Case 6: Real Statistics Verification (No Fake Data)
1. Complete 1 recitation with an 85% score.
2. Navigate to **Progress** tab.
   - Total Deeds should reflect live count (1).
   - Completed Deeds should reflect (1).
   - Average Score should show `85%`.
   - Unlocked Time should show `30m` (or duration earned).
   - Today's circle should be checked with a green tick.
3. Navigate to **Profile** tab.
   - Shows live daily goal, live count of protected apps, and current streak.

---

## 4. OEM-Specific Test Matrix

| OEM Device | Setting to Check | Expected Behavior |
|------------|------------------|-------------------|
| **Xiaomi / Redmi / POCO (MIUI/HyperOS)** | Settings > Apps > Permissions > Autostart = ON; Battery Saver = "No restrictions". | Prevents MIUI from killing `FocusAccessibilityService` when screen turns off. |
| **Samsung (OneUI)** | Settings > Apps > DeenFlow > Battery > "Unrestricted". | AlarmManager wakes device from deep sleep without delay. |
| **Oppo / Realme (ColorOS)** | App info > Battery usage > Allow background activity & Allow auto-launch. | Timed unlock alarm triggers on time. |
| **Vivo / iQOO (FuntouchOS)** | Settings > Battery > High background power consumption > DeenFlow = ON. | Continuous foreground app detection. |
