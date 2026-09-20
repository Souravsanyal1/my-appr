import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:focus_deen/core/services/native_bridge_service.dart';
import 'package:focus_deen/core/services/storage_service.dart';

class UsageController extends GetxController {
  final NativeBridgeService _nativeBridge = Get.find<NativeBridgeService>();
  final StorageService _storageService = Get.find<StorageService>();

  final RxMap<String, int> appUsageMillis = <String, int>{}.obs;
  final RxString currentForegroundPackage = ''.obs;
  final RxInt totalTodayMinutes = 0.obs;
  final RxInt focusScore = 85.obs; // 0-100 scale
  final RxBool isLoading = false.obs;

  StreamSubscription? _foregroundSub;
  StreamSubscription? _blockedSub;
  StreamSubscription? _warningSub;

  @override
  void onInit() {
    super.onInit();
    _initListeners();
    refreshUsage();
  }

  @override
  void onClose() {
    _foregroundSub?.cancel();
    _blockedSub?.cancel();
    _warningSub?.cancel();
    super.onClose();
  }

  void _initListeners() {
    _foregroundSub = _nativeBridge.foregroundAppStream.listen((pkg) {
      currentForegroundPackage.value = pkg;
    });

    _blockedSub = _nativeBridge.appBlockedStream.listen((event) {
      final pkg = event['packageName'] as String? ?? '';
      final appName = event['appName'] as String? ?? 'App';
      final used = (event['usedMinutes'] as num?)?.toInt() ?? 0;
      final limit = (event['limitMinutes'] as num?)?.toInt() ?? 0;

      Get.toNamed('/blocked', arguments: {
        'packageName': pkg,
        'appName': appName,
        'usedMinutes': used,
        'limitMinutes': limit,
      });
    });

    _warningSub = _nativeBridge.limitWarningStream.listen((event) {
      final appName = event['appName'] as String? ?? 'App';
      final minutesLeft = event['minutesLeft'] as num? ?? 5;

      Get.snackbar(
        'Time Warning',
        '$appName has $minutesLeft minutes remaining before limit.',
        backgroundColor: Colors.amber.shade800,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.timer_outlined, color: Colors.white),
      );
    });
  }

  Future<void> refreshUsage() async {
    isLoading.value = true;
    try {
      final monitored = _storageService.getMonitoredPackages();
      final usage = await _nativeBridge.getAppUsage(packages: monitored);
      appUsageMillis.assignAll(usage);

      int total = 0;
      for (final val in usage.values) {
        total += (val / (1000 * 60)).round();
      }
      totalTodayMinutes.value = total;

      // Calculate focus score based on limits adherence
      final limits = _storageService.getLimits();
      int exceededCount = 0;
      for (final limit in limits) {
        final usedMins = ((usage[limit.packageName] ?? 0) / (1000 * 60)).round();
        if (usedMins > limit.dailyLimitMinutes) {
          exceededCount++;
        }
      }

      final score = ((100 - (exceededCount * 25) - (total > 180 ? 20 : 0)).clamp(20, 100)).toInt();
      focusScore.value = score;
    } catch (e) {
      debugPrint('Error refreshing usage: $e');
    } finally {
      isLoading.value = false;
    }
  }

  int getUsageForPackage(String packageName) {
    final millis = appUsageMillis[packageName] ?? 0;
    return (millis / (1000 * 60)).round();
  }
}
