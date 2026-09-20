import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:focus_deen/core/constants/app_colors.dart';
import 'package:focus_deen/features/focus_session/controllers/focus_session_controller.dart';

class FocusSessionScreen extends StatelessWidget {
  const FocusSessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FocusSessionController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Islamic Focus Session'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // Top session type indicator
              Obx(() => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: (controller.isBreak.value ? AppColors.emerald : AppColors.primaryGold)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: controller.isBreak.value ? AppColors.emerald : AppColors.primaryGold,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          controller.isBreak.value ? Icons.spa : Icons.self_improvement,
                          size: 18,
                          color: controller.isBreak.value ? AppColors.emerald : AppColors.primaryGold,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          controller.isBreak.value ? 'Sunnah Reflection Break' : 'Deep Barakah Work',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: controller.isBreak.value ? AppColors.emerald : AppColors.primaryGold,
                          ),
                        ),
                      ],
                    ),
                  )),
              const Spacer(),

              // Circular Countdown Timer
              Obx(() {
                final progress = controller.progress;
                final timeText = controller.formattedTime;
                final isBreak = controller.isBreak.value;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 240,
                      height: 240,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 12,
                        backgroundColor: isDark ? Colors.white12 : Colors.black12,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isBreak ? AppColors.emerald : AppColors.primaryGold,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeText,
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isBreak ? 'Breathe & Reflect' : 'Remaining',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }),
              const Spacer(),

              // Duration selector pills (when not running)
              Obx(() {
                if (controller.isRunning.value || controller.isBreak.value) {
                  return const SizedBox.shrink();
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [15, 25, 45, 60].map((mins) {
                    final isSelected = controller.selectedDurationMinutes.value == mins;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: ChoiceChip(
                        label: Text('${mins}m'),
                        selected: isSelected,
                        selectedColor: AppColors.primaryGold.withValues(alpha: 0.2),
                        onSelected: (_) => controller.setDuration(mins),
                      ),
                    );
                  }).toList(),
                );
              }),
              const SizedBox(height: 16),

              // Mindful Reflection Box
              Obx(() {
                final reminder = controller.mindfulReminders[controller.currentReminderIndex.value];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                    ),
                  ),
                  child: Text(
                    reminder,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                      color: isDark ? AppColors.primaryGoldLight : Colors.brown.shade800,
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),

              // Controls
              Obx(() {
                final isRunning = controller.isRunning.value;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      iconSize: 28,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Reset',
                      onPressed: controller.resetSession,
                    ),
                    const SizedBox(width: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isRunning ? AppColors.warning : AppColors.primaryGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: isRunning ? controller.pauseSession : controller.startSession,
                      child: Row(
                        children: [
                          Icon(isRunning ? Icons.pause : Icons.play_arrow, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            isRunning ? 'Pause' : 'Begin Focus',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    const SizedBox(width: 28), // balance reset button
                  ],
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
