import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
// ignore: unused_import
import 'lock_overlay_main.dart'; // Ensures lockOverlayMain entrypoint is included in the build

import 'core/blocker/blocker_service.dart';
import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/services/device_identity_service.dart';
import 'core/services/firebase_auth_service.dart';
import 'core/services/firebase_realtime_service.dart';
import 'core/services/firestore_sync_service.dart';
import 'core/services/gamification_service.dart';
import 'core/services/language_service.dart';
import 'core/services/native_bridge_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/pin_security_service.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/limits/controllers/limit_controller.dart';
import 'features/usage/controllers/usage_controller.dart';

// Top-level FCM background handler — must be registered BEFORE Firebase.initializeApp
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM Background] Received: ${message.messageId}');
  // No initialization needed here; local scheduling is deferred to next app open.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register background message handler BEFORE Firebase init
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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
  final nativeBridge = Get.put<NativeBridgeService>(
    NativeBridgeService(),
    permanent: true,
  );
  Get.put<PinSecurityService>(PinSecurityService(), permanent: true);
  Get.put<ThemeController>(ThemeController(), permanent: true);
  Get.put<BlockerService>(BlockerService().init(), permanent: true);

  // Initialize Gamification & Stacking Unlock Service
  final gamificationService = await GamificationService().init();
  Get.put<GamificationService>(gamificationService, permanent: true);

  // Initialize Device Identity (anonymous UUID + Firestore user doc)
  final deviceIdentityService = await DeviceIdentityService().init();
  Get.put<DeviceIdentityService>(deviceIdentityService, permanent: true);

  // Initialize Notification Service (FCM + local notifications + inbox)
  final notificationService = await NotificationService().init();
  Get.put<NotificationService>(notificationService, permanent: true);

  // Sync user document on app open (throttled to once/hour)
  unawaited(deviceIdentityService.syncUserDocument());

  // Sync monitored/protected packages to Android Native Layer
  final initialMonitored = storageService.getMonitoredPackages();
  nativeBridge.syncMonitoredPackages(initialMonitored);

  // Sync overlay settings (min score threshold, unlock duration) to native SharedPreferences
  final minScore = storageService.read<int>('unlock_threshold_percentage') ?? 80;
  final unlockDuration = storageService.read<int>('unlock_duration_minutes') ?? 30;
  nativeBridge.syncSettings(minScore: minScore, unlockDurationMinutes: unlockDuration);

  // Initialize Global State Controllers
  Get.put<LimitController>(LimitController(), permanent: true);
  Get.put<UsageController>(UsageController(), permanent: true);

  runApp(const FocusDeenApp(initialRoute: AppRoutes.splash));
}

void unawaited(Future<void> future) {
  // Intentionally not awaiting — fire and forget with error catch
  future.catchError((e) => debugPrint('[unawaited] $e'));
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
