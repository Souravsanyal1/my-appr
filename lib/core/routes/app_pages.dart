import 'package:get/get.dart';
import '../../features/app_selection/bindings/app_selection_binding.dart';
import '../../features/app_selection/views/app_selection_screen.dart';
import '../../features/auth/views/auth_screen.dart';
import '../../features/blocking/views/blocked_screen.dart';
import '../../features/dashboard/bindings/dashboard_binding.dart';
import '../../features/dashboard/views/dashboard_screen.dart';
import '../../features/dhikr/views/adhkar_screen.dart';
import '../../features/dhikr/views/tasbih_screen.dart';
import '../../features/focus_session/views/focus_session_screen.dart';
import '../../features/learning/views/learning_catalog_screen.dart';
import '../../features/limits/bindings/limit_binding.dart';
import '../../features/limits/views/limit_screen.dart';
import '../../features/onboarding/bindings/onboarding_binding.dart';
import '../../features/onboarding/views/onboarding_screen.dart';
import '../../features/schedule/views/schedule_screen.dart';
import '../../features/settings/views/settings_screen.dart';
import '../../features/statistics/views/statistics_screen.dart';
import '../../features/unlock/views/unlock_screen.dart';
import 'app_routes.dart';

class AppPages {
  static final List<GetPage> routes = [
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingScreen(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardScreen(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: AppRoutes.appSelection,
      page: () => const AppSelectionScreen(),
      binding: AppSelectionBinding(),
    ),
    GetPage(
      name: AppRoutes.limits,
      page: () => const LimitScreen(),
      binding: LimitBinding(),
    ),
    GetPage(
      name: AppRoutes.blocked,
      page: () => const BlockedScreen(),
    ),
    GetPage(
      name: AppRoutes.unlock,
      page: () => const UnlockScreen(),
    ),
    GetPage(
      name: AppRoutes.focusSession,
      page: () => const FocusSessionScreen(),
    ),
    GetPage(
      name: AppRoutes.tasbih,
      page: () => const TasbihScreen(),
    ),
    GetPage(
      name: AppRoutes.adhkar,
      page: () => const AdhkarScreen(),
    ),
    GetPage(
      name: AppRoutes.learning,
      page: () => const LearningCatalogScreen(),
    ),
    GetPage(
      name: AppRoutes.schedule,
      page: () => const ScheduleScreen(),
    ),
    GetPage(
      name: AppRoutes.statistics,
      page: () => const StatisticsScreen(),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsScreen(),
    ),
    GetPage(
      name: AppRoutes.auth,
      page: () => const AuthScreen(),
    ),
  ];
}
