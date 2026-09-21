import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/gamification_service.dart';
import '../../../core/services/language_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/rank_shield_card.dart';

class ProgressView extends StatelessWidget {
  const ProgressView({super.key});

  @override
  Widget build(BuildContext context) {
    final gamification = GamificationService.to;
    final lang = LanguageService.to;
    final storage = Get.find<StorageService>();

    return Obx(() {
      final isBn = lang.isBangla;
      final currentStreak = gamification.currentStreak.value;
      final longestStreak = gamification.longestStreak.value;
      final currentXp = gamification.currentXp.value;
      final history = gamification.deedHistory;
      final totalDeeds = history.length > storage.getCompletedDeedsCount()
          ? history.length
          : storage.getCompletedDeedsCount();

      // Total time earned across history or storage
      int totalMinutes = storage.getUnlockedMinutesTotal();
      if (history.isNotEmpty) {
        final historyMins =
            history.fold<int>(0, (sum, item) => sum + item.durationMinutes);
        if (historyMins > totalMinutes) totalMinutes = historyMins;
      }

      final hours = totalMinutes ~/ 60;
      final mins = totalMinutes % 60;
      final timeStr = hours > 0
          ? (isBn ? '$hoursঘ $minsমি' : '${hours}h ${mins}m')
          : (isBn ? '$minsমি' : '${mins}m');

      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBn ? 'আপনার অগ্রগতি' : 'Your Progress',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isBn
                            ? 'আপনার আমল ও সচেতন ধারাবাহিকতা ট্র্যাক করুন'
                            : 'Track your streaks and mindful habits',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Iconsax.global,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => lang.toggleLanguage(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 1. Rank Shield Card
              const RankShieldCard(compact: true),
              const SizedBox(height: 20),

              // 2. Summary Row (5 Key Metrics)
              Text(
                lang.t('summary'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildSummaryCard(
                      icon: Icons.local_fire_department_rounded,
                      iconColor: const Color(0xFFFF9500),
                      label: lang.t('current_streak'),
                      value: isBn ? '$currentStreak দিন' : '$currentStreak days',
                    ),
                    const SizedBox(width: 10),
                    _buildSummaryCard(
                      icon: Iconsax.award,
                      iconColor: AppColors.primaryGold,
                      label: lang.t('longest_streak'),
                      value: isBn ? '$longestStreak দিন' : '$longestStreak days',
                    ),
                    const SizedBox(width: 10),
                    _buildSummaryCard(
                      icon: Iconsax.task_square,
                      iconColor: AppColors.brightGreen,
                      label: lang.t('total_deeds'),
                      value: '$totalDeeds',
                    ),
                    const SizedBox(width: 10),
                    _buildSummaryCard(
                      icon: Iconsax.star_1,
                      iconColor: const Color(0xFFFFD700),
                      label: lang.t('total_xp'),
                      value: '$currentXp XP',
                    ),
                    const SizedBox(width: 10),
                    _buildSummaryCard(
                      icon: Iconsax.timer_1,
                      iconColor: AppColors.brightGreen,
                      label: lang.t('total_time_earned'),
                      value: timeStr,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Weekly Activity: 7-Day Bar Chart
              _buildWeeklyBarChart(
                isBn: isBn,
                history: history,
                weeklyDays: gamification.weeklyCompletedDays,
              ),
              const SizedBox(height: 24),

              // 4. Deed History List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lang.t('deed_history'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (history.isNotEmpty)
                    Text(
                      '${history.length} ${isBn ? 'টি আমল' : 'entries'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (history.isEmpty)
                _buildEmptyHistoryState(isBn: isBn)
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.length > 20 ? 20 : history.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = history[index];
                    return _buildHistoryTile(item, isBn);
                  },
                ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      width: 135,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 7-DAY BAR CHART
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildWeeklyBarChart({
    required bool isBn,
    required List<DeedHistoryItem> history,
    required Set<int> weeklyDays,
  }) {
    // Days mapping: Sun (7) to Sat (6)
    final dayNamesEn = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final dayNamesBn = ['রবি', 'সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র', 'শনি'];
    final weekdayIds = [
      DateTime.sunday,
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
      DateTime.saturday,
    ];

    final now = DateTime.now();
    final todayWeekday = now.weekday;

    // Calculate deeds per day in this week
    final Map<int, int> counts = {};
    for (final id in weekdayIds) {
      counts[id] = 0;
    }

    for (final item in history) {
      final diff = now.difference(item.timestamp).inDays;
      if (diff <= 7) {
        final w = item.timestamp.weekday;
        counts[w] = (counts[w] ?? 0) + 1;
      }
    }

    // If history is small, fallback to weekly active days
    for (final active in weeklyDays) {
      if ((counts[active] ?? 0) == 0) {
        counts[active] = 1;
      }
    }

    int maxCount = counts.values.fold(0, (max, c) => c > max ? c : max);
    if (maxCount < 4) maxCount = 4;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Iconsax.chart_2,
                    size: 18,
                    color: AppColors.brightGreen,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isBn ? 'সাপ্তাহিক আমল' : 'Weekly Activity',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  isBn ? 'রবি – শনি' : 'Sun – Sat',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // 7 Bars
          SizedBox(
            height: 130,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final dayId = weekdayIds[i];
                final count = counts[dayId] ?? 0;
                final isToday = dayId == todayWeekday;
                final barRatio = (count / maxCount).clamp(0.08, 1.0);
                final barHeight = 76.0 * barRatio;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Count number
                    Text(
                      count > 0 ? '$count' : '',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isToday
                            ? AppColors.brightGreen
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Vertical Bar
                    Container(
                      width: 22,
                      height: barHeight,
                      decoration: BoxDecoration(
                        gradient: count > 0
                            ? (isToday
                                ? const LinearGradient(
                                    colors: [
                                      AppColors.brightGreen,
                                      Color(0xFF1B6B45),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  )
                                : LinearGradient(
                                    colors: [
                                      AppColors.primaryGreen.withValues(
                                        alpha: 0.6,
                                      ),
                                      AppColors.primaryGreen.withValues(
                                        alpha: 0.25,
                                      ),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ))
                            : null,
                        color: count == 0
                            ? Colors.white.withValues(alpha: 0.05)
                            : null,
                        borderRadius: BorderRadius.circular(6),
                        border: isToday
                            ? Border.all(
                                color: AppColors.brightGreen,
                                width: 1.5,
                              )
                            : null,
                        boxShadow: isToday && count > 0
                            ? [
                                BoxShadow(
                                  color: AppColors.brightGreen.withValues(
                                    alpha: 0.35,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Day Label
                    Text(
                      isBn ? dayNamesBn[i] : dayNamesEn[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                        color: isToday
                            ? AppColors.brightGreen
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DEED HISTORY TILE
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHistoryTile(DeedHistoryItem item, bool isBn) {
    final timeFormatted = DateFormat('MMM d, hh:mm a').format(item.timestamp);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.brightGreen.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.brightGreen.withValues(alpha: 0.3),
              ),
            ),
            child: const Center(
              child: Icon(
                Iconsax.tick_circle,
                size: 22,
                color: AppColors.brightGreen,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Deed Name + Timestamp
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.deedName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeFormatted,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // XP Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primaryGold.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Iconsax.star_1,
                  size: 12,
                  color: AppColors.primaryGold,
                ),
                const SizedBox(width: 4),
                Text(
                  '+${item.xpEarned} XP',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Time Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.brightGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.brightGreen.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              '+${item.durationMinutes}m',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.brightGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistoryState({required bool isBn}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Icon(
                Iconsax.book_saved,
                size: 28,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isBn ? 'এখনও কোনো আমল সম্পন্ন হয়নি' : 'No deeds completed yet',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isBn
                ? 'একটি নেক আমল সম্পন্ন করে আপনার প্রথম এক্সপি ও আনলক সময় অর্জন করুন'
                : 'Complete a good deed to earn your first XP and unlock time',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => Get.toNamed('/unlock'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brightGreen,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Iconsax.magic_star, size: 16),
            label: Text(
              isBn ? 'একটি আমল করুন' : 'Do a Good Deed',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
