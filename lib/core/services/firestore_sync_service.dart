import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:focus_deen/core/services/firebase_auth_service.dart';
import 'package:focus_deen/core/services/storage_service.dart';
import 'package:focus_deen/features/limits/models/app_limit_model.dart';

class FirestoreSyncService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuthService _authService = Get.find<FirebaseAuthService>();
  final StorageService _storageService = Get.find<StorageService>();

  final RxBool isSyncing = false.obs;
  final Rx<DateTime?> lastSyncTime = Rx<DateTime?>(null);

  /// Back up local limits and configuration to Cloud Firestore
  Future<bool> backupToCloud() async {
    final uid = _authService.uid;
    if (uid.isEmpty) return false;

    isSyncing.value = true;
    try {
      final limits = _storageService.getLimits().map((l) => l.toMap()).toList();
      final monitored = _storageService.getMonitoredPackages();

      await _firestore.collection('users').doc(uid).set({
        'limits': limits,
        'monitoredPackages': monitored,
        'isStrictMode': _storageService.isStrictModeEnabled(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      lastSyncTime.value = DateTime.now();
      return true;
    } catch (e) {
      debugPrint('Error backupToCloud: $e');
      return false;
    } finally {
      isSyncing.value = false;
    }
  }

  /// Restore cloud backup into local storage
  Future<bool> restoreFromCloud() async {
    final uid = _authService.uid;
    if (uid.isEmpty) return false;

    isSyncing.value = true;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) return false;

      final data = doc.data()!;
      if (data['limits'] is List) {
        final List<AppLimitModel> restoredLimits = (data['limits'] as List)
            .map((e) => AppLimitModel.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
        _storageService.saveLimits(restoredLimits);
      }

      if (data['monitoredPackages'] is List) {
        final List<String> pkgs = (data['monitoredPackages'] as List)
            .map((e) => e.toString())
            .toList();
        _storageService.saveMonitoredPackages(pkgs);
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
