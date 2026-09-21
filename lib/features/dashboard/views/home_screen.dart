import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/gamification_service.dart';
import '../../../core/services/language_service.dart';
import '../../../core/services/native_bridge_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/storage_service.dart';
import '../../settings/views/profile_view.dart';
import '../../statistics/views/progress_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 3-tab BottomNav: 0: Stats, 1: Unlock (Center Dashboard / Primary), 2: Settings
  int _currentTabIndex = 1;

  @override
  Widget build(BuildContext context) {
    final languageService = LanguageService.to;

    return Obx(() {
      final isBn = languageService.isBangla;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(
          index: _currentTabIndex,
          children: [
            const ProgressView(),
            _buildHomeTab(context, isBn),
            const ProfileView(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.border, width: 1.0),
            ),
          ),
          child: NavigationBar(
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.primaryGreen.withValues(alpha: 0.18),
            selectedIndex: _currentTabIndex,
            onDestinationSelected: (idx) {
              if (idx == 1 && _currentTabIndex == 1) {
                // Tapping center Unlock while on Home opens the Deed Reveal flow
                Get.toNamed('/unlock');
              } else {
                setState(() => _currentTabIndex = idx);
              }
            },
            destinations: [
              // 1. Stats (merged from অগ্রগতি / Progress)
              NavigationDestination(
                icon: const Icon(
                  Iconsax.chart_21,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
                selectedIcon: const Icon(
                  Iconsax.chart_2,
                  color: AppColors.brightGreen,
                  size: 22,
                ),
                label: languageService.t('nav_stats'),
              ),
              // 2. Unlock (Center Padlock - Primary Tab)
              NavigationDestination(
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.5)),
                  ),
                  child: const Icon(
                    Iconsax.unlock,
                    color: AppColors.brightGreen,
                    size: 20,
                  ),
                ),
                selectedIcon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Iconsax.unlock,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
                label: languageService.t('nav_unlock'),
              ),
              // 3. Settings (merged from প্রোফাইল / Profile & Settings)
              NavigationDestination(
                icon: const Icon(
                  Iconsax.setting_2,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
                selectedIcon: const Icon(
                  Iconsax.setting_2,
                  color: AppColors.brightGreen,
                  size: 22,
                ),
                label: languageService.t('nav_settings'),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHomeTab(BuildContext context, bool isBn) {
    final gamification = GamificationService.to;
    final storage = Get.find<StorageService>();
    final languageService = LanguageService.to;
    final monitoredPkgs = storage.getMonitoredPackages();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===============================================================
            // 1. TOP BAR: App Logo + Name (Left) & Streak with Flame (Right)
            // ===============================================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: Logo + App Name
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryGreen.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.mosque_rounded,
                          color: AppColors.brightGreen,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      languageService.t('app_name'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),

                // Right: Notification Bell + Language Switcher + Streak
                Row(
                  children: [
                    // Notification Bell with unread badge
                    Obx(() {
                      final notifService = Get.isRegistered<NotificationService>()
                          ? NotificationService.to
                          : null;
                      final unread = notifService?.unreadCount.value ?? 0;
                      return GestureDetector(
                        onTap: () => Get.toNamed(AppRoutes.notifications),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Center(
                                child: Icon(
                                  Iconsax.notification,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            if (unread > 0)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    color: AppColors.brightGreen,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      unread > 9 ? '9+' : '$unread',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(width: 8),

                    // Language Switcher Chip
                    GestureDetector(
                      onTap: () => languageService.showLanguageSelector(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Iconsax.global,
                              size: 14,
                              color: AppColors.brightGreen,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isBn ? 'বাং' : 'EN',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.brightGreen,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.arrow_drop_down,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Streak Counter with Google Material Fire Icon
                    Obx(
                      () => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFFA726).withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_fire_department_rounded,
                              size: 17,
                              color: Color(0xFFFFA726),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${gamification.currentStreak.value}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Accessibility Permission Alert Banner (if needed)
            FutureBuilder<bool>(
              future: Get.find<NativeBridgeService>().checkAccessibilityPermission(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data == false) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.warning,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isBn
                                ? 'অ্যাপ লক সক্রিয় করতে এক্সেসিবিলিটি সার্ভিস অন করুন।'
                                : 'Enable accessibility service to activate app lock.',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              Get.find<NativeBridgeService>().requestPermission('accessibility'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.warning,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: Text(isBn ? 'অন করুন' : 'Enable'),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // ===============================================================
            // 2. HORIZONTAL WEEK STRIP (Sun–Sat)
            // ===============================================================
            _buildHorizontalWeekStrip(context, gamification, isBn),
            const SizedBox(height: 18),

            // ===============================================================
            // a) "TIME REMAINING" CARD — Live Countdown (Persists Across Restarts)
            // ===============================================================
            _buildTimeRemainingCard(context, gamification, isBn),
            const SizedBox(height: 14),

            // ===============================================================
            // b) BIG STATUS BANNER — "APPS CURRENTLY Unlocked" / "Locked"
            // ===============================================================
            _buildStatusBanner(context, gamification, isBn),
            const SizedBox(height: 14),

            // ===============================================================
            // c) "ADD MORE TIME" CARD — Stack Time with Deed Trigger
            // ===============================================================
            _buildAddMoreTimeCard(context, isBn),
            const SizedBox(height: 14),

            // ===============================================================
            // d) "LOCKED APPS" SECTION — Count, Lock Status & App Picker
            // ===============================================================
            _buildLockedAppsSection(context, gamification, monitoredPkgs, isBn),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Week Strip (Sun–Sat) with highlighted today ring and filled past days
  // ---------------------------------------------------------------------------
  Widget _buildHorizontalWeekStrip(
    BuildContext context,
    GamificationService gamification,
    bool isBn,
  ) {
    final now = DateTime.now();
    // Sunday of the current week
    final daysFromSunday = now.weekday % 7;
    final sunday = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysFromSunday));

    final dayNamesEn = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final dayNamesBn = ['রবি', 'সোম', 'মঙ্গল', 'বুধ', 'বৃহ', 'শুক্র', 'শনি'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          final dayDate = sunday.add(Duration(days: index));
          final isToday = dayDate.year == now.year &&
              dayDate.month == now.month &&
              dayDate.day == now.day;
          final isPast = dayDate.isBefore(DateTime(now.year, now.month, now.day));

          // Check if user completed deeds on this day
          final dayWeekday = dayDate.weekday; // Sunday is 7, Monday is 1...
          final isCompleted = gamification.weeklyCompletedDays.contains(dayWeekday);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isBn ? dayNamesBn[index] : dayNamesEn[index],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                  color: isToday ? AppColors.brightGreen : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? AppColors.primaryGreen.withValues(alpha: 0.25)
                      : (isToday ? AppColors.surfaceLight : Colors.transparent),
                  border: Border.all(
                    color: isToday
                        ? AppColors.brightGreen
                        : (isCompleted ? AppColors.primaryGreen : AppColors.border),
                    width: isToday ? 2.0 : 1.0,
                  ),
                ),
                child: Center(
                  child: isCompleted && isPast
                      ? const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: AppColors.brightGreen,
                        )
                      : Text(
                          '${dayDate.day}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                            color: isToday ? AppColors.brightGreen : AppColors.textPrimary,
                          ),
                        ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // a) "Time Remaining" Card — Live Countdown
  // ---------------------------------------------------------------------------
  Widget _buildTimeRemainingCard(
    BuildContext context,
    GamificationService gamification,
    bool isBn,
  ) {
    final languageService = LanguageService.to;

    return Obx(() {
      final isUnlocked = gamification.isUnlocked;
      final countdownStr = gamification.formattedCountdown;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isUnlocked
                ? AppColors.primaryGreen.withValues(alpha: 0.35)
                : AppColors.border,
            width: isUnlocked ? 1.5 : 1.0,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Iconsax.timer_1,
                        color: AppColors.brightGreen,
                        size: 17,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        languageService.t('time_remaining'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    countdownStr,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                      color: isUnlocked ? AppColors.brightGreen : AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isUnlocked
                        ? (isBn ? 'অ্যাপসমূহ ব্যবহারে সময় বরাদ্দ আছে' : 'Access granted across protected apps')
                        : (isBn ? 'কোনো সময় অবশিষ্ট নেই' : 'No access time currently remaining'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? AppColors.primaryGreen.withValues(alpha: 0.15)
                    : AppColors.surfaceLight,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isUnlocked ? AppColors.brightGreen : AppColors.border,
                ),
              ),
              child: Icon(
                isUnlocked ? Iconsax.clock : Iconsax.timer_pause,
                color: isUnlocked ? AppColors.brightGreen : AppColors.textMuted,
                size: 24,
              ),
            ),
          ],
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // b) Big Status Banner — "APPS CURRENTLY Unlocked" / "Locked"
  // ---------------------------------------------------------------------------
  Widget _buildStatusBanner(
    BuildContext context,
    GamificationService gamification,
    bool isBn,
  ) {
    final languageService = LanguageService.to;

    return Obx(() {
      final isUnlocked = gamification.isUnlocked;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isUnlocked
              ? AppColors.primaryGreen.withValues(alpha: 0.14)
              : AppColors.error.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUnlocked
                ? AppColors.primaryGreen.withValues(alpha: 0.5)
                : AppColors.error.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? AppColors.primaryGreen.withValues(alpha: 0.2)
                    : AppColors.error.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUnlocked ? Iconsax.unlock : Iconsax.lock,
                color: isUnlocked ? AppColors.brightGreen : AppColors.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isUnlocked
                        ? languageService.t('apps_currently_unlocked')
                        : languageService.t('apps_currently_locked'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: isUnlocked ? AppColors.brightGreen : AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isUnlocked
                        ? languageService.t('apps_unlocked_desc')
                        : languageService.t('all_apps_locked'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // c) "Add more time" Card — Stacking Unlock Trigger
  // ---------------------------------------------------------------------------
  Widget _buildAddMoreTimeCard(BuildContext context, bool isBn) {
    final languageService = LanguageService.to;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Iconsax.add_circle,
                color: AppColors.brightGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                languageService.t('add_more_time'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            languageService.t('add_time_description'),
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Get.toNamed('/unlock'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    languageService.t('do_another_deed'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // d) "Locked Apps" Section
  // ---------------------------------------------------------------------------
  Widget _buildLockedAppsSection(
    BuildContext context,
    GamificationService gamification,
    List<String> monitoredPkgs,
    bool isBn,
  ) {
    final languageService = LanguageService.to;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            languageService.t('locked_apps'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primaryGreen.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            '${monitoredPkgs.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.brightGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Obx(
                      () => Text(
                        gamification.isUnlocked
                            ? (isBn ? 'সুরক্ষিত অ্যাপসমূহ সাময়িক আনলকড' : 'Protected apps temporarily accessible')
                            : (isBn ? 'সুরক্ষিত সকল অ্যাপ লক করা আছে' : 'All protected apps are locked'),
                        style: TextStyle(
                          fontSize: 12,
                          color: gamification.isUnlocked
                              ? AppColors.brightGreen
                              : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => Get.toNamed('/choose-apps'),
                icon: const Icon(Iconsax.setting_4, size: 16),
                label: Text(
                  isBn ? 'অ্যাপ বাছুন' : 'Choose',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brightGreen,
                  side: BorderSide(
                    color: AppColors.primaryGreen.withValues(alpha: 0.4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Iconsax.eye_slash,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                languageService.t('app_icons_privacy_note'),
                style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
