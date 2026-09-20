import 'package:get/get.dart';
import 'package:focus_deen/core/services/storage_service.dart';

class BlockingService extends GetxService {
  final StorageService _storageService = Get.find<StorageService>();

  bool isAppBlocked(String packageName, int usedMinutes) {
    final limits = _storageService.getLimits();
    final limit = limits.firstWhereOrNull((l) => l.packageName == packageName);
    if (limit == null || !limit.isEnabled) return false;

    // Check if temporarily unlocked
    final unlocks = _storageService.getUnlockSessions();
    final activeUnlock = unlocks.firstWhereOrNull((u) => u.packageName == packageName && !u.isExpired);
    if (activeUnlock != null) return false;

    return usedMinutes >= limit.dailyLimitMinutes;
  }
}
