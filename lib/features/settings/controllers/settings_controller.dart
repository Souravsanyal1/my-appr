import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/services/language_service.dart';
import '../../../core/services/native_bridge_service.dart';
import '../../../core/services/pin_security_service.dart';
import '../../../core/services/storage_service.dart';
import '../../security/views/pin_dialog.dart';

class SettingsController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();
  final PinSecurityService _pinService = Get.find<PinSecurityService>();
  final NativeBridgeService _nativeBridge = Get.find<NativeBridgeService>();

  final RxBool isStrictMode = false.obs;
  final RxBool requirePinForLimits = false.obs;
  final RxBool notifyBeforeLimit = true.obs;
  final RxBool notifyStreakReminder = true.obs;
  final RxInt unlockThreshold = 80.obs;

  // Permission statuses
  final RxBool hasUsagePermission = false.obs;
  final RxBool hasAccessibility = false.obs;
  final RxBool hasOverlay = false.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadSettings();
      checkPermissions();
    });
  }

  void loadSettings() {
    isStrictMode.value = _pinService.isStrictModeActive();
    requirePinForLimits.value =
        _storageService.read<bool>('require_pin_limits') ?? false;
    notifyBeforeLimit.value =
        _storageService.read<bool>('notify_before_limit') ?? true;
    notifyStreakReminder.value =
        _storageService.read<bool>('notify_streak') ?? true;
    unlockThreshold.value =
        _storageService.read<int>('unlock_threshold_percentage') ?? 80;
  }

  Future<void> checkPermissions() async {
    try {
      hasUsagePermission.value = await _nativeBridge.checkUsageAccess();
      hasAccessibility.value = await _nativeBridge
          .checkAccessibilityPermission();
      hasOverlay.value = await _nativeBridge.checkOverlayPermission();
    } catch (_) {}
  }

  Future<void> toggleStrictMode(bool value) async {
    if (value) {
      if (!_pinService.isPinConfigured()) {
        final created = await PinDialog.show(
          title: 'Setup PIN for Strict Mode',
          subtitle: 'Create a 4-digit security PIN',
          isCreatingPin: true,
        );
        if (!created) return;
      }
      _pinService.setStrictMode(true);
      isStrictMode.value = true;
    } else {
      final verified = await PinDialog.show(
        title: 'Disable Strict Mode',
        subtitle: 'Enter PIN to confirm disabling',
      );
      if (verified) {
        _pinService.setStrictMode(false);
        isStrictMode.value = false;
      }
    }
  }

  void setUnlockThreshold(int threshold) {
    unlockThreshold.value = threshold;
    _storageService.write('unlock_threshold_percentage', threshold);
    // Sync to native SharedPreferences so the overlay reads the updated threshold
    final duration = _storageService.read<int>('unlock_duration_minutes') ?? 30;
    _nativeBridge.syncSettings(minScore: threshold, unlockDurationMinutes: duration);
  }

  void toggleNotifyBeforeLimit(bool val) {
    notifyBeforeLimit.value = val;
    _storageService.write('notify_before_limit', val);
  }

  void toggleNotifyStreak(bool val) {
    notifyStreakReminder.value = val;
    _storageService.write('notify_streak', val);
  }

  Future<void> changePin() async {
    if (_pinService.isPinConfigured()) {
      final verified = await PinDialog.show(
        title: 'Verify Existing PIN',
        subtitle: 'Enter current PIN before changing',
      );
      if (!verified) return;
    }

    await PinDialog.show(
      title: 'Set New PIN',
      subtitle: 'Enter your new 4-digit PIN',
      isCreatingPin: true,
    );
  }

  Future<void> clearAudioRecordings() async {
    int deletedCount = 0;
    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        final entities = tempDir.listSync();
        for (final entity in entities) {
          final p = entity.path.toLowerCase();
          if (p.endsWith('.m4a') || p.endsWith('.aac') || p.endsWith('.wav') || p.contains('recitation')) {
            try {
              entity.deleteSync();
              deletedCount++;
            } catch (_) {}
          }
        }
      }
    } catch (_) {}

    final isBn = LanguageService.to.isBangla;
    Get.snackbar(
      isBn ? 'গোপনীয়তা সংরক্ষিত' : 'Privacy Cleaned',
      isBn
          ? (deletedCount > 0
              ? '$deletedCountটি সাময়িক অডিও ফাইল মুছে ফেলা হয়েছে।'
              : 'কোনো সাময়িক অডিও ফাইল অবশিষ্ট নেই।')
          : (deletedCount > 0
              ? '$deletedCount temporary audio files deleted.'
              : 'All local recitation audio caches are clean.'),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> resetAllData() async {
    if (_pinService.isPinConfigured()) {
      final verified = await PinDialog.show(
        title: 'Factory Reset PIN',
        subtitle: 'Enter PIN to confirm erasing all data',
      );
      if (!verified) return;
    }

    _storageService.clear();
    loadSettings();
    Get.offAllNamed('/onboarding');
  }
}
