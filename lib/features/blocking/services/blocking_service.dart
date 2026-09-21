import 'package:get/get.dart';
import '../../../core/services/storage_service.dart';
import '../../schedule/models/schedule_model.dart';

class BlockingService extends GetxService {
  final StorageService _storageService = Get.find<StorageService>();

  bool isAppBlocked(String packageName, int usedMinutes) {
    // 1. Check if temporarily unlocked
    final unlocks = _storageService.getUnlockSessions();
    final activeUnlock = unlocks.firstWhereOrNull(
      (u) => u.packageName == packageName && !u.isExpired,
    );
    if (activeUnlock != null) return false;

    // 2. Check active scheduled restriction
    final rawSchedules = _storageService.read<List<dynamic>>('user_schedules');
    if (rawSchedules != null) {
      final now = DateTime.now();
      for (final raw in rawSchedules) {
        try {
          final schedule = ScheduleModel.fromMap(
            Map<String, dynamic>.from(raw as Map),
          );
          if (schedule.isTimeActive(now) &&
              schedule.blockedPackages.contains(packageName)) {
            return true;
          }
        } catch (_) {}
      }
    }

    // 3. Check daily limit
    final limits = _storageService.getLimits();
    final limit = limits.firstWhereOrNull((l) => l.packageName == packageName);
    if (limit == null || !limit.isEnabled) return false;

    return usedMinutes >= limit.dailyLimitMinutes;
  }
}
