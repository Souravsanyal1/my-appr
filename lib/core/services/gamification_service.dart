import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'native_bridge_service.dart';
import 'storage_service.dart';

enum UserRank {
  bronze(
    nameEn: 'Bronze',
    nameBn: 'ব্রোঞ্জ',
    minXp: 0,
    nextThreshold: 110,
    color: Color(0xFFCD7F32),
  ),
  silver(
    nameEn: 'Silver',
    nameBn: 'সিলভার',
    minXp: 111,
    nextThreshold: 300,
    color: Color(0xFFC0C0C0),
  ),
  gold(
    nameEn: 'Gold',
    nameBn: 'গোল্ড',
    minXp: 301,
    nextThreshold: 600,
    color: Color(0xFFFFD700),
  ),
  platinum(
    nameEn: 'Platinum',
    nameBn: 'প্লাটিনাম',
    minXp: 601,
    nextThreshold: 1200,
    color: Color(0xFF00E5FF),
  );

  final String nameEn;
  final String nameBn;
  final int minXp;
  final int nextThreshold;
  final Color color;

  const UserRank({
    required this.nameEn,
    required this.nameBn,
    required this.minXp,
    required this.nextThreshold,
    required this.color,
  });
}

class DeedHistoryItem {
  final String deedName;
  final int xpEarned;
  final int durationMinutes;
  final DateTime timestamp;

  const DeedHistoryItem({
    required this.deedName,
    required this.xpEarned,
    required this.durationMinutes,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'deedName': deedName,
        'xpEarned': xpEarned,
        'durationMinutes': durationMinutes,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory DeedHistoryItem.fromMap(Map<String, dynamic> map) => DeedHistoryItem(
        deedName: map['deedName'] as String? ?? 'Good Deed',
        xpEarned: map['xpEarned'] as int? ?? 10,
        durationMinutes: map['durationMinutes'] as int? ?? 30,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
        ),
      );
}

class GamificationService extends GetxService {
  static GamificationService get to => Get.find<GamificationService>();

  late final StorageService _storage;
  late final NativeBridgeService _nativeBridge;

  Timer? _countdownTicker;

  // Stacking Unlock Expiry
  final Rx<DateTime?> unlockExpiry = Rx<DateTime?>(null);
  final RxInt remainingSeconds = 0.obs;

  // XP & Rank
  final RxInt currentXp = 0.obs;

  // Streak & Activity
  final RxInt currentStreak = 1.obs;
  final RxInt longestStreak = 1.obs;
  final RxSet<int> weeklyCompletedDays = <int>{}.obs; // DateTime.sunday (7), monday (1)...

  // Deed History
  final RxList<DeedHistoryItem> deedHistory = <DeedHistoryItem>[].obs;

  Future<GamificationService> init() async {
    _storage = Get.find<StorageService>();
    _nativeBridge = Get.find<NativeBridgeService>();

    _loadState();
    _startCountdownTicker();

    return this;
  }

  void _loadState() {
    // 1. Persistent unlock expiry timestamp
    final expiryMs = _storage.read<int>('unlock_expiry_timestamp_ms') ?? 0;
    if (expiryMs > DateTime.now().millisecondsSinceEpoch) {
      unlockExpiry.value = DateTime.fromMillisecondsSinceEpoch(expiryMs);
    } else {
      unlockExpiry.value = null;
    }
    _updateRemainingSeconds();

    // 2. XP
    currentXp.value = _storage.read<int>('user_xp') ?? 90; // default initial demo XP

    // 3. Streak & Longest Streak
    currentStreak.value = _storage.getStreakDays();
    longestStreak.value = _storage.read<int>('longest_streak_days') ?? currentStreak.value;
    if (currentStreak.value > longestStreak.value) {
      longestStreak.value = currentStreak.value;
      _storage.write('longest_streak_days', longestStreak.value);
    }

    // 4. Weekly active days
    final activeDays = _storage.getWeeklyActiveDays();
    weeklyCompletedDays.assignAll(activeDays);

    // 5. History (Keep last 100 entries max)
    final historyRaw = _storage.read<List<dynamic>>('user_deed_history');
    if (historyRaw != null) {
      final items = historyRaw
          .map((e) => DeedHistoryItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .take(100)
          .toList();
      deedHistory.assignAll(items);
      if (historyRaw.length > 100) {
        _storage.write(
          'user_deed_history',
          items.map((e) => e.toMap()).toList(),
        );
      }
    }
  }

  void _startCountdownTicker() {
    _countdownTicker?.cancel();
    _countdownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemainingSeconds();
    });
  }

