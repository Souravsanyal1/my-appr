import 'package:get/get.dart';
import '../controllers/app_selection_controller.dart';

class AppSelectionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AppSelectionController>(() => AppSelectionController());
  }
}
