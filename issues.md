# DeenFlow Debug & Live Runtime Test Report (`issues.md`)

**Test Date & Time**: September 21, 2026, 20:56 Local  
**Test Target**: Physical Android Device (Infinix X678B, Android 14 API 34 via Wireless ADB)  
**App Version**: 1.0.0 (Debug Build)  
**Package Name**: `com.focusdeen.focus_deen`  

---

## Summary of Findings

| ID | Component | Severity | Issue Description | Status |
|---|---|---|---|---|
| **ISSUE-01** | Android Gradle Build | High | `flutter_local_notifications` requires Core Library Desugaring | **Resolved & Verified** in `build.gradle.kts` |
| **ISSUE-02** | Home Screen UI | Medium | RenderFlex Right Overflow (15px) on Locked Apps Card | **Resolved & Verified** in `home_screen.dart` |
| **ISSUE-03** | Firestore Security Rules | High | `PERMISSION_DENIED` on `users/{uid}/limits` & `users/{uid}/stats` | **Resolved & Deployed** in `firestore.rules` |
| **ISSUE-04** | Device Identity Service | Medium | `updateFcmToken` failed with permission-denied due to partial map | **Resolved & Verified** in `device_identity_service.dart` |
| **ISSUE-05** | App Startup / Main | Low | `[core/duplicate-app]` notice when initializing Firebase | **Resolved & Verified** in `lib/main.dart` |

---

## Detailed Issue Analysis & Remediation

### ISSUE-01: Core Library Desugaring Build Failure
- **Error**:
  ```
  Dependency ':flutter_local_notifications' requires core library desugaring to be enabled for :app.
  ```
- **Root Cause**: `flutter_local_notifications` v22+ uses modern Java 8+ / Java Time APIs on older Android runtimes, requiring Gradle desugaring.
- **Fix Applied**:
  In `android/app/build.gradle.kts`:
  - Set `isCoreLibraryDesugaringEnabled = true` under `compileOptions`.
  - Added dependency `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")`.

---

### ISSUE-02: RenderFlex Overflow (15px) on Locked Apps Card
- **Error**: `A RenderFlex overflowed by 15 pixels on the right` (visible yellow/black caution stripes in Bengali UI).
- **Location**: `lib/features/dashboard/views/home_screen.dart` (lines 774–846).
- **Root Cause**: The left `Column` containing "লক করা অ্যাপসমূহ 2" and subtitle "সুরক্ষিত সকল অ্যাপ লক করা আছে" was placed inside a `Row` alongside `OutlinedButton.icon(label: 'অ্যাপ বাছুন')` without `Expanded`. On typical 360–380dp screen widths with Bengali text, the combined width exceeds the viewport.
- **Fix**: Wrap the left `Column` with `Expanded` and add `overflow: TextOverflow.ellipsis` to the subtitle text.

---

### ISSUE-03: Firestore Permission Denied on Subcollections
- **Error Logs**:
  ```
  Error listening to cloud limits: [cloud_firestore/permission-denied] PERMISSION_DENIED: Missing or insufficient permissions.
  Error saving daily stats: [cloud_firestore/permission-denied] PERMISSION_DENIED: Missing or insufficient permissions.
  ```
- **Location**: `firestore.rules`, `lib/core/services/firestore_sync_service.dart`.
- **Root Cause**: `firestore.rules` matched `users/{deviceId}` but Firestore security rules do not automatically cascade to subcollections. Subcollections `limits`, `stats`, and `history` were denied by the catch-all `match /{document=**} { allow read, write: if false; }`.
- **Fix**: In `firestore.rules`, add:
  ```javascript
  match /users/{userId}/{allChildren=**} {
    allow read, write: if isAuthenticated();
  }
  ```

---

### ISSUE-04: FCM Token Rotation Permission Denied
- **Error Log**:
  ```
  [DeviceIdentity] updateFcmToken notice: [cloud_firestore/permission-denied] PERMISSION_DENIED
  ```
- **Location**: `lib/core/services/device_identity_service.dart:125`.
- **Root Cause**: `firestore.rules` checked `request.resource.data.deviceId == deviceId` during updates. When `updateFcmToken` called `update({'fcmToken': token})`, `deviceId` was omitted from the partial payload.
- **Fix**: Include `deviceId: _deviceId` in `updateFcmToken` payload and use `set(..., SetOptions(merge: true))`.

---

### ISSUE-05: Duplicate Firebase Initialization Notice
- **Error Log**:
  ```
  Firebase initializeApp notice: [core/duplicate-app] A Firebase App named "[DEFAULT]" already exists
  ```
- **Location**: `lib/main.dart`.
- **Root Cause**: Native FlutterFire setup already initialized the default app prior to Dart entry point.
- **Fix**: Guard `Firebase.initializeApp` with `if (Firebase.apps.isEmpty)`.

---

## Live Screenshots & Logs
- Device screenshot captured and verified: [current_test_screen.png](file:///c:/Users/kirit/OneDrive/Desktop/New%20folder%20(11)/current_test_screen.png)
- Anonymous Device ID successfully registered: `70ed18a2-0620-4979-bccb-6b52a34e3750`
- FCM Token generated and reachable: `f_gERxWNSnenHLaseAwQRL:APA91bG...`
