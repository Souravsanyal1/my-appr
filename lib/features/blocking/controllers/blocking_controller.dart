import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:focus_deen/core/services/native_bridge_service.dart';
import 'package:focus_deen/features/app_selection/controllers/app_selection_controller.dart';

class BlockingController extends GetxController {
  final NativeBridgeService _nativeBridge = Get.find<NativeBridgeService>();

  final RxString packageName = ''.obs;
  final RxString appName = ''.obs;
  final RxInt usedMinutes = 0.obs;
  final RxInt limitMinutes = 0.obs;

  /// Icon bytes for the currently blocked app, sourced from the cached
  /// InstalledAppModel list if AppSelectionController is already loaded.
  Uint8List? get blockedAppIconBytes {
    if (!Get.isRegistered<AppSelectionController>()) return null;
    final ctrl = Get.find<AppSelectionController>();
    final pkg = packageName.value;
    if (pkg.isEmpty) return null;
    try {
      return ctrl.allApps
          .firstWhere((a) => a.packageName == pkg)
          .iconBytes;
    } catch (_) {
      return null;
    }
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      packageName.value =
          args['packageName']?.toString() ?? 'com.instagram.android';
      appName.value = args['appName']?.toString() ?? 'Instagram';
      usedMinutes.value = (args['usedMinutes'] as num?)?.toInt() ?? 30;
      limitMinutes.value = (args['limitMinutes'] as num?)?.toInt() ?? 30;
    } else {
      final params = Get.parameters;
      packageName.value = params['package'] ?? 'com.instagram.android';
      appName.value = params['appName'] ?? 'Instagram';
      usedMinutes.value = int.tryParse(params['used'] ?? '30') ?? 30;
      limitMinutes.value = int.tryParse(params['limit'] ?? '30') ?? 30;
    }
  }

  void onLearnToUnlock() {
    Get.toNamed(
      '/unlock',
      arguments: {'packageName': packageName.value, 'appName': appName.value},
    );
  }

  void onStartFocusSession() {
    Get.snackbar(
      'Focus Session Started',
      '25-minute mindful focus timer is active. Distractions are paused.',
      snackPosition: SnackPosition.TOP,
    );
    Get.offAllNamed('/dashboard');
  }

  Future<void> onCloseApp() async {
    // Close the blocked app via native accessibility action
    await _nativeBridge.closeForegroundApp();
    Get.offAllNamed('/dashboard');
  }
}
