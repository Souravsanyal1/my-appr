# DeenFlow App Store & Google Play Compliance Guide

This document provides ready-to-submit compliance declarations for the Google Play Store (Accessibility Service) and Apple App Store (FamilyControls entitlement).

---

## 1. Google Play Accessibility Service Declaration

### Purpose of Accessibility Usage
> "DeenFlow uses Android's AccessibilityService API solely for digital wellbeing: to detect when the user launches their own selected restricted apps (such as TikTok, Instagram, YouTube, or Facebook) and momentarily display an Islamic deed/recitation screen before granting access."

### Form Responses for Google Play Console (App Content > Accessibility API)
- **Is the Accessibility API used for accessibility features?**
  - Select: *No, it is used for an alternative user-facing tool (Digital Wellbeing / App Blocker).*
- **Which events does the service listen to?**
  - Select: `TYPE_WINDOW_STATE_CHANGED` only.
- **Does DeenFlow read the screen content of other apps?**
  - Select: **No**. `canRetrieveWindowContent` is explicitly set to `false`.
- **Does DeenFlow record user keystrokes, passwords, or personal messages?**
  - Select: **No**.
- **Is any data transmitted off-device?**
  - Select: **No**. App monitoring is performed 100% locally and offline on the user's device.
- **YouTube Video Demonstration URL**:
  - Provide a short 30-second screen capture demonstrating: (1) user toggling protection for an app, (2) the in-app prominent disclosure dialog appearing before system settings, (3) enabling accessibility, and (4) opening the protected app which triggers DeenFlow's deed screen.

---

## 2. In-App Prominent Disclosure (Google Play Requirement)

The following dialog is displayed inside DeenFlow **before** redirecting the user to Android Accessibility settings:

```
[Icon: Accessibility]
Accessibility Service Disclosure / অ্যাক্সেসিবিলিটি স্পষ্ট প্রজ্ঞাপন

DeenFlow uses the Accessibility Service API strictly to detect when you launch protected applications (e.g. TikTok, YouTube) and present your Islamic deed screen.

• 🔒 Never reads messages, typed text, passwords, or personal content.
• 📱 All detection operates 100% locally and offline on your device.
• ⚡ You can toggle this permission off anytime from system settings.

[Buttons: "No thanks" / "Agree & Enable"]
```

---

## 3. Privacy Policy — Accessibility & App Usage Section

> ### App Monitoring & Accessibility Notice
> "DeenFlow accesses the foreground application package name using Android's AccessibilityService API exclusively when you designate specific apps for mindful restriction. 
> 
> We do NOT collect, store, or transmit your screen contents, personal messages, keystrokes, credentials, or private app data. Detection of package names occurs completely in device memory and is never shared with third parties or stored on external servers."

---

## 4. Apple FamilyControls Entitlement Request Steps

The Screen Time API requires the `com.apple.developer.family-controls` entitlement, which must be requested from Apple:

1. Log into your [Apple Developer Account](https://developer.apple.com/contact/request/family-controls-distribution/).
2. Fill out the **Family Controls Entitlement Request Form**:
   - **App Name**: DeenFlow
   - **Bundle ID**: `com.focusdeen.app`
   - **Category**: Lifestyle / Productivity / Family
   - **Why does your app require Family Controls?**:
     *"DeenFlow helps individuals and families practice mindful phone usage and cultivate spiritual habits by shielding distracting social media apps until a short Islamic deed or Quranic recitation is completed."*
   - **Which APIs do you plan to use?**:
     - `FamilyControls` (to present the `FamilyActivityPicker` for user-selected app tokens)
     - `ManagedSettings` (to apply shields via `ManagedSettingsStore`)
     - `DeviceActivity` (to handle scheduled unlock windows and re-lock events)
3. Once approved, enable the entitlement in your App ID configuration on developer.apple.com, and download the updated Provisioning Profile containing `com.apple.developer.family-controls`.
