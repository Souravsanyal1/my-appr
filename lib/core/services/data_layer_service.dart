import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'device_identity_service.dart';
import 'gamification_service.dart';
import 'language_service.dart';
import 'storage_service.dart';

/// Single unified data layer service for FocusDeen.
/// Routes writes and reads to either Firebase Realtime Database or Cloud Firestore
/// based on access characteristics (live ephemeral vs queryable permanent).
class DataLayerService extends GetxService {
  static DataLayerService get to => Get.find<DataLayerService>();

  FirebaseFirestore? get _firestore {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('[DataLayer] Firestore instance notice: $e');
    }
    return null;
  }

  FirebaseDatabase? get _rtdb {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseDatabase.instance;
    } catch (e) {
      debugPrint('[DataLayer] RTDB instance notice: $e');
    }
    return null;
  }

  // Device ID provider
  String get _deviceId {
    if (Get.isRegistered<DeviceIdentityService>()) {
      return DeviceIdentityService.to.deviceId;
    }
    return 'unknown_device';
  }

  // ═══════════════════════════════════════════════════════════════
  // REALTIME DATABASE OBSERVABLES & STREAMS
  // ═══════════════════════════════════════════════════════════════

  // Live Stats
  final RxInt totalUsersCount = 0.obs;
  final RxInt onlineNowCount = 0.obs;
  final RxInt activeTodayCount = 0.obs;
  final RxInt deedsCompletedTodayCount = 0.obs;

  // Live Unlock State
  final RxBool isTemporarilyUnlocked = false.obs;
  final RxInt unlockExpiresAtMs = 0.obs;
  final RxString unlockedByPackage = ''.obs;

  // Subscriptions
  StreamSubscription? _connectedSub;
  StreamSubscription? _liveStatsSub;
  StreamSubscription? _unlockStateSub;
  StreamSubscription? _scheduledJobsSub;

  @override
  void onInit() {
    super.onInit();
    _initRtdb();
  }

  @override
  void onClose() {
    _connectedSub?.cancel();
    _liveStatsSub?.cancel();
    _unlockStateSub?.cancel();
    _scheduledJobsSub?.cancel();
    super.onClose();
  }

  // ═══════════════════════════════════════════════════════════════
  // 1. REALTIME DATABASE: PRESENCE & ON-DISCONNECT
  // ═══════════════════════════════════════════════════════════════

  void _initRtdb() {
    final rtdb = _rtdb;
    if (rtdb == null) return;

    if (!kIsWeb) {
      try {
        rtdb.setPersistenceEnabled(true);
      } catch (_) {}
    }

    _setupPresence(rtdb);
    _listenToLiveStats(rtdb);
    _listenToUnlockState(rtdb);
    _listenToScheduledJobs(rtdb);
  }

  void _setupPresence(FirebaseDatabase rtdb) {
    final deviceId = _deviceId;
    if (deviceId.isEmpty || deviceId == 'unknown_device') return;

    final connectedRef = rtdb.ref('.info/connected');
    final myPresenceRef = rtdb.ref('presence/$deviceId');
    final onlineCounterRef = rtdb.ref('liveStats/onlineNow');

    _connectedSub = connectedRef.onValue.listen((event) {
      final connected = event.snapshot.value == true;
      if (connected) {
        // Setup onDisconnect handler
        myPresenceRef.onDisconnect().set({
          'online': false,
          'lastSeen': ServerValue.timestamp,
        }).then((_) {
          // Decrement online counter on disconnect
          onlineCounterRef.onDisconnect().set(ServerValue.increment(-1));
        });

        // Set online status
        myPresenceRef.set({
          'online': true,
          'lastSeen': ServerValue.timestamp,
        });

        // Increment online counter atomically
        onlineCounterRef.set(ServerValue.increment(1));

        // Mark active today in RTDB
        _markActiveToday(rtdb);
      }
    });
  }

  void _markActiveToday(FirebaseDatabase rtdb) {
    final todayKey = DateTime.now().toIso8601String().substring(0, 10);
    final storage = Get.isRegistered<StorageService>() ? Get.find<StorageService>() : null;
    final lastMarkedDay = storage?.read<String>('last_active_day_marked') ?? '';

    if (lastMarkedDay != todayKey) {
      rtdb.ref('liveStats/activeToday').set(ServerValue.increment(1));
      storage?.write('last_active_day_marked', todayKey);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 2. REALTIME DATABASE: LIVE STATS & ATOMIC TRANSACTIONS
  // ═══════════════════════════════════════════════════════════════

  void _listenToLiveStats(FirebaseDatabase rtdb) {
    _liveStatsSub = rtdb.ref('liveStats').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data is Map) {
        totalUsersCount.value = (data['totalUsers'] as num?)?.toInt() ?? 0;
        onlineNowCount.value = (data['onlineNow'] as num?)?.toInt() ?? 0;
        activeTodayCount.value = (data['activeToday'] as num?)?.toInt() ?? 0;
        deedsCompletedTodayCount.value =
            (data['deedsCompletedToday'] as num?)?.toInt() ?? 0;
      }
    });
  }

  /// Increment deeds completed today via atomic server increment
  Future<void> incrementDeedsCompletedToday() async {
    final rtdb = _rtdb;
    if (rtdb == null) return;
    try {
      await rtdb
          .ref('liveStats/deedsCompletedToday')
          .set(ServerValue.increment(1));
    } catch (e) {
      debugPrint('[DataLayer] incrementDeedsCompletedToday notice: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 3. REALTIME DATABASE: UNLOCK STATE (LIVE COUNTDOWN)
  // ═══════════════════════════════════════════════════════════════

  void _listenToUnlockState(FirebaseDatabase rtdb) {
    final deviceId = _deviceId;
    if (deviceId.isEmpty) return;

    _unlockStateSub = rtdb.ref('unlockState/$deviceId').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data is Map) {
        final isUnlocked = data['isUnlocked'] == true;
        final expiresAt = (data['unlockedUntil'] as num?)?.toInt() ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;

        if (isUnlocked && expiresAt > now) {
          isTemporarilyUnlocked.value = true;
          unlockExpiresAtMs.value = expiresAt;
          unlockedByPackage.value = data['unlockedBy']?.toString() ?? '';
        } else {
          isTemporarilyUnlocked.value = false;
          unlockExpiresAtMs.value = 0;
          unlockedByPackage.value = '';
        }
      } else {
        isTemporarilyUnlocked.value = false;
        unlockExpiresAtMs.value = 0;
        unlockedByPackage.value = '';
      }
    });
  }

  /// Set live unlock countdown in RTDB
  Future<void> setUnlockState({
    required bool isUnlocked,
    required int unlockedUntil,
    required String unlockedBy,
    int score = 100,
  }) async {
    final rtdb = _rtdb;
    if (rtdb == null) return;
    final deviceId = _deviceId;
    if (deviceId.isEmpty) return;

    try {
      await rtdb.ref('unlockState/$deviceId').set({
        'isUnlocked': isUnlocked,
        'unlockedUntil': unlockedUntil,
        'unlockedBy': unlockedBy,
        'score': score,
        'updatedAt': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('[DataLayer] setUnlockState error: $e');
    }
  }

  /// Clear unlock state
  Future<void> clearUnlockState() async {
    final rtdb = _rtdb;
    if (rtdb == null) return;
    final deviceId = _deviceId;
    if (deviceId.isEmpty) return;

    try {
      await rtdb.ref('unlockState/$deviceId').set({
        'isUnlocked': false,
        'unlockedUntil': 0,
        'unlockedBy': '',
        'updatedAt': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('[DataLayer] clearUnlockState error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 4. REALTIME DATABASE: SCHEDULED JOBS LISTENER
  // ═══════════════════════════════════════════════════════════════

  void _listenToScheduledJobs(FirebaseDatabase rtdb) {
    final deviceId = _deviceId;
    if (deviceId.isEmpty) return;

    _scheduledJobsSub = rtdb
        .ref('scheduledJobs')
        .orderByChild('targetDeviceId')
        .equalTo(deviceId)
        .onValue
        .listen((event) {
      final data = event.snapshot.value;
      if (data is Map) {
        debugPrint('[DataLayer] Pending scheduled jobs for device: ${data.length}');
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // 5. FIRESTORE: USER PROFILE (users/{deviceId})
  // ═══════════════════════════════════════════════════════════════

  /// Sync full profile document to Firestore users/{deviceId}
  Future<void> syncUserProfile({
    String? fcmToken,
    List<String>? lockedApps,
  }) async {
    final firestore = _firestore;
    if (firestore == null) return;
    final deviceId = _deviceId;
    if (deviceId.isEmpty || deviceId == 'unknown_device') return;

    try {
      final lang = Get.isRegistered<LanguageService>()
          ? LanguageService.to.currentLanguage.value
          : 'bn';

      final gamification = Get.isRegistered<GamificationService>()
          ? GamificationService.to
          : null;

      final storage = Get.isRegistered<StorageService>()
          ? Get.find<StorageService>()
          : null;

      String appVersion = '1.0.0';
      try {
        final info = await PackageInfo.fromPlatform();
        appVersion = '${info.version}+${info.buildNumber}';
      } catch (_) {}

      final String platform = Platform.isAndroid ? 'android' : 'ios';
      final effectiveLockedApps =
          lockedApps ?? storage?.getMonitoredPackages() ?? [];

      final Map<String, dynamic> data = {
        'deviceId': deviceId,
        'platform': platform,
        'language': lang,
        'appVersion': appVersion,
        'lastActiveAt': FieldValue.serverTimestamp(),
        'notificationsEnabled': fcmToken != null && fcmToken.isNotEmpty,
        if (fcmToken != null && fcmToken.isNotEmpty) 'fcmToken': fcmToken,
        'streak': gamification?.currentStreak.value ?? 0,
        'totalDeeds': gamification?.deedHistory.length ?? 0,
        'totalXp': gamification?.currentXp.value ?? 0,
        'lockedApps': effectiveLockedApps,
      };

      final docRef = firestore.collection('users').doc(deviceId);
      final docSnap = await docRef.get();

      if (!docSnap.exists) {
        data['createdAt'] = FieldValue.serverTimestamp();
        data['country'] = Platform.localeName.split('_').last;
        await docRef.set(data);
      } else {
        await docRef.update(data);
      }
      debugPrint('[DataLayer] Firestore user synced: $deviceId');
    } catch (e) {
      debugPrint('[DataLayer] syncUserProfile notice: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 6. FIRESTORE: DEED HISTORY (deedHistory/{deviceId}/items/{id})
  // ═══════════════════════════════════════════════════════════════

  /// Record completed deed log permanently in Firestore
  Future<void> recordCompletedDeed({
    required String deedId,
    required String deedTitle,
    required String category,
    required int score,
    required int durationSeconds,
  }) async {
    final firestore = _firestore;
    final deviceId = _deviceId;
    if (firestore == null || deviceId.isEmpty) return;

    try {
      await firestore
          .collection('deedHistory')
          .doc(deviceId)
          .collection('items')
          .add({
        'deedId': deedId,
        'deedTitle': deedTitle,
        'category': category,
        'score': score,
        'durationSeconds': durationSeconds,
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Also increment RTDB counter atomically
      await incrementDeedsCompletedToday();
    } catch (e) {
      debugPrint('[DataLayer] recordCompletedDeed notice: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 7. FIRESTORE: NOTIFICATIONS STREAM
  // ═══════════════════════════════════════════════════════════════

  Stream<QuerySnapshot<Map<String, dynamic>>> getNotificationsStream({
    int limitCount = 30,
  }) {
    final firestore = _firestore;
    if (firestore == null) return const Stream.empty();

    return firestore
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(limitCount)
        .snapshots();
  }
}
