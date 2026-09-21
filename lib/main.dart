import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/services/firebase_auth_service.dart';
import 'core/services/firebase_realtime_service.dart';
import 'core/services/firestore_sync_service.dart';
import 'core/services/language_service.dart';
import 'core/services/native_bridge_service.dart';
import 'core/services/pin_security_service.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/limits/controllers/limit_controller.dart';
import 'features/usage/controllers/usage_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase safely
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint('Firebase initializeApp notice: $e');
  }

  // Initialize Storage Service
  final storageService = await StorageService().init();
  Get.put<StorageService>(storageService, permanent: true);

  // Initialize Language Service (Bengali & English)
  final languageService = await LanguageService().init();
  Get.put<LanguageService>(languageService, permanent: true);

  // Initialize Firebase & Cloud Sync Services (Auth, Firestore, Realtime Database)
  Get.put<FirebaseAuthService>(FirebaseAuthService(), permanent: true);
  Get.put<FirestoreSyncService>(FirestoreSyncService(), permanent: true);
  Get.put<FirebaseRealtimeService>(FirebaseRealtimeService(), permanent: true);

  // Initialize Core Services
  Get.put<NativeBridgeService>(NativeBridgeService(), permanent: true);
  Get.put<PinSecurityService>(PinSecurityService(), permanent: true);
  Get.put<ThemeController>(ThemeController(), permanent: true);

  // Initialize Global State Controllers
  Get.put<LimitController>(LimitController(), permanent: true);
  Get.put<UsageController>(UsageController(), permanent: true);

  runApp(const FocusDeenApp(initialRoute: AppRoutes.splash));
}

class FocusDeenApp extends StatelessWidget {
  final String initialRoute;

  const FocusDeenApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(() {
      return GetMaterialApp(
        title: 'FocusDeen',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.themeMode,
        initialRoute: initialRoute,
        getPages: AppPages.routes,
      );
    });
  }
}
