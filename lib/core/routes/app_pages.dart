import 'package:get/get.dart';
import 'package:focus_deen/features/app_selection/bindings/app_selection_binding.dart';
import 'package:focus_deen/features/app_selection/views/app_selection_screen.dart';
import 'package:focus_deen/features/auth/views/auth_screen.dart';
import 'package:focus_deen/features/blocking/views/blocked_screen.dart';
import 'package:focus_deen/features/dashboard/bindings/dashboard_binding.dart';
import 'package:focus_deen/features/dashboard/views/dashboard_screen.dart';
import 'package:focus_deen/features/dhikr/views/adhkar_screen.dart';
import 'package:focus_deen/features/dhikr/views/tasbih_screen.dart';
import 'package:focus_deen/features/focus_session/views/focus_session_screen.dart';
import 'package:focus_deen/features/limits/bindings/limit_binding.dart';
import 'package:focus_deen/features/limits/views/limit_screen.dart';
import 'package:focus_deen/features/onboarding/bindings/onboarding_binding.dart';
import 'package:focus_deen/features/onboarding/views/onboarding_screen.dart';
import 'package:focus_deen/features/unlock/views/unlock_screen.dart';
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
      name: AppRoutes.auth,
      page: () => const AuthScreen(),
    ),
  ];
}
