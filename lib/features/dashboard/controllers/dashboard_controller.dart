import 'dart:async';
import 'package:get/get.dart';
import 'package:focus_deen/core/services/storage_service.dart';
import 'package:focus_deen/features/limits/controllers/limit_controller.dart';
import 'package:focus_deen/features/unlock/models/unlock_session_model.dart';
import 'package:focus_deen/features/usage/controllers/usage_controller.dart';

class DashboardController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();
  final UsageController usageController = Get.find<UsageController>();
  final LimitController limitController = Get.find<LimitController>();

  final RxList<UnlockSessionModel> activeUnlocks = <UnlockSessionModel>[].obs;
  Timer? _countdownTimer;

  @override
  void onInit() {
    super.onInit();
    refreshDashboard();
    _startTimer();
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    super.onClose();
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final list = _storageService.getUnlockSessions();
      activeUnlocks.assignAll(list);
    });
  }

  void refreshDashboard() {
    usageController.refreshUsage();
    limitController.loadLimits();
    activeUnlocks.assignAll(_storageService.getUnlockSessions());
  }
}
