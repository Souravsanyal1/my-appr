import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'android_app_blocker.dart';
import 'app_blocker.dart';
import 'ios_app_blocker.dart';
import 'unsupported_app_blocker.dart';

/// GetX Service wrapper providing the active platform AppBlocker singleton.
class BlockerService extends GetxService {
  static BlockerService get to => Get.find<BlockerService>();

  late final AppBlocker blocker;

  BlockerService init() {
    if (kIsWeb) {
      blocker = UnsupportedAppBlocker();
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      blocker = AndroidAppBlocker();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      blocker = IosAppBlocker();
    } else {
      blocker = UnsupportedAppBlocker();
    }
    return this;
  }

  @override
  void onClose() {
    blocker.dispose();
    super.onClose();
  }
}
