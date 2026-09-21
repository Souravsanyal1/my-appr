import 'package:flutter_test/flutter_test.dart';
import 'package:focus_deen/features/dhikr/models/dhikr_model.dart';
import 'package:focus_deen/features/focus_session/models/focus_session_model.dart';
import 'package:focus_deen/features/learning/models/learning_lesson_model.dart';
import 'package:focus_deen/features/learning/repositories/learning_repository.dart';
import 'package:focus_deen/features/limits/models/app_limit_model.dart';
import 'package:focus_deen/features/schedule/models/schedule_model.dart';
import 'package:focus_deen/features/statistics/models/achievement_model.dart';
import 'package:focus_deen/features/statistics/models/daily_stats_model.dart';
import 'package:focus_deen/features/unlock/models/unlock_session_model.dart';
import 'package:focus_deen/features/unlock/services/pronunciation_analyzer.dart';

void main() {
  group('AppLimitModel Tests', () {
    test('Serialize and deserialize AppLimitModel', () {
      const limit = AppLimitModel(
        packageName: 'com.instagram.android',
        appName: 'Instagram',
        dailyLimitMinutes: 30,
        warningThresholdMinutes: 5,
        mode: 'block',
        isEnabled: true,
      );

      final map = limit.toMap();
      final restored = AppLimitModel.fromMap(map);

      expect(restored.packageName, 'com.instagram.android');
      expect(restored.appName, 'Instagram');
      expect(restored.dailyLimitMinutes, 30);
      expect(restored.warningThresholdMinutes, 5);
      expect(restored.mode, 'block');
      expect(restored.isEnabled, true);
    });

    test('CopyWith creates expected instance', () {
      const limit = AppLimitModel(
        packageName: 'com.zhiliaoapp.musically',
        appName: 'TikTok',
        dailyLimitMinutes: 20,
      );

      final updated = limit.copyWith(dailyLimitMinutes: 25, isEnabled: false);
      expect(updated.dailyLimitMinutes, 25);
      expect(updated.isEnabled, false);
      expect(updated.appName, 'TikTok');
    });
  });

  group('UnlockSessionModel Tests', () {
    test('Calculates expiration properly', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final activeSession = UnlockSessionModel(
        packageName: 'com.instagram.android',
        appName: 'Instagram',
        durationMinutes: 10,
        expiresAtTimestamp: now + 600000,
      );

      expect(activeSession.isExpired, false);
      expect(activeSession.remainingSeconds, greaterThan(0));

      final expiredSession = UnlockSessionModel(
        packageName: 'com.instagram.android',
        appName: 'Instagram',
        durationMinutes: 5,
        expiresAtTimestamp: now - 1000,
      );

      expect(expiredSession.isExpired, true);
      expect(expiredSession.remainingSeconds, 0);
    });
  });

  group('FocusSessionModel Tests', () {
    test('Serialize and deserialize FocusSessionModel', () {
      final session = FocusSessionModel(
        id: 'session-1',
        startTime: DateTime(2026, 9, 20, 10, 0),
        durationMinutes: 25,
        isCompleted: true,
      );

      final map = session.toMap();
      final restored = FocusSessionModel.fromMap(map);

      expect(restored.id, 'session-1');
      expect(restored.durationMinutes, 25);
      expect(restored.isCompleted, true);
    });
  });

  group('DhikrModel Tests', () {
    test('Serialize and deserialize DhikrModel', () {
      const dhikr = DhikrModel(
        id: 'subhanallah',
        arabic: 'سُبْحَانَ اللَّهِ',
        transliteration: 'SubhanAllah',
        translation: 'Glory be to Allah',
        targetCount: 33,
        virtue: 'Plants a palm tree in Paradise.',
      );

      final map = dhikr.toMap();
      final restored = DhikrModel.fromMap(map);

      expect(restored.transliteration, 'SubhanAllah');
      expect(restored.targetCount, 33);
    });
  });

  group('Islamic Learning Repository Tests', () {
    test('Contains all 4 initial verified categories', () {
      final lessons = LearningRepository.allLessons;
      expect(lessons, isNotEmpty);

      final categories = lessons.map((l) => l.category).toSet();
      expect(categories.contains(LearningCategory.dailyDhikr), true);
      expect(categories.contains(LearningCategory.dailyDuas), true);
      expect(categories.contains(LearningCategory.salahLearning), true);
      expect(categories.contains(LearningCategory.shortSurahs), true);
    });

    test('All lessons have non-empty Arabic text and references', () {
      for (final lesson in LearningRepository.allLessons) {
        expect(lesson.arabicText.trim(), isNotEmpty);
        expect(lesson.transliteration.trim(), isNotEmpty);
        expect(lesson.translation.trim(), isNotEmpty);
        expect(lesson.sourceReference.trim(), isNotEmpty);
      }
    });

    test('LearningLessonModel serialization', () {
      final sample = LearningRepository.allLessons.first;
      final map = sample.toMap();
      final restored = LearningLessonModel.fromMap(map);

      expect(restored.id, sample.id);
      expect(restored.category, sample.category);
      expect(restored.arabicText, sample.arabicText);
    });
  });

  group('PronunciationAnalyzer Tests', () {
    test('Short recitation generates failure result with educational guidance', () async {
      final analyzer = LocalPronunciationAnalyzer();
      final result = await analyzer.analyze(
        expectedArabic: 'سُبْحَانَ اللَّهِ',
        expectedTransliteration: 'Subḥān Allāh',
        durationSeconds: 1,
        minDurationSeconds: 4,
        unlockThreshold: 80,
      );

      expect(result.isPassing, false);
      expect(result.earnedUnlockMinutes, 0);
      expect(result.disclaimer, isNotEmpty);
    });

    test('Sufficient duration generates passing result above threshold', () async {
      final analyzer = LocalPronunciationAnalyzer();
      final result = await analyzer.analyze(
        expectedArabic: 'سُبْحَانَ اللَّهِ',
        expectedTransliteration: 'Subḥān Allāh',
        durationSeconds: 6,
        minDurationSeconds: 4,
        unlockThreshold: 75,
      );

      expect(result.isPassing, true);
      expect(result.overallScore, greaterThanOrEqualTo(75));
      expect(result.earnedUnlockMinutes, greaterThanOrEqualTo(5));
      expect(result.wordRecognitionScore, greaterThan(0));
      expect(result.timingScore, greaterThan(0));
      expect(result.audioSimilarityScore, greaterThan(0));
    });
  });

  group('ScheduleModel Tests', () {
    test('Evaluates normal day schedule matching correctly', () {
      const schedule = ScheduleModel(
        id: 'study',
        name: 'Study Time',
        startHour: 14,
        startMinute: 0,
        endHour: 17,
        endMinute: 0,
        repeatType: ScheduleRepeatType.daily,
        blockedPackages: ['com.instagram.android'],
        isEnabled: true,
      );

      // 3:30 PM should be active
      final activeTime = DateTime(2026, 9, 21, 15, 30);
      expect(schedule.isTimeActive(activeTime), true);

      // 1:30 PM should be inactive
      final inactiveTime = DateTime(2026, 9, 21, 13, 30);
      expect(schedule.isTimeActive(inactiveTime), false);

      // 5:30 PM should be inactive
      final afterTime = DateTime(2026, 9, 21, 17, 30);
      expect(schedule.isTimeActive(afterTime), false);
    });

    test('Evaluates overnight schedule matching correctly', () {
      const nightSchedule = ScheduleModel(
        id: 'night',
        name: 'Night Mode',
        startHour: 23,
        startMinute: 0,
        endHour: 7,
        endMinute: 0,
        repeatType: ScheduleRepeatType.daily,
        blockedPackages: ['com.zhiliaoapp.musically'],
        isEnabled: true,
      );

      // 11:30 PM should be active
      final lateNight = DateTime(2026, 9, 21, 23, 30);
      expect(nightSchedule.isTimeActive(lateNight), true);

      // 3:00 AM should be active
      final earlyMorning = DateTime(2026, 9, 21, 3, 0);
      expect(nightSchedule.isTimeActive(earlyMorning), true);

      // 10:00 AM should be inactive
      final daytime = DateTime(2026, 9, 21, 10, 0);
      expect(nightSchedule.isTimeActive(daytime), false);
    });
  });

  group('DailyStats & Achievement Tests', () {
    test('DailyStatsModel serialization', () {
      const stats = DailyStatsModel(
        dateString: '2026-09-21',
        totalScreenTimeMinutes: 134,
        socialMediaMinutes: 84,
        focusMinutes: 50,
        blockedAttempts: 14,
        lessonsCompleted: 3,
        recitationsCount: 8,
        averagePracticeScore: 84,
      );

      final map = stats.toMap();
      final restored = DailyStatsModel.fromMap(map);

      expect(restored.totalScreenTimeMinutes, 134);
      expect(restored.blockedAttempts, 14);
      expect(restored.averagePracticeScore, 84);
    });

    test('AchievementModel progress calculation', () {
      const achievement = AchievementModel(
        id: 'streak_7',
        title: '7 Day Streak',
        description: 'Maintain 7 consecutive days',
        iconName: 'local_fire_department',
        targetValue: 7,
        currentValue: 7,
        isUnlocked: true,
      );

      expect(achievement.progressPercentage, 1.0);
      expect(achievement.isUnlocked, true);

      const inProgress = AchievementModel(
        id: 'streak_30',
        title: '30 Day Streak',
        description: 'Maintain 30 consecutive days',
        iconName: 'military_tech',
        targetValue: 30,
        currentValue: 15,
        isUnlocked: false,
      );

      expect(inProgress.progressPercentage, 0.5);
      expect(inProgress.isUnlocked, false);
    });
  });
}
