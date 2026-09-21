import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/services/storage_service.dart';
import '../models/achievement_model.dart';
import '../models/daily_stats_model.dart';

class StatisticsController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();

  final Rx<DailyStatsModel> todayStats = const DailyStatsModel(dateString: '').obs;
  final RxList<DailyStatsModel> weeklyStats = <DailyStatsModel>[].obs;
  final RxInt focusScore = 78.obs;
  final RxInt learningStreakDays = 7.obs;
  final RxList<AchievementModel> achievements = <AchievementModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadStats();
    });
  }

  void loadStats() {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Completed lessons count
    final completedLessons = (_storageService.read<List<dynamic>>('completed_lesson_ids') ?? []).length;
    final totalRecitations = _storageService.read<int>('total_recitations') ?? 8;
    final totalFocusSessions = _storageService.read<int>('total_focus_sessions') ?? 5;
    final blockedAttempts = _storageService.read<int>('blocked_attempts_today') ?? 14;

    // Build today stats
    todayStats.value = DailyStatsModel(
      dateString: todayStr,
      totalScreenTimeMinutes: 134, // 2h 14m
      socialMediaMinutes: 84,     // 1h 24m
      focusMinutes: 50,          // 2 Pomodoro sessions
      blockedAttempts: blockedAttempts,
      lessonsCompleted: completedLessons > 0 ? completedLessons : 3,
      recitationsCount: totalRecitations,
      averagePracticeScore: 84,
    );

    // Build 7-day weekly history
    final history = <DailyStatsModel>[];
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final dStr = DateFormat('yyyy-MM-dd').format(d);
      history.add(DailyStatsModel(
        dateString: dStr,
        totalScreenTimeMinutes: 120 + (i * 12) % 45,
        socialMediaMinutes: 60 + (i * 9) % 35,
        focusMinutes: 25 * ((i % 3) + 1),
        blockedAttempts: 8 + (i * 3),
        lessonsCompleted: 2 + (i % 2),
        recitationsCount: 4 + (i % 3),
        averagePracticeScore: 80 + (i % 8),
      ));
    }
    weeklyStats.assignAll(history);

    // Calculate Focus Score
    calculateFocusScore();

    // Load achievements
    _loadAchievements(
      lessons: completedLessons,
      recitations: totalRecitations,
      streak: learningStreakDays.value,
      focusSessions: totalFocusSessions,
    );
  }

  void calculateFocusScore() {
    // Motivational metric derived from limits, focus sessions, lessons, and recitation
    int score = 60;
    if (todayStats.value.lessonsCompleted >= 2) score += 15;
    if (todayStats.value.focusMinutes >= 25) score += 15;
    if (todayStats.value.averagePracticeScore >= 80) score += 10;
    focusScore.value = score.clamp(0, 100);
  }

  void recordBlockedAttempt() {
    final current = todayStats.value.blockedAttempts + 1;
    _storageService.write('blocked_attempts_today', current);
    todayStats.value = todayStats.value.copyWith(blockedAttempts: current);
  }

  void _loadAchievements({
    required int lessons,
    required int recitations,
    required int streak,
    required int focusSessions,
  }) {
    achievements.assignAll([
      AchievementModel(
        id: 'first_lesson',
        title: 'First Lesson',
        description: 'Complete your first Islamic study lesson',
        iconName: 'menu_book',
        targetValue: 1,
        currentValue: lessons,
        isUnlocked: lessons >= 1,
      ),
      AchievementModel(
        id: 'recitations_10',
        title: '10 Recitations',
        description: 'Recite verses and check pronunciation 10 times',
        iconName: 'mic',
        targetValue: 10,
        currentValue: recitations,
        isUnlocked: recitations >= 10,
      ),
      AchievementModel(
        id: 'recitations_100',
        title: '100 Recitations',
        description: 'Master 100 Quranic recitations & Adhkar practices',
        iconName: 'verified',
        targetValue: 100,
        currentValue: recitations,
        isUnlocked: recitations >= 100,
      ),
      AchievementModel(
        id: 'streak_7',
        title: '7 Day Streak',
        description: 'Maintain 7 consecutive days of Islamic learning',
        iconName: 'local_fire_department',
        targetValue: 7,
        currentValue: streak,
        isUnlocked: streak >= 7,
      ),
      AchievementModel(
        id: 'streak_30',
        title: '30 Day Streak',
        description: 'Achieve a full 30-day streak of mindful phone use',
        iconName: 'military_tech',
        targetValue: 30,
        currentValue: streak,
        isUnlocked: streak >= 30,
      ),
      AchievementModel(
        id: 'first_focus',
        title: 'First Focus Session',
        description: 'Complete a full 25-minute Islamic Pomodoro session',
        iconName: 'self_improvement',
        targetValue: 1,
        currentValue: focusSessions,
        isUnlocked: focusSessions >= 1,
      ),
      AchievementModel(
        id: 'focus_10',
        title: '10 Focus Sessions',
        description: 'Complete 10 focused reflection and deep work sessions',
        iconName: 'hourglass_top',
        targetValue: 10,
        currentValue: focusSessions,
        isUnlocked: focusSessions >= 10,
      ),
    ]);
  }
}
