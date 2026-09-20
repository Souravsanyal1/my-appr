import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:focus_deen/core/services/native_bridge_service.dart';
import 'package:focus_deen/core/services/pin_security_service.dart';
import 'package:focus_deen/core/services/storage_service.dart';
import 'package:focus_deen/features/limits/models/app_limit_model.dart';
import 'package:focus_deen/features/security/views/pin_dialog.dart';

class LimitController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();
  final NativeBridgeService _nativeBridge = Get.find<NativeBridgeService>();
  final PinSecurityService _pinService = Get.find<PinSecurityService>();

  final RxList<AppLimitModel> limits = <AppLimitModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadLimits();
  }

  void loadLimits() {
    isLoading.value = true;
    final saved = _storageService.getLimits();
    if (saved.isEmpty) {
      // Default presets as requested in prompt:
      // Instagram: 30m, 5m warning, block
      // TikTok: 20m, 5m warning, block
      // Facebook: 45m, 10m warning, warning mode
      final presets = [
        const AppLimitModel(
          packageName: 'com.instagram.android',
          appName: 'Instagram',
          dailyLimitMinutes: 30,
          warningThresholdMinutes: 5,
          mode: 'block',
        ),
        const AppLimitModel(
          packageName: 'com.zhiliaoapp.musically',
          appName: 'TikTok',
          dailyLimitMinutes: 20,
          warningThresholdMinutes: 5,
          mode: 'block',
        ),
        const AppLimitModel(
          packageName: 'com.facebook.katana',
          appName: 'Facebook',
          dailyLimitMinutes: 45,
          warningThresholdMinutes: 10,
          mode: 'warning',
        ),
      ];
      limits.assignAll(presets);
      _storageService.saveLimits(presets);
      _nativeBridge.syncLimits(presets);
    } else {
      limits.assignAll(saved);
      _nativeBridge.syncLimits(saved);
    }
    isLoading.value = false;
  }

  Future<bool> checkSecurity() async {
    if (_pinService.isStrictModeActive()) {
      final verified = await PinDialog.show(
        title: 'Strict Mode Check',
        subtitle: 'Enter PIN to modify app limits',
      );
      return verified;
    }
    return true;
  }

  Future<void> addOrUpdateLimit(AppLimitModel limit) async {
    final allowed = await checkSecurity();
    if (!allowed) return;

    final index = limits.indexWhere((l) => l.packageName == limit.packageName);
    if (index >= 0) {
      limits[index] = limit;
    } else {
      limits.add(limit);
    }

    _storageService.saveLimits(limits.toList());
    await _nativeBridge.syncLimits(limits.toList());

    Get.snackbar(
      'Limit Updated',
      'Limit for ${limit.appName} set to ${limit.dailyLimitMinutes} minutes.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  Future<void> toggleLimit(String packageName, bool isEnabled) async {
    final allowed = await checkSecurity();
    if (!allowed) return;

    final index = limits.indexWhere((l) => l.packageName == packageName);
    if (index >= 0) {
      final updated = limits[index].copyWith(isEnabled: isEnabled);
      limits[index] = updated;
      _storageService.saveLimits(limits.toList());
      await _nativeBridge.syncLimits(limits.toList());
    }
  }

  Future<void> removeLimit(String packageName) async {
    final allowed = await checkSecurity();
    if (!allowed) return;

    limits.removeWhere((l) => l.packageName == packageName);
    _storageService.saveLimits(limits.toList());
    await _nativeBridge.syncLimits(limits.toList());
  }

  AppLimitModel? getLimitForPackage(String packageName) {
    try {
      return limits.firstWhere((l) => l.packageName == packageName);
    } catch (_) {
      return null;
    }
  }
}
