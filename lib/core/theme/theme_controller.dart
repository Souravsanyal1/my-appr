import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  static const String _themeKey = 'isDarkMode';
  final _storage = GetStorage();

  final RxBool isDarkMode = true.obs;

  @override
  void onInit() {
    super.onInit();
    final storedDark = _storage.read<bool>(_themeKey);
    if (storedDark != null) {
      isDarkMode.value = storedDark;
    } else {
      isDarkMode.value = true; // Default to dark theme
    }
  }

  ThemeMode get themeMode =>
      isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    _storage.write(_themeKey, isDarkMode.value);
    Get.changeThemeMode(themeMode);
  }
}
