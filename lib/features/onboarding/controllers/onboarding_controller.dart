import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:focus_deen/core/services/native_bridge_service.dart';
import 'package:focus_deen/core/services/storage_service.dart';

class OnboardingController extends GetxController with WidgetsBindingObserver {
  final NativeBridgeService _nativeBridge = Get.find<NativeBridgeService>();
  final StorageService _storageService = Get.find<StorageService>();

  final RxInt currentStep = 0.obs;

  // Permission statuses
  final RxBool hasUsagePermission = false.obs;
  final RxBool hasAccessibilityPermission = false.obs;
  final RxBool hasOverlayPermission = false.obs;
  final RxBool hasNotificationPermission = false.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    checkAllPermissions();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkAllPermissions();
    }
  }

  Future<void> checkAllPermissions() async {
    final perms = await _nativeBridge.checkPermissions();
    hasUsagePermission.value = perms['usageStats'] ?? false;
    hasAccessibilityPermission.value = perms['accessibility'] ?? false;
    hasOverlayPermission.value = perms['overlay'] ?? false;
    hasNotificationPermission.value = perms['notifications'] ?? false;
  }

  Future<void> requestPermission(String type) async {
    await _nativeBridge.requestPermission(type);
  }

  Future<void> openAppSettings() async {
    await _nativeBridge.openAppSettings();
  }

  void nextStep() {
    if (currentStep.value < 1) {
      currentStep.value++;
    } else {
      finishOnboarding();
    }
  }

  void finishOnboarding() {
    _storageService.setOnboardingComplete(true);
    Get.offAllNamed('/dashboard');
  }
}
