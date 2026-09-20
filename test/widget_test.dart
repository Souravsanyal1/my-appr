import 'package:flutter_test/flutter_test.dart';
import 'package:focus_deen/features/limits/models/app_limit_model.dart';
import 'package:focus_deen/features/unlock/models/unlock_session_model.dart';

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
}
