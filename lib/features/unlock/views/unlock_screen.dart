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
      appBar: AppBar(title: const Text(AppStrings.unlockTitle)),
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
                  color: isDark
                      ? AppColors.darkCardBorder
                      : AppColors.lightCardBorder,
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
                        Obx(
                          () => Text(
                            controller.appName.value.isEmpty
                                ? 'Restricted App'
                                : controller.appName.value,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Recite to Earn an Unlock Pass',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Surah Selection Pills
            Text(
              'Select Challenge Surah',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontSize: 17),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: Obx(() {
                final selectedIndex = controller.selectedVerseIndex.value;
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.verses.length,
                  itemBuilder: (context, index) {
                    final verse = controller.verses[index];
                    final isSelected = selectedIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(verse.surahName.split('(').first.trim()),
                        selected: isSelected,
                        selectedColor: AppColors.primaryGold.withValues(
                          alpha: 0.2,
                        ),
                        onSelected: (_) => controller.selectVerse(index),
                      ),
                    );
                  },
                );
              }),
            ),
            const SizedBox(height: 16),

            // Quranic Card to Recite
            Obx(() {
              final verse = controller.currentVerse;
              return Container(
                width: double.infinity,
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
                  border: Border.all(
                    color: AppColors.emerald.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      verse.surahName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      verse.arabic,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        height: 1.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      verse.transliteration,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      verse.translation,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),

            // Audio Recording Section
            Center(
              child: Obx(() {
                final isRec = controller.isRecording.value;
                final seconds = controller.recordingSeconds.value;

                return Column(
                  children: [
                    GestureDetector(
                      onTap: controller.toggleRecording,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isRec ? 88 : 76,
                        height: isRec ? 88 : 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isRec
                              ? AppColors.danger
                              : AppColors.primaryGold,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isRec
                                          ? AppColors.danger
                                          : AppColors.primaryGold)
                                      .withValues(alpha: 0.4),
                              blurRadius: isRec ? 24 : 12,
                              spreadRadius: isRec ? 6 : 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          isRec ? Icons.stop : Icons.mic,
                          color: isRec ? Colors.white : Colors.black,
                          size: 38,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isRec
                          ? 'Recording recitation... 00:${seconds.toString().padLeft(2, '0')}'
                          : 'Tap microphone to start reciting',
                      style: TextStyle(
                        fontWeight: isRec ? FontWeight.bold : FontWeight.normal,
                        color: isRec ? AppColors.danger : null,
                      ),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 20),

            // Score Result Card (when recorded)
            Obx(() {
              if (controller.isAnalyzing.value) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 14),
                      Text('Analyzing pronunciation & rhythm...'),
                    ],
                  ),
                );
              }

              final res = controller.recitationResult.value;
              if (res == null) return const SizedBox.shrink();

              return Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: res.isPassing
                      ? AppColors.primaryEmerald.withValues(alpha: 0.12)
                      : AppColors.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: res.isPassing
                        ? AppColors.primaryEmerald
                        : AppColors.danger,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Practice Score: ${res.overallScore}%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: res.isPassing
                                ? AppColors.primaryEmerald
                                : AppColors.danger,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: res.isPassing
                                ? AppColors.primaryEmerald
                                : AppColors.danger,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            res.isPassing
                                ? '${res.earnedUnlockMinutes}m Pass'
                                : 'Try Again',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Detailed metrics
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricCol(
                          'Words',
                          '${res.wordRecognitionScore}%',
                        ),
                        _buildMetricCol('Timing', '${res.timingScore}%'),
                        _buildMetricCol(
                          'Similarity',
                          '${res.audioSimilarityScore}%',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      res.feedback,
                      style: const TextStyle(fontSize: 13, height: 1.3),
                    ),
                    const SizedBox(height: 8),
                    // Tajweed Disclaimer
                    Text(
                      res.disclaimer,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Unlock Duration Tiers Guide
            Text(
              'Unlock Duration Tiers',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildTierRow(
              '70% – 79%',
              '5 minutes unlock',
              Icons.looks_one_outlined,
            ),
            const SizedBox(height: 6),
            _buildTierRow(
              '80% – 89%',
              '10 minutes unlock',
              Icons.looks_two_outlined,
            ),
            const SizedBox(height: 6),
            _buildTierRow(
              '90%+ Score',
              '15 minutes unlock',
              Icons.looks_3_outlined,
              isHighlighted: true,
            ),
            const SizedBox(height: 24),

            // Submit Button
            Obx(() {
              final res = controller.recitationResult.value;
              final duration = res != null
                  ? res.earnedUnlockMinutes
                  : controller.getDurationForScore(
                      controller.selectedScore.value,
                    );
              final canUnlock = duration > 0 && !controller.isUnlocking.value;

              return SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canUnlock
                        ? AppColors.primaryGold
                        : Colors.grey,
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

  Widget _buildTierRow(
    String scoreRange,
    String duration,
    IconData icon, {
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.primaryGold.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? AppColors.primaryGold : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isHighlighted ? AppColors.primaryGold : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              scoreRange,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                color: isHighlighted ? AppColors.primaryGold : null,
              ),
            ),
          ),
          Text(
            duration,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCol(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.secondaryGold,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
