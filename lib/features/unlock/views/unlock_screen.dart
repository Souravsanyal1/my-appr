import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:focus_deen/core/constants/app_colors.dart';
import 'package:focus_deen/core/constants/app_strings.dart';
import 'package:focus_deen/features/unlock/controllers/unlock_controller.dart';

class UnlockScreen extends GetView<UnlockController> {
  const UnlockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<UnlockController>()) {
      Get.put(UnlockController());
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.unlockTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Target App Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                ),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: Colors.black,
                    child: Icon(Icons.lock_clock),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(() => Text(
                              controller.appName.value.isEmpty
                                  ? 'Restricted App'
                                  : controller.appName.value,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            )),
                        const SizedBox(height: 2),
                        const Text(
                          'Temporary Pass Required',
                          style: TextStyle(fontSize: 13, color: AppColors.warning),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Islamic Spiritual Practice / Reflection Module
            Text(
              'Mindful Reflection Exercise',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Pause, read, and reflect on this reminder before resuming your digital activity.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 14),

            // Quranic Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: isDark
                    ? const LinearGradient(
                        colors: [Color(0xFF1B3831), Color(0xFF132823)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Text(
                    'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '“قَدْ أَفْلَحَ الْمُؤْمِنُونَ • الَّذِينَ هُمْ فِي صَلَاتِهِمْ خَاشِعُونَ • وَالَّذِينَ هُمْ عَنِ اللَّغْوِ مُعْرِضُونَ”',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.6,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.ayahFocus,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: isDark ? AppColors.textSecondaryDark : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    AppStrings.ayahFocusSource,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Unlock Duration Tiers Guide
            Text(
              'Unlock Duration Tiers',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 10),
            _buildTierRow('70% – 79%', '5 minutes unlock', Icons.looks_one_outlined),
            const SizedBox(height: 8),
            _buildTierRow('80% – 89%', '10 minutes unlock', Icons.looks_two_outlined),
            const SizedBox(height: 8),
            _buildTierRow('90%+ Score', '15 minutes unlock', Icons.looks_3_outlined, isHighlighted: true),
            const SizedBox(height: 24),

            // Interactive Scoring Simulator (Prepares for Phase 5 Pronunciation module)
            Text(
              'Simulate Score / Controlled Unlock',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() {
              final score = controller.selectedScore.value;
              final duration = controller.getDurationForScore(score);

              return Column(
                children: [
                  Slider(
                    value: score.toDouble(),
                    min: 65,
                    max: 100,
                    divisions: 7,
                    activeColor: AppColors.primaryGold,
                    label: '$score%',
                    onChanged: (v) => controller.selectedScore.value = v.round(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Achieved Score: $score%', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: duration > 0 ? AppColors.emerald.withValues(alpha: 0.15) : AppColors.danger.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          duration > 0 ? 'Qualifies for $duration min' : 'Below passing threshold (70%)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: duration > 0 ? AppColors.emerald : AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
            const SizedBox(height: 32),

            // Submit Button
            Obx(() {
              final duration = controller.getDurationForScore(controller.selectedScore.value);
              final canUnlock = duration > 0 && !controller.isUnlocking.value;

              return SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canUnlock ? AppColors.primaryGold : Colors.grey,
                  ),
                  onPressed: canUnlock
                      ? () {
                          controller.unlock(
                            targetPackage: controller.packageName.value.isEmpty
                                ? 'com.instagram.android'
                                : controller.packageName.value,
                            targetAppName: controller.appName.value.isEmpty
                                ? 'App'
                                : controller.appName.value,
                            durationMinutes: duration,
                          );
                        }
                      : null,
                  child: controller.isUnlocking.value
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Text(
                          'Claim $duration-Minute Pass',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                ),
              );
            }),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Get.offAllNamed('/dashboard'),
                child: const Text('Cancel & Stay Mindful'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierRow(String scoreRange, String duration, IconData icon, {bool isHighlighted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isHighlighted ? AppColors.primaryGold.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? AppColors.primaryGold : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: isHighlighted ? AppColors.primaryGold : Colors.grey),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              scoreRange,
              style: TextStyle(
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                color: isHighlighted ? AppColors.primaryGold : null,
              ),
            ),
          ),
          Text(
            duration,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