  void _updateRemainingSeconds() {
    final expiry = unlockExpiry.value;
    if (expiry == null) {
      remainingSeconds.value = 0;
      return;
    }
    final diff = expiry.difference(DateTime.now()).inSeconds;
    if (diff <= 0) {
      remainingSeconds.value = 0;
      unlockExpiry.value = null;
      _storage.write('unlock_expiry_timestamp_ms', 0);
    } else {
      remainingSeconds.value = diff;
    }
  }

  bool get isUnlocked => remainingSeconds.value > 0;

  String get formattedCountdown {
    final totalSecs = remainingSeconds.value;
    if (totalSecs <= 0) return '00m 00s';
    final hours = totalSecs ~/ 3600;
    final minutes = (totalSecs % 3600) ~/ 60;
    final seconds = totalSecs % 60;
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
    }
    return '${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
  }

  /// Stacks unlock time onto existing remaining time (or from now if locked).
  void stackUnlockTime(int additionalMinutes) {
    final now = DateTime.now();
    DateTime target;
    if (unlockExpiry.value != null && unlockExpiry.value!.isAfter(now)) {
      target = unlockExpiry.value!.add(Duration(minutes: additionalMinutes));
    } else {
      target = now.add(Duration(minutes: additionalMinutes));
    }

    unlockExpiry.value = target;
    _storage.write('unlock_expiry_timestamp_ms', target.millisecondsSinceEpoch);
    _updateRemainingSeconds();

    // Sync to native layer so AppMonitorService and FloatingTimerController get the exact stacked expiry
    final monitored = _storage.getMonitoredPackages();
    final remainingMinutes = (target.difference(now).inSeconds / 60).ceil().clamp(1, 9999);
    for (final pkg in monitored) {
      _nativeBridge.setTemporaryUnlock(pkg, remainingMinutes);
    }
  }

  /// User Rank Info
  UserRank get currentRank {
    final xp = currentXp.value;
    if (xp >= 601) return UserRank.platinum;
    if (xp >= 301) return UserRank.gold;
    if (xp >= 111) return UserRank.silver;
    return UserRank.bronze;
  }

  int get xpToNextRank {
    final rank = currentRank;
    if (rank == UserRank.platinum) return 0;
    return (rank.nextThreshold - currentXp.value).clamp(0, 999999);
  }

  double get rankProgress {
    final rank = currentRank;
    if (rank == UserRank.platinum) return 1.0;
    final range = rank.nextThreshold - rank.minXp;
    final inTier = (currentXp.value - rank.minXp).clamp(0, range);
    return (inTier / range).clamp(0.0, 1.0);
  }

  /// Awards XP, records history, advances streak, and stacks unlock time.
  void recordCompletedDeed({
    required String deedName,
    required int durationMinutes,
    required String difficulty, // 'Easy', 'Medium', 'Hard'
  }) {
    int xpEarned = 10;
    if (difficulty.toLowerCase() == 'medium') {
      xpEarned = 20;
    } else if (difficulty.toLowerCase() == 'hard') {
      xpEarned = 30;
    }

    // 1. Stack unlock time
    stackUnlockTime(durationMinutes);

    // 2. Add XP
    currentXp.value += xpEarned;
    _storage.write('user_xp', currentXp.value);

    // 3. Update Streak & Active Days
    final today = DateTime.now();
    weeklyCompletedDays.add(today.weekday);
    _storage.write('weekly_active_days', weeklyCompletedDays.toList());

    _storage.recordDeedAttempt(
      score: 95,
      passed: true,
      unlockMinutes: durationMinutes,
    );
    currentStreak.value = _storage.getStreakDays();
    if (currentStreak.value > longestStreak.value) {
      longestStreak.value = currentStreak.value;
      _storage.write('longest_streak_days', longestStreak.value);
    }

    // 4. Record to History
    final item = DeedHistoryItem(
      deedName: deedName,
      xpEarned: xpEarned,
      durationMinutes: durationMinutes,
      timestamp: today,
    );
    deedHistory.insert(0, item);
    if (deedHistory.length > 100) {
      deedHistory.removeRange(100, deedHistory.length);
    }
    _storage.write('user_deed_history', deedHistory.map((e) => e.toMap()).toList());
  }

  @override
  void onClose() {
    _countdownTicker?.cancel();
    super.onClose();
  }
}
