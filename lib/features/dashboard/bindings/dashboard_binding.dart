import 'package:get/get.dart';
import 'package:focus_deen/features/dashboard/controllers/dashboard_controller.dart';
import 'package:focus_deen/features/limits/controllers/limit_controller.dart';
import 'package:focus_deen/features/usage/controllers/usage_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<UsageController>()) {
      Get.put<UsageController>(UsageController());
    }
    if (!Get.isRegistered<LimitController>()) {
      Get.put<LimitController>(LimitController());
    }
    Get.put<DashboardController>(DashboardController());
  }
}
