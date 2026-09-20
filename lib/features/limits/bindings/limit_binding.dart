import 'package:get/get.dart';
import '../controllers/limit_controller.dart';

class LimitBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LimitController>(() => LimitController());
  }
}
