import 'package:flutter_test/flutter_test.dart';
import 'package:focus_deen/features/dhikr/models/dhikr_model.dart';
import 'package:focus_deen/features/focus_session/models/focus_session_model.dart';
import 'package:focus_deen/features/limits/models/app_limit_model.dart';
import 'package:focus_deen/features/unlock/models/unlock_session_model.dart';
import 'package:focus_deen/features/unlock/services/recitation_scoring_service.dart';

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

  group('RecitationScoringService Tests', () {
    test('Short recitation fails threshold', () {
      final service = RecitationScoringService();
      final verse = RecitationScoringService.challengeVerses.first;

      final result = service.evaluateRecitation(
        durationSeconds: 1, // Below minimum
        verse: verse,
      );

      expect(result.isPassing, false);
      expect(result.earnedUnlockMinutes, 0);
    });

    test('Proper recitation passes with earned minutes', () {
      final service = RecitationScoringService();
      final verse = RecitationScoringService.challengeVerses.first;

      final result = service.evaluateRecitation(
        durationSeconds: verse.minRecitationSeconds + 3,
        verse: verse,
      );

      expect(result.isPassing, true);
      expect(result.scorePercentage, greaterThanOrEqualTo(70));
      expect(result.earnedUnlockMinutes, greaterThanOrEqualTo(5));
    });
  });
}
