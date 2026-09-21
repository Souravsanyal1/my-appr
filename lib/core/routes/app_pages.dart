import 'package:get/get.dart';
import '../../core/widgets/main_shell.dart';
import '../../features/app_selection/bindings/app_selection_binding.dart';
import '../../features/app_selection/views/app_selection_screen.dart';
import '../../features/auth/views/auth_screen.dart';
import '../../features/blocking/views/blocked_screen.dart';

import '../../features/dhikr/views/adhkar_screen.dart';
import '../../features/dhikr/views/tasbih_screen.dart';
import '../../features/focus_session/views/focus_session_screen.dart';
import '../../features/intention/views/intention_complete_view.dart';
import '../../features/intention/views/intention_screen.dart';
import '../../features/learning/views/deed_detail_view.dart';
import '../../features/learning/views/deeds_library_view.dart';
import '../../features/learning/views/learning_catalog_screen.dart';
import '../../features/learning/views/learning_mode_view.dart';
import '../../features/limits/bindings/limit_binding.dart';
import '../../features/limits/views/limit_screen.dart';
import '../../features/onboarding/bindings/onboarding_binding.dart';
import '../../features/onboarding/views/choose_apps_screen.dart';
import '../../features/onboarding/views/daily_goal_screen.dart';
import '../../features/onboarding/views/permission_setup_screen.dart';
import '../../features/onboarding/views/end_screen.dart';
import '../../features/onboarding/views/onboarding_screen.dart';
import '../../features/onboarding/views/splash_screen.dart';
import '../../features/onboarding/views/welcome_screen.dart';
import '../../features/schedule/views/schedule_screen.dart';
import '../../features/settings/views/profile_view.dart';
import '../../features/settings/views/settings_screen.dart';
import '../../features/statistics/views/progress_view.dart';
import '../../features/statistics/views/statistics_screen.dart';
import '../../features/unlock/views/active_unlock_view.dart';
import '../../features/unlock/views/analysis_view.dart';
import '../../features/unlock/views/recording_view.dart';
import '../../features/unlock/views/result_view.dart';
import '../../features/unlock/views/retry_result_view.dart';
import '../../features/notifications/views/notifications_inbox_view.dart';
import '../../features/unlock/views/unlock_screen.dart';
import '../../features/unlock/views/unlock_success_view.dart';
import 'app_routes.dart';

class AppPages {
  static final List<GetPage> routes = [
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    GetPage(name: AppRoutes.welcome, page: () => const WelcomeScreen()),
    GetPage(
      name: AppRoutes.chooseApps,
      page: () => const ChooseAppsScreen(),
      binding: AppSelectionBinding(),
    ),
    GetPage(
      name: AppRoutes.permissionSetup,
      page: () => const PermissionSetupScreen(),
    ),
    GetPage(name: AppRoutes.dailyGoal, page: () => const DailyGoalScreen()),
    GetPage(
      name: AppRoutes.home,
      page: () => const MainShell(),
    ),
    GetPage(name: AppRoutes.intention, page: () => const IntentionScreen()),
    GetPage(
      name: AppRoutes.intentionComplete,
      page: () => const IntentionCompleteView(),
    ),
    GetPage(name: AppRoutes.deedDetail, page: () => const DeedDetailView()),
    GetPage(name: AppRoutes.learningMode, page: () => const LearningModeView()),
    GetPage(name: AppRoutes.recording, page: () => const RecordingView()),
    GetPage(name: AppRoutes.analysis, page: () => const AnalysisView()),
    GetPage(name: AppRoutes.result, page: () => const ResultView()),
    GetPage(name: AppRoutes.retryResult, page: () => const RetryResultView()),
    GetPage(
      name: AppRoutes.unlockSuccess,
      page: () => const UnlockSuccessView(),
    ),
    GetPage(name: AppRoutes.activeUnlock, page: () => const ActiveUnlockView()),
    GetPage(name: AppRoutes.endScreen, page: () => const EndScreenView()),
    GetPage(name: AppRoutes.deeds, page: () => const DeedsLibraryView()),
    GetPage(name: AppRoutes.progress, page: () => const ProgressView()),
    GetPage(name: AppRoutes.profile, page: () => const ProfileView()),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingScreen(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const MainShell(),
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
    GetPage(name: AppRoutes.blocked, page: () => const BlockedScreen()),
    GetPage(name: AppRoutes.unlock, page: () => const UnlockScreen()),
    GetPage(
      name: AppRoutes.focusSession,
      page: () => const FocusSessionScreen(),
    ),
    GetPage(name: AppRoutes.tasbih, page: () => const TasbihScreen()),
    GetPage(name: AppRoutes.adhkar, page: () => const AdhkarScreen()),
    GetPage(
      name: AppRoutes.learning,
      page: () => const LearningCatalogScreen(),
    ),
    GetPage(name: AppRoutes.schedule, page: () => const ScheduleScreen()),
    GetPage(name: AppRoutes.statistics, page: () => const StatisticsScreen()),
    GetPage(name: AppRoutes.settings, page: () => const SettingsScreen()),
    GetPage(name: AppRoutes.auth, page: () => const AuthScreen()),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsInboxView(),
    ),
  ];
}
