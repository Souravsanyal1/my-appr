import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'gamification_service.dart';
import 'language_service.dart';
import 'storage_service.dart';

const String _kDeviceIdKey = 'anonymous_device_id';
const String _kLastSyncKey = 'device_last_firestore_sync_ms';

class DeviceIdentityService extends GetxService {
  static DeviceIdentityService get to => Get.find<DeviceIdentityService>();

  late final StorageService _storage;

  String _deviceId = '';
  String get deviceId => _deviceId;

  Future<DeviceIdentityService> init() async {
    _storage = Get.find<StorageService>();
    _deviceId = _getOrCreateDeviceId();
    await _ensureAnonymousAuth();
    return this;
  }

  // ─── Device ID ────────────────────────────────────────────────────────────

  String _getOrCreateDeviceId() {
    final existing = _storage.read<String>(_kDeviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final newId = const Uuid().v4();
    _storage.write(_kDeviceIdKey, newId);
    return newId;
  }

  // ─── Silent Anonymous Auth (invisible to user) ────────────────────────────

  Future<void> _ensureAnonymousAuth() async {
    try {
      if (Firebase.apps.isEmpty) return;
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
        debugPrint('[DeviceIdentity] Firebase anonymous sign-in OK.');
      }
    } catch (e) {
      debugPrint('[DeviceIdentity] Anonymous auth notice: $e');
    }
  }

  // ─── Firestore User Document Upsert ───────────────────────────────────────

  /// Call this on every app open. Throttled to at most once per 60 minutes.
  Future<void> syncUserDocument({String? fcmToken}) async {
    try {
      if (Firebase.apps.isEmpty) return;

      // Throttle: only sync once per hour to save reads/writes on free tier
      final lastSyncMs = _storage.read<int>(_kLastSyncKey) ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final oneHourMs = 60 * 60 * 1000;
      final isFirstSync = lastSyncMs == 0;

      if (!isFirstSync && (nowMs - lastSyncMs) < oneHourMs) {
        debugPrint('[DeviceIdentity] Sync throttled — skipping.');
        return;
      }

      final firestore = FirebaseFirestore.instance;
      final lang = Get.isRegistered<LanguageService>()
          ? LanguageService.to.currentLanguage.value
          : 'bn';

      final gamification = Get.isRegistered<GamificationService>()
          ? GamificationService.to
          : null;

      String appVersion = '1.0.0';
      try {
        final info = await PackageInfo.fromPlatform();
        appVersion = '${info.version}+${info.buildNumber}';
      } catch (_) {}

      final String platform = Platform.isAndroid ? 'android' : 'ios';

      String? token = fcmToken;
      if (token == null || token.isEmpty) {
        token = _storage.read<String>('fcm_token');
      }
      if (token == null || token.isEmpty) {
        try {
          token = await FirebaseMessaging.instance.getToken();
          if (token != null) _storage.write('fcm_token', token);
        } catch (_) {}
      }

      final Map<String, dynamic> data = {
        'deviceId': _deviceId,
        'platform': platform,
        'language': lang,
        'appVersion': appVersion,
        'lastActiveAt': FieldValue.serverTimestamp(),
        'notificationsEnabled': true,
        if (token != null && token.isNotEmpty) 'fcmToken': token,
        // App stats
        'streak': gamification?.currentStreak.value ?? 0,
        'totalDeeds': gamification?.deedHistory.length ?? 0,
        'totalXp': gamification?.currentXp.value ?? 0,
      };

      final docRef = firestore.collection('users').doc(_deviceId);

      if (isFirstSync) {
        // First time: also set createdAt and country
        data['createdAt'] = FieldValue.serverTimestamp();
        data['country'] = Platform.localeName.split('_').last;
        await docRef.set(data, SetOptions(merge: true));
      } else {
        await docRef.update(data);
      }

      _storage.write(_kLastSyncKey, nowMs);
      debugPrint('[DeviceIdentity] Firestore sync OK for device: $_deviceId');
    } catch (e) {
      debugPrint('[DeviceIdentity] Firestore sync notice: $e');
    }
  }

  /// Lightweight FCM token refresh — called by NotificationService when token rotates.
  Future<void> updateFcmToken(String token) async {
    try {
      _storage.write('fcm_token', token);
      if (Firebase.apps.isEmpty || _deviceId.isEmpty) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_deviceId)
          .set({
            'deviceId': _deviceId,
            'fcmToken': token,
            'notificationsEnabled': true,
            'lastActiveAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      debugPrint('[DeviceIdentity] FCM token updated in Firestore');
    } catch (e) {
      debugPrint('[DeviceIdentity] updateFcmToken notice: $e');
    }
  }
}
