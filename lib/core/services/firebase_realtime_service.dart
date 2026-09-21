import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:focus_deen/core/services/firebase_auth_service.dart';
import 'package:focus_deen/features/unlock/models/unlock_session_model.dart';

class FirebaseRealtimeService extends GetxService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuthService _authService = Get.find<FirebaseAuthService>();

  StreamSubscription? _unlockSub;
  final RxList<UnlockSessionModel> remoteActiveUnlocks =
      <UnlockSessionModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    try {
      _database.setPersistenceEnabled(true);
    } catch (e) {
      debugPrint(
        'Realtime Database persistence already enabled or not supported: $e',
      );
    }
    _listenToAuthChanges();
  }

  @override
  void onClose() {
    _unlockSub?.cancel();
    super.onClose();
  }

  void _listenToAuthChanges() {
    _authService.currentUser.listen((user) {
      _unlockSub?.cancel();
      if (user != null) {
        _listenToActiveUnlocks(user.uid);
        updateUserPresence(isOnline: true);
      } else {
        remoteActiveUnlocks.clear();
      }
    });
  }

  /// Broadcast live active unlock pass to Realtime Database
  Future<void> syncUnlockSession(UnlockSessionModel session) async {
    final uid = _authService.uid;
    if (uid.isEmpty) return;

    try {
      final ref = _database.ref(
        'active_unlocks/$uid/${session.packageName.replaceAll('.', '_')}',
      );
      await ref.set({
        'packageName': session.packageName,
        'appName': session.appName,
        'durationMinutes': session.durationMinutes,
        'expiresAtTimestamp': session.expiresAtTimestamp,
        'updatedAt': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('Error syncing unlock to Realtime Database: $e');
    }
  }

  /// Remove expired or revoked unlock session from Realtime Database
  Future<void> removeUnlockSession(String packageName) async {
    final uid = _authService.uid;
    if (uid.isEmpty) return;

    try {
      final ref = _database.ref(
        'active_unlocks/$uid/${packageName.replaceAll('.', '_')}',
      );
      await ref.remove();
    } catch (e) {
      debugPrint('Error removing unlock from Realtime Database: $e');
    }
  }

  /// Listen for real-time unlock changes (e.g. synced across multiple devices)
  void _listenToActiveUnlocks(String uid) {
    final ref = _database.ref('active_unlocks/$uid');
    _unlockSub = ref.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data is Map) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final list = <UnlockSessionModel>[];

        data.forEach((key, val) {
          if (val is Map) {
            final session = UnlockSessionModel(
              packageName: val['packageName']?.toString() ?? '',
              appName: val['appName']?.toString() ?? '',
              durationMinutes: (val['durationMinutes'] as num?)?.toInt() ?? 5,
              expiresAtTimestamp:
                  (val['expiresAtTimestamp'] as num?)?.toInt() ?? 0,
            );
            if (session.expiresAtTimestamp > now) {
              list.add(session);
            }
          }
        });
        remoteActiveUnlocks.assignAll(list);
      } else {
        remoteActiveUnlocks.clear();
      }
    });
  }

  /// Real-time live status: whether in Focus Session or idle
  Future<void> updateFocusSessionStatus({
    required bool inFocusSession,
    int? remainingSeconds,
  }) async {
    final uid = _authService.uid;
    if (uid.isEmpty) return;

    try {
      final ref = _database.ref('live_status/$uid');
      await ref.update({
        'inFocusSession': inFocusSession,
        'focusSessionRemainingSeconds': remainingSeconds ?? 0,
        'lastUpdated': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('Error updating focus status in Realtime Database: $e');
    }
  }

  /// Real-time presence management
  Future<void> updateUserPresence({required bool isOnline}) async {
    final uid = _authService.uid;
    if (uid.isEmpty) return;

    try {
      final statusRef = _database.ref('live_status/$uid');
      if (isOnline) {
        await statusRef.update({
          'isOnline': true,
          'lastSeen': ServerValue.timestamp,
        });
        // Auto disconnect handler
        statusRef.onDisconnect().update({
          'isOnline': false,
          'lastSeen': ServerValue.timestamp,
          'inFocusSession': false,
        });
      } else {
        await statusRef.update({
          'isOnline': false,
          'lastSeen': ServerValue.timestamp,
        });
      }
    } catch (e) {
      debugPrint('Error updating presence: $e');
    }
  }

  /// Push a live blocked event alert
  Future<void> broadcastBlockedEvent({
    required String packageName,
    required String appName,
    required int usedMinutes,
    required int limitMinutes,
  }) async {
    final uid = _authService.uid;
    if (uid.isEmpty) return;

    try {
      final ref = _database.ref('realtime_events/$uid/latest_block');
      await ref.set({
        'type': 'app_blocked',
        'packageName': packageName,
        'appName': appName,
        'usedMinutes': usedMinutes,
        'limitMinutes': limitMinutes,
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('Error broadcasting blocked event: $e');
    }
  }

  /// Push live tasbih count to Realtime Database
  Future<void> syncTasbihLive(int count) async {
    final uid = _authService.uid;
    if (uid.isEmpty) return;

    try {
      final ref = _database.ref('live_status/$uid');
      await ref.update({
        'liveTasbihCount': count,
        'lastTasbihTimestamp': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('Error updating tasbih in Realtime Database: $e');
    }
  }
}
