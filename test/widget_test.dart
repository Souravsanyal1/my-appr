import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_deen/core/blocker/app_blocker.dart';
import 'package:focus_deen/core/blocker/blocker_models.dart';
import 'package:focus_deen/core/responsive/responsive_layout.dart';
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
import 'package:get/get.dart' hide ScreenType;
import 'package:focus_deen/core/services/language_service.dart';
import 'package:focus_deen/features/onboarding/views/welcome_screen.dart';

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
    test(
      'Short recitation generates failure result with educational guidance',
      () async {
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
      },
    );

    test(
      'Sufficient duration generates passing result above threshold',
      () async {
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
      },
    );
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

  group('Bengali Pronunciation & Localization Tests', () {
    test(
      'All lessons contain authentic Bengali pronunciation, title and translation',
      () {
        for (final lesson in LearningRepository.allLessons) {
          expect(lesson.banglaTitle, isNotNull);
          expect(lesson.banglaTitle!.trim(), isNotEmpty);
          expect(lesson.banglaPronunciation, isNotNull);
          expect(lesson.banglaPronunciation!.trim(), isNotEmpty);
          expect(lesson.banglaTranslation, isNotNull);
          expect(lesson.banglaTranslation!.trim(), isNotEmpty);

          // Verify localization getters
          expect(lesson.getTitle(true), lesson.banglaTitle);
          expect(lesson.getTitle(false), lesson.title);
          expect(lesson.getPronunciation(true), lesson.banglaPronunciation);
          expect(lesson.getPronunciation(false), lesson.transliteration);
          expect(lesson.getTranslation(true), lesson.banglaTranslation);
          expect(lesson.getTranslation(false), lesson.translation);
        }
      },
    );

    test('Category localized names for Bengali and English', () {
      expect(LearningCategory.dailyDhikr.getLocalizedName(true), 'দৈনিক যিকির');
      expect(
        LearningCategory.dailyDhikr.getLocalizedName(false),
        'Daily Dhikr',
      );
      expect(LearningCategory.dailyDuas.getLocalizedName(true), 'দৈনিক দোয়া');
      expect(
        LearningCategory.salahLearning.getLocalizedName(true),
        'নামাজ শিক্ষা',
      );
      expect(
        LearningCategory.shortSurahs.getLocalizedName(true),
        'ছোট সূরাসমূহ',
      );
    });
  });

  group('Responsive & Cross-Device Layout Tests', () {
    testWidgets('ResponsiveContext categorizes screen breakpoints accurately', (
      tester,
    ) async {
      // 1. Test Compact breakpoint (< 600)
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late ScreenType detectedScreen;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              detectedScreen = ctx.screenType;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(detectedScreen, ScreenType.compact);

      // 2. Test Medium breakpoint (600 - 839)
      tester.view.physicalSize = const Size(720, 1000);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              detectedScreen = ctx.screenType;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(detectedScreen, ScreenType.medium);

      // 3. Test Expanded/Tablet breakpoint (>= 840)
      tester.view.physicalSize = const Size(1024, 768);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              detectedScreen = ctx.screenType;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(detectedScreen, ScreenType.expanded);
    });

    testWidgets(
      'ResponsiveScaffoldBody renders cleanly without overflow on compact 320x568 screen',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResponsiveScaffoldBody(
                child: ListView(
                  children: const [
                    Text('Header Title', style: TextStyle(fontSize: 24)),
                    SizedBox(height: 16),
                    Text('DeenFlow mindful screen-time and recitation coach.'),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: null,
                      child: Text('Start Session'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Header Title'), findsOneWidget);
        expect(find.text('Start Session'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'ResponsiveScaffoldBody constrains content width to 700dp max on tablet',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResponsiveScaffoldBody(
                child: Container(
                  key: const ValueKey('tablet_container'),
                  height: 200,
                  color: Colors.green,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final box = tester.renderObject<RenderBox>(
          find.byKey(const ValueKey('tablet_container')),
        );
        // On 1200dp width screen, the content is centered and constrained to max 700dp (minus horizontal padding)
        expect(box.size.width, lessThanOrEqualTo(700.0));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'ResponsiveScaffoldBody handles 200% text scale without exceptions',
      (tester) async {
        tester.view.physicalSize = const Size(375, 667);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(375, 667),
                textScaler: TextScaler.linear(2.0),
              ),
              child: Scaffold(
                body: ResponsiveScaffoldBody(
                  child: ListView(
                    children: const [
                      Text('Large Scaled Title'),
                      Text('Educational recitation and mindfulness content'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Large Scaled Title'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'WelcomeScreen renders without overflow on compact 360x640 screen in Bengali',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // Put LanguageService
        final lang = Get.put(LanguageService());
        lang.currentLanguage.value = 'bn';

        await tester.pumpWidget(const GetMaterialApp(home: WelcomeScreen()));
        await tester.pumpAndSettle();

        expect(find.text('বিরতি ও আমল'), findsOneWidget);
        expect(find.text('শুরু করা যাক'), findsOneWidget);
        expect(tester.takeException(), isNull);

        Get.delete<LanguageService>();
      },
    );

    testWidgets(
      'WelcomeScreen renders without overflow on ultra-compact 320x568 screen in English',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final lang = Get.put(LanguageService());
        lang.currentLanguage.value = 'en';

        await tester.pumpWidget(const GetMaterialApp(home: WelcomeScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Pause & Recite'), findsOneWidget);
        expect(find.text("Let's get started"), findsOneWidget);
        expect(tester.takeException(), isNull);

        Get.delete<LanguageService>();
      },
    );
  });

  group('AppBlocker & Timed Unlock Tests', () {
    test('FakeAppBlocker correctly manages protected apps and timed unlocks', () async {
      final fakeBlocker = FakeAppBlocker();

      // Verify installed apps retrieval
      final apps = await fakeBlocker.getInstalledApps();
      expect(apps.length, 2);
      expect(apps.first.name, 'TikTok');

      // Set protected apps
      await fakeBlocker.setProtectedApps(['com.zhiliaoapp.musically']);
      expect(fakeBlocker.protectedApps.contains('com.zhiliaoapp.musically'), true);

      // Unlock for 15 minutes
      final beforeUnlock = DateTime.now();
      await fakeBlocker.unlock('com.zhiliaoapp.musically', const Duration(minutes: 15));

      final activeUnlocks = await fakeBlocker.getUnlockedUntil();
      expect(activeUnlocks.containsKey('com.zhiliaoapp.musically'), true);
      expect(
        activeUnlocks['com.zhiliaoapp.musically']!.isAfter(beforeUnlock.add(const Duration(minutes: 14))),
        true,
      );

      // Lock now
      await fakeBlocker.lockNow('com.zhiliaoapp.musically');
      final afterRelock = await fakeBlocker.getUnlockedUntil();
      expect(afterRelock.containsKey('com.zhiliaoapp.musically'), false);

      fakeBlocker.dispose();
    });

    test('BlockerEvent stream broadcasts unlock and relock events', () async {
      final fakeBlocker = FakeAppBlocker();
      final events = <BlockerEvent>[];

      final sub = fakeBlocker.events.listen(events.add);

      await fakeBlocker.unlock('com.instagram.android', const Duration(minutes: 30));
      await fakeBlocker.lockNow('com.instagram.android');

      await Future.delayed(const Duration(milliseconds: 50));
      expect(events.length, 2);
      expect(events[0].type, BlockerEventType.unlocked);
      expect(events[1].type, BlockerEventType.relocked);

      await sub.cancel();
      fakeBlocker.dispose();
    });
  });
}

class FakeAppBlocker implements AppBlocker {
  final List<String> protectedApps = [];
  final Map<String, DateTime> unlockedUntil = {};
  PermissionStatusSet permissions = const PermissionStatusSet(
    accessibilityGranted: true,
    usageStatsGranted: true,
    overlayGranted: true,
    notificationsGranted: true,
    exactAlarmsGranted: true,
    batteryOptimizationIgnored: true,
  );
  final StreamController<BlockerEvent> _controller =
      StreamController<BlockerEvent>.broadcast();

  @override
  Stream<BlockerEvent> get events => _controller.stream;

  @override
  Future<List<InstalledAppInfo>> getInstalledApps() async => const [
        InstalledAppInfo(
            id: 'com.zhiliaoapp.musically', name: 'TikTok', category: 'Social'),
        InstalledAppInfo(
            id: 'com.instagram.android', name: 'Instagram', category: 'Social'),
      ];

  @override
  Future<void> setProtectedApps(List<String> ids) async {
    protectedApps.clear();
    protectedApps.addAll(ids);
  }

  @override
  Future<void> unlock(String id, Duration duration) async {
    unlockedUntil[id] = DateTime.now().add(duration);
    _controller.add(
      BlockerEvent(
        type: BlockerEventType.unlocked,
        packageId: id,
        appName: id,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> lockNow(String id) async {
    unlockedUntil.remove(id);
    _controller.add(
      BlockerEvent(
        type: BlockerEventType.relocked,
        packageId: id,
        appName: id,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  Future<Map<String, DateTime>> getUnlockedUntil() async =>
      Map.unmodifiable(unlockedUntil);

  @override
  Future<PermissionStatusSet> checkPermissions() async => permissions;

  @override
  Future<void> openPermissionSettings(BlockerPermission p) async {}

  @override
  void dispose() {
    _controller.close();
  }
}
