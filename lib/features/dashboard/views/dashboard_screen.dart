import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:focus_deen/core/constants/app_colors.dart';
import 'package:focus_deen/core/constants/app_strings.dart';
import 'package:focus_deen/core/theme/theme_controller.dart';
import 'package:focus_deen/features/dashboard/controllers/dashboard_controller.dart';
import 'package:focus_deen/features/limits/models/app_limit_model.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mosque, color: AppColors.primaryGold, size: 22),
            SizedBox(width: 8),
            Text(
              AppStrings.appName,
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ],
        ),
        actions: [
          // Theme Toggle
          Obx(() => IconButton(
                icon: Icon(
                  themeController.isDarkMode.value ? Icons.light_mode : Icons.dark_mode,
                  color: AppColors.primaryGold,
                ),
                onPressed: themeController.toggleTheme,
              )),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.refreshDashboard,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => controller.refreshDashboard(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // 1. Islamic Daily Motivation Banner
            _buildDailyReminderCard(context, isDark),
            const SizedBox(height: 16),

            // 2. Main Stats Summary Card (Focus Score + Screen Time)
            _buildStatsOverviewCard(context, isDark),
            const SizedBox(height: 16),

            // 3. Active Temporary Unlocks Section (if any)
            _buildActiveUnlocksSection(context, isDark),

            // 4. Quick Action Buttons
            _buildQuickActions(context),
            const SizedBox(height: 20),

            // 5. Monitored Apps & Limits Section
            _buildMonitoredAppsSection(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyReminderCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkCardGradient : null,
        color: isDark ? null : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
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
            child: const Icon(Icons.wb_sunny_outlined, color: AppColors.primaryGold, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Reflection',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.primaryGold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.quoteTime,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverviewCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
      ),
      child: Obx(() {
        final score = controller.usageController.focusScore.value;
        final totalMins = controller.usageController.totalTodayMinutes.value;
        final limitsCount = controller.limitController.limits.length;

        final hours = totalMins ~/ 60;
        final mins = totalMins % 60;
        final timeFormatted = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

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
                        backgroundColor: isDark ? Colors.white12 : Colors.black12,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          score >= 80 ? AppColors.emerald : AppColors.warning,
                        ),
                      ),
                    ),
                    Text(
                      '$score',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Focus Score',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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
                  'Restricted Time',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
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
                  '$limitsCount Active Limit${limitsCount == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _buildActiveUnlocksSection(BuildContext context, bool isDark) {
    return Obx(() {
      final unlocks = controller.activeUnlocks;
      if (unlocks.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.emerald.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.emerald.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lock_open, color: AppColors.emerald, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Active Temporary Passes',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.emerald),
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
                      Text(session.appName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.apps_outlined, size: 18),
            label: const Text('Apps'),
            onPressed: () => Get.toNamed('/app-selection'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.timer_outlined, size: 18),
            label: const Text('Limits'),
            onPressed: () => Get.toNamed('/limits'),
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          tooltip: 'Preview Block Screen',
          icon: const Icon(Icons.play_arrow_rounded, color: AppColors.danger),
          onPressed: () {
            Get.toNamed('/blocked', arguments: {
              'packageName': 'com.instagram.android',
              'appName': 'Instagram',
              'usedMinutes': 30,
              'limitMinutes': 30,
            });
          },
        ),
      ],
    );
  }

  Widget _buildMonitoredAppsSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'App Usage & Limits',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => Get.toNamed('/limits'),
              child: const Text('Manage'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Obx(() {
          final limits = controller.limitController.limits;
          if (limits.isEmpty) {
            return const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text('No app limits added yet. Tap Limits to configure.'),
                ),
              ),
            );
          }

          return Column(
            children: limits.map((limit) {
              final used = controller.usageController.getUsageForPackage(limit.packageName);
              return _buildAppUsageCard(context, limit, used, isDark);
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
  ) {
    final progress = (usedMinutes / limit.dailyLimitMinutes).clamp(0.0, 1.0);
    final isExceeded = usedMinutes >= limit.dailyLimitMinutes;
    final isWarning = !isExceeded && (limit.dailyLimitMinutes - usedMinutes) <= limit.warningThresholdMinutes;

    Color statusColor = AppColors.emerald;
    String statusText = 'Normal';
    if (isExceeded) {
      statusColor = AppColors.danger;
      statusText = "Time's Up";
    } else if (isWarning) {
      statusColor = AppColors.warning;
      statusText = 'Warning (${limit.dailyLimitMinutes - usedMinutes}m left)';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withValues(alpha: 0.15),
                  child: Icon(
                    isExceeded ? Icons.block : Icons.phone_android,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        limit.appName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$usedMinutes / ${limit.dailyLimitMinutes} minutes',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
