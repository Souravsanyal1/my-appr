import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/language_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/progress_ring.dart';

class ProgressView extends StatelessWidget {
  const ProgressView({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<StorageService>();
    final languageService = LanguageService.to;

    return Obx(() {
      final isBn = languageService.isBangla;
      final streak = storage.getStreakDays();
      final activeDays = storage.getWeeklyActiveDays();
      final totalDeeds = storage.getTotalDeedsCount();
      final completedDeeds = storage.getCompletedDeedsCount();
      final avgScore = storage.getAverageScore();
      final unlockedMinutes = storage.getUnlockedMinutesTotal();

      final hours = unlockedMinutes ~/ 60;
      final mins = unlockedMinutes % 60;
      final timeStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';
      final scoreStr = avgScore > 0 ? '$avgScore%' : '0%';

      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isBn ? 'আপনার অগ্রগতি' : 'Your Progress',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isBn
                    ? 'আপনার আমল ও সচেতন ব্যবহারের ধারাবাহিকতা ট্র্যাক করুন।'
                    : 'Track your streaks and mindful habits.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Streak Card
              AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                child: Column(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 36)),
                    const SizedBox(height: 8),
                    Text(
                      '$streak',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      isBn ? 'দিনের ধারাবাহিকতা' : 'DAY STREAK',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: AppColors.brightGreen,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Weekly Calendar Days Row (Mon..Sun: 1..7)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDayColumn('M', activeDays.contains(1)),
                        _buildDayColumn('T', activeDays.contains(2)),
                        _buildDayColumn('W', activeDays.contains(3)),
                        _buildDayColumn('T', activeDays.contains(4)),
                        _buildDayColumn('F', activeDays.contains(5)),
                        _buildDayColumn('S', activeDays.contains(6)),
                        _buildDayColumn('S', activeDays.contains(7)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Statistics Overview
              Text(
                isBn ? 'পরিসংখ্যান' : 'Statistics',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // 4 Stats Grid Cards with Real Data
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isBn ? 'মোট আমল' : 'Total Deeds',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$totalDeeds',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isBn ? 'সম্পন্ন' : 'Completed',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$completedDeeds',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.brightGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isBn ? 'গড় স্কোর' : 'Average Score',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            scoreStr,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.brightGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isBn ? 'আনলক করা সময়' : 'Unlocked Time',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            timeStr,
                            style: const TextStyle(
                              fontSize: 20,
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildDayColumn(String day, bool isDone) {
    return Column(
      children: [
        Text(
          day,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isDone ? AppColors.primaryGreen : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDone ? AppColors.primaryGreen : AppColors.border,
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 16, color: Colors.black)
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}
