import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:focus_deen/core/services/firebase_auth_service.dart';
import 'package:focus_deen/core/services/storage_service.dart';
import 'package:focus_deen/features/limits/models/app_limit_model.dart';

import 'package:firebase_core/firebase_core.dart';

class FirestoreSyncService extends GetxService {
  FirebaseFirestore? get _firestore {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (e) {
      debugPrint('FirebaseFirestore instance notice: $e');
    }
    return null;
  }

  final FirebaseAuthService _authService = Get.find<FirebaseAuthService>();
  final StorageService _storageService = Get.find<StorageService>();

  final RxBool isSyncing = false.obs;
  final Rx<DateTime?> lastSyncTime = Rx<DateTime?>(null);
  StreamSubscription? _limitsSub;

  @override
  void onInit() {
    super.onInit();
    _authService.currentUser.listen((user) {
      _limitsSub?.cancel();
      if (user != null) {
        _listenToCloudLimits(user.uid);
      }
    });
  }

  @override
  void onClose() {
    _limitsSub?.cancel();
    super.onClose();
  }

  /// Real-time listener for limits updated in Cloud Firestore
  void _listenToCloudLimits(String uid) {
    final firestore = _firestore;
    if (firestore == null) return;

    _limitsSub = firestore
        .collection('users')
        .doc(uid)
        .collection('limits')
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.docs.isNotEmpty) {
              final cloudLimits = snapshot.docs.map((doc) {
                return AppLimitModel.fromMap(doc.data());
              }).toList();

              // Update local cache
              _storageService.saveLimits(cloudLimits);
              lastSyncTime.value = DateTime.now();
            }
          },
          onError: (e) {
            debugPrint('Error listening to cloud limits: $e');
          },
        );
  }

  /// Back up local limits and configuration to Cloud Firestore
  Future<bool> backupToCloud() async {
    final firestore = _firestore;
    if (firestore == null) return false;

    final uid = _authService.uid;
    if (uid.isEmpty) return false;

    isSyncing.value = true;
    try {
      final limits = _storageService.getLimits();
      final monitored = _storageService.getMonitoredPackages();

      final batch = firestore.batch();
      final userRef = firestore.collection('users').doc(uid);

      batch.set(userRef, {
        'email': _authService.email,
        'monitoredPackages': monitored,
        'isStrictMode': _storageService.isStrictModeEnabled(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Sync limits as documents in subcollection
      final limitsCol = userRef.collection('limits');
      for (final limit in limits) {
        final docRef = limitsCol.doc(limit.packageName.replaceAll('.', '_'));
        batch.set(docRef, limit.toMap(), SetOptions(merge: true));
      }

      await batch.commit();
      lastSyncTime.value = DateTime.now();
      return true;
    } catch (e) {
      debugPrint('Error backupToCloud: $e');
      return false;
    } finally {
      isSyncing.value = false;
    }
  }

  /// Save daily screen time & focus score stats to Firestore
  Future<void> saveDailyStats({
    required int totalMinutes,
    required int focusScore,
    required int completedFocusSessions,
  }) async {
    final firestore = _firestore;
    if (firestore == null) return;

    final uid = _authService.uid;
    if (uid.isEmpty) return;

    try {
      final today = DateTime.now()
          .toIso8601String()
          .split('T')
          .first; // YYYY-MM-DD
      await firestore
          .collection('users')
          .doc(uid)
          .collection('daily_stats')
          .doc(today)
          .set({
            'date': today,
            'totalScreenTimeMinutes': totalMinutes,
            'focusScore': focusScore,
            'completedFocusSessions': completedFocusSessions,
            'timestamp': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving daily stats: $e');
    }
  }

  /// Save tasbih lifetime count to Firestore
  Future<void> saveTasbihStats(int totalCount) async {
    final firestore = _firestore;
    if (firestore == null) return;

    final uid = _authService.uid;
    if (uid.isEmpty) return;

    try {
      await firestore.collection('users').doc(uid).set({
        'lifetimeTasbihCount': totalCount,
        'lastTasbihUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving tasbih stats: $e');
    }
  }

  /// Restore cloud backup into local storage
  Future<bool> restoreFromCloud() async {
    final firestore = _firestore;
    if (firestore == null) return false;

    final uid = _authService.uid;
    if (uid.isEmpty) return false;

    isSyncing.value = true;
    try {
      final userDoc = await firestore.collection('users').doc(uid).get();
      if (!userDoc.exists || userDoc.data() == null) return false;

      final data = userDoc.data()!;
      if (data['monitoredPackages'] is List) {
        final List<String> pkgs = (data['monitoredPackages'] as List)
            .map((e) => e.toString())
            .toList();
        _storageService.saveMonitoredPackages(pkgs);
      }

      // Fetch limits subcollection
      final limitsSnap = await firestore
          .collection('users')
          .doc(uid)
          .collection('limits')
          .get();

      if (limitsSnap.docs.isNotEmpty) {
        final restoredLimits = limitsSnap.docs
            .map((d) => AppLimitModel.fromMap(d.data()))
            .toList();
        _storageService.saveLimits(restoredLimits);
      }

      lastSyncTime.value = DateTime.now();
      return true;
    } catch (e) {
      debugPrint('Error restoreFromCloud: $e');
      return false;
    } finally {
      isSyncing.value = false;
    }
  }
}
