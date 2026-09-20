import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:focus_deen/core/constants/app_colors.dart';
import 'package:focus_deen/core/constants/app_strings.dart';
import 'package:focus_deen/core/widgets/restricted_settings_dialog.dart';
import 'package:focus_deen/features/onboarding/controllers/onboarding_controller.dart';

class OnboardingScreen extends GetView<OnboardingController> {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Obx(() {
            return Column(
              children: [
                // Top Progress indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStepDot(0, controller.currentStep.value),
                    const SizedBox(width: 8),
                    _buildStepDot(1, controller.currentStep.value),
                  ],
                ),
                const SizedBox(height: 24),

                // Content
                Expanded(
                  child: controller.currentStep.value == 0
                      ? _buildWelcomeStep(context, isDark)
                      : _buildPermissionsStep(context, isDark),
                ),

                // Bottom Action
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: controller.nextStep,
                    child: Text(
                      controller.currentStep.value == 0
                          ? 'Continue to Setup'
                          : 'Enter FocusDeen',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildStepDot(int stepIndex, int current) {
    final isActive = stepIndex == current;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: isActive ? 28 : 10,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryGold : Colors.grey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildWelcomeStep(BuildContext context, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Islamic Emblem Graphic
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.emeraldGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.emerald.withValues(alpha: 0.3),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.mosque,
              size: 56,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 32),

        const Text(
          AppStrings.appName,
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),

        Text(
          AppStrings.tagline,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 28),

        // Islamic Reminder Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
            ),
          ),
          child: Column(
            children: [
              Text(
                AppStrings.quoteTime,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                AppStrings.quoteTimeSource,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionsStep(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.permissionsTitle,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.permissionsSubtitle,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 20),

          // 1. Usage Stats Permission
          Obx(() => _buildPermissionCard(
                context,
                title: 'Usage Access',
                desc: 'Needed to measure screen time on restricted apps accurately.',
                icon: Icons.bar_chart_rounded,
                isGranted: controller.hasUsagePermission.value,
                onRequest: () => controller.requestPermission('usageStats'),
              )),
          const SizedBox(height: 12),

          // 2. Accessibility Service Permission
          Obx(() => _buildPermissionCard(
                context,
                title: 'Accessibility Service',
                desc: 'Detects active foreground app to enforce limits in real-time.',
                icon: Icons.accessibility_new_rounded,
                isGranted: controller.hasAccessibilityPermission.value,
                onRequest: () => controller.requestPermission('accessibility'),
              )),
          Obx(() {
            if (!controller.hasAccessibilityPermission.value) {
              return Padding(
                padding: const EdgeInsets.only(top: 6.0, bottom: 4.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () => RestrictedSettingsDialog.show(context),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.help_outline, size: 14, color: AppColors.primaryGold),
                        SizedBox(width: 4),
                        Text(
                          'Android 13+ "Restricted Setting"? Tap here',
                          style: TextStyle(fontSize: 11, color: AppColors.primaryGold, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          const SizedBox(height: 12),

          // 3. System Alert Overlay
          Obx(() => _buildPermissionCard(
                context,
                title: 'Display Over Other Apps',
                desc: 'Allows FocusDeen to present the blocked reflection screen.',
                icon: Icons.layers_outlined,
                isGranted: controller.hasOverlayPermission.value,
                onRequest: () => controller.requestPermission('overlay'),
              )),
          const SizedBox(height: 12),

          // 4. Notifications
          Obx(() => _buildPermissionCard(
                context,
                title: 'Warnings & Notifications',
                desc: 'Alerts you 5 minutes before your daily limit is exhausted.',
                icon: Icons.notifications_active_outlined,
                isGranted: controller.hasNotificationPermission.value,
                onRequest: () => controller.requestPermission('notifications'),
              )),
        ],
      ),
    );
  }

  Widget _buildPermissionCard(
    BuildContext context, {
    required String title,
    required String desc,
    required IconData icon,
    required bool isGranted,
    required VoidCallback onRequest,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted
              ? AppColors.emerald.withValues(alpha: 0.5)
              : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isGranted ? AppColors.emerald : Colors.grey).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isGranted ? AppColors.emerald : Colors.grey,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isGranted)
            const Icon(Icons.check_circle, color: AppColors.emerald, size: 24)
          else
            TextButton(
              onPressed: onRequest,
              child: const Text('Enable', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}
