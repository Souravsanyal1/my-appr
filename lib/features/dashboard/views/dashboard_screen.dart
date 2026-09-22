import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:focus_deen/core/constants/app_colors.dart';
import 'package:focus_deen/core/constants/app_spacing.dart';
import 'package:focus_deen/core/constants/app_strings.dart';
import 'package:focus_deen/core/services/language_service.dart';
import 'package:focus_deen/core/services/native_bridge_service.dart';
import 'package:focus_deen/core/services/notification_service.dart';
import 'package:focus_deen/core/widgets/app_icon_widget.dart';
import 'package:focus_deen/core/widgets/rank_shield_card.dart';
import 'package:focus_deen/core/widgets/restricted_settings_dialog.dart';
import 'package:focus_deen/features/dashboard/controllers/dashboard_controller.dart';
import 'package:focus_deen/features/limits/models/app_limit_model.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final langService = LanguageService.to;

    return Obx(() {
      final isBn = langService.isBangla;

      return Scaffold(
        appBar: AppBar(
          title: Text(
            isBn ? 'ফোকাসদ্বীন' : AppStrings.appName,
            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          automaticallyImplyLeading: false,
          actions: [
            Obx(() {
              final notifService = Get.isRegistered<NotificationService>()
                  ? NotificationService.to
                  : null;
              final unread = notifService?.unreadCount.value ?? 0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    tooltip: isBn ? 'বিজ্ঞপ্তি' : 'Notifications',
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => Get.toNamed('/notifications'),
                  ),
                  if (unread > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unread > 9 ? '9+' : '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            }),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async => controller.refreshDashboard(),
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            children: [
              // 1. Islamic Daily Motivation Banner
              _buildDailyReminderCard(context, isDark, isBn),
              const SizedBox(height: AppSpacing.md),

              // 2. Rank & Habit Progress Shield (Visual Parity with Blocked & Progress Screens)
              const RankShieldCard(compact: true),
              const SizedBox(height: AppSpacing.md),

              // 3. Main Stats Summary Card (Focus Score + Screen Time)
              _buildStatsOverviewCard(context, isDark, isBn),
              const SizedBox(height: AppSpacing.md),

              // 4. Battery Optimization Exemption Banner
              _buildBatteryOptimizationBanner(context, isDark, isBn),

              // 5. Accessibility Service Warning / Restricted Setting Banner
              _buildAccessibilityWarningBanner(context, isDark, isBn),

              // 6. Active Temporary Unlocks Section (if any)
              _buildActiveUnlocksSection(context, isDark, isBn),

              // 7. Islamic Focus & Mindfulness Cards
              _buildMindfulnessToolsSection(context, isDark, isBn),
              const SizedBox(height: AppSpacing.md),

              // 8. Quick Action Buttons
              _buildQuickActions(context, isBn),
              const SizedBox(height: AppSpacing.lg),

              // 9. Monitored Apps & Limits Section
              _buildMonitoredAppsSection(context, isDark, isBn),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildDailyReminderCard(BuildContext context, bool isDark, bool isBn) {
    final quote = isBn
        ? '“পাঁচটি বিষয় আসার পূর্বে পাঁচটি বিষয়ের সুযোগ গ্রহণ কর: তোমার বার্ধক্যের পূর্বে যৌবন, অসুস্থতার পূর্বে সুস্থতা, দারিদ্র্যের পূর্বে সচ্ছলতা, ব্যস্ততার পূর্বে অবসর এবং মৃত্যুর পূর্বে তোমার জীবন।”'
        : AppStrings.quoteTime;
    final source = isBn ? '— রাসূলুল্লাহ ﷺ (আল-হাকিম)' : AppStrings.quoteTimeSource;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkCardGradient : null,
        color: isDark ? null : AppColors.lightCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wb_sunny_outlined,
              color: AppColors.primaryGold,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBn ? 'দৈনিক উপদেশ' : 'Daily Reflection',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.primaryGold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  quote,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  source,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverviewCard(BuildContext context, bool isDark, bool isBn) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Obx(() {
        final score = controller.usageController.focusScore.value;
        final totalMins = controller.usageController.totalTodayMinutes.value;
        final limitsCount = controller.limitController.limits.length;

        final hours = totalMins ~/ 60;
        final mins = totalMins % 60;
        final timeFormatted = hours > 0
            ? (isBn ? '$hoursঘ $minsমি' : '${hours}h ${mins}m')
            : (isBn ? '$minsমি' : '${mins}m');

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Focus Score Dial
            Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 76,
                      height: 76,
                      child: CircularProgressIndicator(
                        value: (score / 100).clamp(0.0, 1.0),
                        strokeWidth: 8,
                        backgroundColor: isDark
                            ? Colors.white12
                            : Colors.black12,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          score >= 80 ? AppColors.emerald : AppColors.warning,
                        ),
                      ),
                    ),
                    Text(
                      '$score',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isBn ? 'ফোকাস স্কোর' : 'Focus Score',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            Container(
              height: 70,
              width: 1,
              color: isDark ? Colors.white10 : Colors.black12,
            ),
            // Screen Time
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBn ? 'সীমিত অ্যাপের সময়' : 'Restricted Time',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeFormatted,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isBn
                      ? '$limitsCountটি অ্যাপের সীমা সক্রিয়'
                      : '$limitsCount Active Limit${limitsCount == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _buildActiveUnlocksSection(BuildContext context, bool isDark, bool isBn) {
    return Obx(() {
      final unlocks = controller.activeUnlocks;
      if (unlocks.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.emerald.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.emerald.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock_open, color: AppColors.emerald, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isBn ? 'সক্রিয় সাময়িক আনলক পাস' : 'Active Temporary Passes',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.emerald,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...unlocks.map((session) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        session.appName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.emerald,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          session.remainingFormatted,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildBatteryOptimizationBanner(BuildContext context, bool isDark, bool isBn) {
    final nativeBridge = Get.find<NativeBridgeService>();

    return FutureBuilder<bool>(
      future: nativeBridge.isBatteryOptimizationIgnored(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data == false) {
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.battery_alert_outlined,
                  color: AppColors.warning,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBn ? 'ব্যাটারি অপ্টিমাইজেশন সক্রিয়' : 'Battery Optimization Active',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isBn
                            ? 'ব্যাকগ্রাউন্ডে ট্র্যাকিং নিরবচ্ছিন্ন রাখতে ফোকাসদ্বীনকে অপ্টিমাইজেশন থেকে বাদ দিন।'
                            : 'Exclude FocusDeen so monitoring stays active in background.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await nativeBridge.requestIgnoreBatteryOptimizations();
                  },
                  child: Text(
                    isBn ? 'ঠিক করুন' : 'Fix',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildAccessibilityWarningBanner(BuildContext context, bool isDark, bool isBn) {
    final nativeBridge = Get.find<NativeBridgeService>();

    return FutureBuilder<Map<String, bool>>(
      future: nativeBridge.checkPermissions(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data?['accessibility'] == false) {
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.accessibility_new,
                  color: Colors.redAccent,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBn ? 'এক্সেসিবিলিটি সার্ভিস নিষ্ক্রিয়' : 'Accessibility Service Inactive',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isBn
                            ? 'অ্যাপ ব্লকিং চালু রাখতে এক্সেসিবিলিটি চালু করুন।'
                            : 'Required to detect foreground apps. Fix "Restricted setting" if blocked.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => RestrictedSettingsDialog.show(context),
                  child: Text(
                    isBn ? 'গাইড দেখুন' : 'Fix / Guide',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMindfulnessToolsSection(BuildContext context, bool isDark, bool isBn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isBn ? 'ইসলামিক শিক্ষা ও আত্মনিয়ন্ত্রণ' : 'Islamic Learning & Focus',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        // Featured: Islamic Learning Library Card
        InkWell(
          onTap: () => Get.toNamed('/learning'),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F6B4F), Color(0xFF094332)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryEmerald.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.menu_book,
                    color: AppColors.secondaryGold,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBn ? 'ইসলামিক লার্নিং লাইব্রেরি' : 'Islamic Learning Library',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isBn
                            ? 'দৈনিক জিকির, দোয়া, নামাজ শিক্ষা ও প্রয়োজনীয় সূরা'
                            : 'Daily Dhikr, Duas, Salah Learning & Short Surahs',
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white70),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Row 1: Focus Session & Schedules
        Row(
          children: [
            Expanded(
              child: _buildToolCard(
                context,
                title: isBn ? 'ফোকাস সেশন' : 'Focus Session',
                subtitle: isBn ? '২৫মি পোমোডোরো' : '25m Pomodoro',
                icon: Icons.self_improvement,
                color: AppColors.emerald,
                isDark: isDark,
                onTap: () => Get.toNamed('/focus-session'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildToolCard(
                context,
                title: isBn ? 'ব্লক শিডিউল' : 'Block Schedules',
                subtitle: isBn ? 'পড়া ও নাইট মোড' : 'Study & Night Mode',
                icon: Icons.alarm_outlined,
                color: Colors.deepOrangeAccent,
                isDark: isDark,
                onTap: () => Get.toNamed('/schedule'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 2: Digital Tasbih & Adhkar
        Row(
          children: [
            Expanded(
              child: _buildToolCard(
                context,
                title: isBn ? 'ডিজিটাল তাসবীহ' : 'Digital Tasbih',
                subtitle: isBn ? 'দৈনিক জিকির গণক' : 'Daily Dhikr Counter',
                icon: Icons.fingerprint,
                color: AppColors.primaryGold,
                isDark: isDark,
                onTap: () => Get.toNamed('/tasbih'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildToolCard(
                context,
                title: isBn ? 'দৈনিক আজকার' : 'Daily Adhkar',
                subtitle: isBn ? 'সকাল ও সন্ধ্যার আমল' : 'Morning & Evening',
                icon: Icons.wb_sunny_outlined,
                color: Colors.teal,
                isDark: isDark,
                onTap: () => Get.toNamed('/adhkar'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? AppColors.darkCardBorder
                : AppColors.lightCardBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isBn) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.apps_outlined, size: 18),
            label: Text(isBn ? 'অ্যাপসমূহ' : 'Apps'),
            onPressed: () => Get.toNamed('/app-selection'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.timer_outlined, size: 18),
            label: Text(isBn ? 'সীমা নির্ধারণ' : 'Limits'),
            onPressed: () => Get.toNamed('/limits'),
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          tooltip: isBn ? 'ব্লক স্ক্রিন প্রিভিউ' : 'Preview Block Screen',
          icon: const Icon(Icons.play_arrow_rounded, color: AppColors.danger),
          onPressed: () {
            Get.toNamed(
              '/blocked',
              arguments: {
                'packageName': 'com.instagram.android',
                'appName': 'Instagram',
                'usedMinutes': 30,
                'limitMinutes': 30,
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildMonitoredAppsSection(BuildContext context, bool isDark, bool isBn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isBn ? 'অ্যাপ ব্যবহার ও সীমা' : 'App Usage & Limits',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => Get.toNamed('/limits'),
              child: Text(isBn ? 'পরিচালনা' : 'Manage'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Obx(() {
          final limits = controller.limitController.limits;
          if (limits.isEmpty) {
            return Card(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.hourglass_empty_rounded,
                        size: 36,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isBn
                            ? 'এখনো কোনো অ্যাপের সীমা যোগ করা হয়নি। কনফিগার করতে সীমা নির্ধারণে চাপুন।'
                            : 'No app limits added yet. Tap Limits to configure.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return Column(
            children: limits.map((limit) {
              final used = controller.usageController.getUsageForPackage(
                limit.packageName,
              );
              return _buildAppUsageCard(context, limit, used, isDark, isBn);
            }).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildAppUsageCard(
    BuildContext context,
    AppLimitModel limit,
    int usedMinutes,
    bool isDark,
    bool isBn,
  ) {
    final progress = (usedMinutes / limit.dailyLimitMinutes).clamp(0.0, 1.0);
    final isExceeded = usedMinutes >= limit.dailyLimitMinutes;
    final isWarning =
        !isExceeded &&
        (limit.dailyLimitMinutes - usedMinutes) <=
            limit.warningThresholdMinutes;

    Color statusColor = AppColors.emerald;
    String statusText = isBn ? 'স্বাভাবিক' : 'Normal';
    if (isExceeded) {
      statusColor = AppColors.danger;
      statusText = isBn ? 'সময় শেষ' : "Time's Up";
    } else if (isWarning) {
      statusColor = AppColors.warning;
      final remaining = limit.dailyLimitMinutes - usedMinutes;
      statusText = isBn ? 'সতর্কতা ($remainingমি বাকি)' : 'Warning ($remaining min left)';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                AppIconWidget(
                  packageName: limit.packageName,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        limit.appName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isBn
                            ? '$usedMinutes / ${limit.dailyLimitMinutes} মিনিট'
                            : '$usedMinutes / ${limit.dailyLimitMinutes} minutes',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: isDark ? Colors.white10 : Colors.black12,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
