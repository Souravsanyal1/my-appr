import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../features/limits/models/app_limit_model.dart';
import '../../features/unlock/models/unlock_session_model.dart';
import 'native_bridge_service.dart';

class StorageService extends GetxService {
  late final GetStorage _box;

  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyLimits = 'app_limits';
  static const String keyMonitoredPackages = 'monitored_packages';
  static const String keyUnlockSessions = 'unlock_sessions';
  static const String keyStrictMode = 'strict_mode';
  static const String keyPinHash = 'security_pin_hash';

  Future<StorageService> init() async {
    await GetStorage.init();
    _box = GetStorage();
    return this;
  }

  // Onboarding
  bool isOnboardingComplete() {
    return _box.read<bool>(keyOnboardingComplete) ?? false;
  }

  void setOnboardingComplete(bool complete) {
    _box.write(keyOnboardingComplete, complete);
  }

  // Limits
  List<AppLimitModel> getLimits() {
    final raw = _box.read<List<dynamic>>(keyLimits);
    if (raw == null) return [];
    return raw
        .map((e) => AppLimitModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  void saveLimits(List<AppLimitModel> limits) {
    final raw = limits.map((e) => e.toMap()).toList();
    _box.write(keyLimits, raw);
  }

  // Monitored Packages
  List<String> getMonitoredPackages() {
    final raw = _box.read<List<dynamic>>(keyMonitoredPackages);
    if (raw == null || raw.isEmpty) {
      return [
        'com.zhiliaoapp.musically',
        'com.ss.android.ugc.trill',
        'com.instagram.android',
        'com.facebook.katana',
        'com.google.android.youtube',
        'com.snapchat.android',
      ];
    }
    return raw.map((e) => e.toString()).toList();
  }

  void saveMonitoredPackages(List<String> packages) {
    _box.write(keyMonitoredPackages, packages);
    try {
      if (Get.isRegistered<NativeBridgeService>()) {
        Get.find<NativeBridgeService>().syncMonitoredPackages(packages);
      }
    } catch (e) {
      // Ignored if service not yet initialized
    }
  }

  // Temporary Unlock Sessions
  List<UnlockSessionModel> getUnlockSessions() {
    final raw = _box.read<List<dynamic>>(keyUnlockSessions);
    if (raw == null) return [];
    final now = DateTime.now().millisecondsSinceEpoch;
    final sessions = raw
        .map(
          (e) =>
              UnlockSessionModel.fromMap(Map<String, dynamic>.from(e as Map)),
        )
        .where((s) => s.expiresAtTimestamp > now) // filter out expired
        .toList();
    return sessions;
  }

  void saveUnlockSessions(List<UnlockSessionModel> sessions) {
    final raw = sessions.map((e) => e.toMap()).toList();
    _box.write(keyUnlockSessions, raw);
  }

  // Strict Mode & Security PIN
  bool isStrictModeEnabled() {
    return _box.read<bool>(keyStrictMode) ?? false;
  }

  void setStrictModeEnabled(bool enabled) {
    _box.write(keyStrictMode, enabled);
  }

  String? getPinHash() {
    return _box.read<String>(keyPinHash);
  }

  void savePinHash(String hash) {
    _box.write(keyPinHash, hash);
  }

  bool hasPinSet() {
    final hash = getPinHash();
    return hash != null && hash.isNotEmpty;
  }

  // User Profile
  String getUserName() => _box.read<String>('user_name') ?? 'Sourav Sanyal';
  void setUserName(String name) => _box.write('user_name', name);

  // Daily Goal (in minutes)
  int getDailyGoalMinutes() => _box.read<int>('daily_goal_minutes') ?? 30;
  void setDailyGoalMinutes(int mins) => _box.write('daily_goal_minutes', mins);

  // Minimum Passing Score
  int getMinimumPassingScore() =>
      _box.read<int>('unlock_score_threshold') ?? 80;
  void setMinimumPassingScore(int score) =>
      _box.write('unlock_score_threshold', score);

  // Default Unlock Duration (in minutes)
  int getDefaultUnlockDurationMinutes() =>
      _box.read<int>('default_unlock_duration_minutes') ?? 30;
  void setDefaultUnlockDurationMinutes(int mins) =>
      _box.write('default_unlock_duration_minutes', mins);

  // Real Statistics & Tracking
  int getTotalDeedsCount() => _box.read<int>('total_deeds_count') ?? 0;
  int getCompletedDeedsCount() =>
      _box.read<int>('completed_deeds_count') ?? 0;
  int getUnlockedMinutesTotal() =>
      _box.read<int>('unlocked_minutes_total') ?? 0;

  int getAverageScore() {
    final List<dynamic>? scores =
        _box.read<List<dynamic>>('pronunciation_scores');
    if (scores == null || scores.isEmpty) return 0;
    final valid = scores.map((e) => (e as num).toInt()).toList();
    if (valid.isEmpty) return 0;
    final sum = valid.fold<int>(0, (prev, element) => prev + element);
    return (sum / valid.length).round();
  }

  int getStreakDays() {
    _checkStreak();
    return _box.read<int>('streak_days') ?? 1;
  }

  List<int> getWeeklyActiveDays() {
    _checkStreak();
    final raw = _box.read<List<dynamic>>('weekly_active_days');
    if (raw == null || raw.isEmpty) return [DateTime.now().weekday];
    return raw.map((e) => (e as num).toInt()).toList();
  }

  void _checkStreak() {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final lastActive = _box.read<String>('last_active_date_str');
    if (lastActive == null) {
      _box.write('last_active_date_str', todayStr);
      _box.write('streak_days', 1);
      _box.write('weekly_active_days', [today.weekday]);
      return;
    }
    if (lastActive == todayStr) return; // already recorded today

    final lastDate = DateTime.tryParse(lastActive);
    if (lastDate != null) {
      final diffDays = DateTime(today.year, today.month, today.day)
          .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
          .inDays;
      if (diffDays == 1) {
        final currentStreak = _box.read<int>('streak_days') ?? 1;
        _box.write('streak_days', currentStreak + 1);
      } else if (diffDays > 1) {
        _box.write('streak_days', 1);
      }

      final currentWeekDays =
          (_box.read<List<dynamic>>('weekly_active_days') ?? [])
              .map((e) => (e as num).toInt())
              .toSet();
      if (diffDays >= 7 || today.weekday < lastDate.weekday) {
        currentWeekDays.clear();
      }
      currentWeekDays.add(today.weekday);
      _box.write('weekly_active_days', currentWeekDays.toList());
      _box.write('last_active_date_str', todayStr);
    }
  }

  void recordDeedAttempt({
    required int score,
    required bool passed,
    required int unlockMinutes,
  }) {
    _checkStreak();
    final total = getTotalDeedsCount() + 1;
    _box.write('total_deeds_count', total);

    final scores = (_box.read<List<dynamic>>('pronunciation_scores') ?? [])
        .map((e) => (e as num).toInt())
        .toList();
    scores.add(score);
    if (scores.length > 50) scores.removeAt(0);
    _box.write('pronunciation_scores', scores);

    if (passed) {
      final completed = getCompletedDeedsCount() + 1;
      _box.write('completed_deeds_count', completed);

      if (unlockMinutes > 0) {
        final totalMinutes = getUnlockedMinutesTotal() + unlockMinutes;
        _box.write('unlocked_minutes_total', totalMinutes);
      }
    }
  }

  // Generic key-value helpers
  T? read<T>(String key) => _box.read<T>(key);
  void write(String key, dynamic value) => _box.write(key, value);
  void clear() => _box.erase();
}
