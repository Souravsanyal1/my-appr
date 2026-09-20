class UnlockSessionModel {
  final String packageName;
  final String appName;
  final int durationMinutes;
  final int expiresAtTimestamp; // Epoch millis

  const UnlockSessionModel({
    required this.packageName,
    required this.appName,
    required this.durationMinutes,
    required this.expiresAtTimestamp,
  });

  bool get isExpired => DateTime.now().millisecondsSinceEpoch >= expiresAtTimestamp;

  int get remainingSeconds {
    final diff = expiresAtTimestamp - DateTime.now().millisecondsSinceEpoch;
    return diff > 0 ? (diff / 1000).ceil() : 0;
  }

  String get remainingFormatted {
    final seconds = remainingSeconds;
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'appName': appName,
      'durationMinutes': durationMinutes,
      'expiresAtTimestamp': expiresAtTimestamp,
    };
  }

  factory UnlockSessionModel.fromMap(Map<String, dynamic> map) {
    return UnlockSessionModel(
      packageName: map['packageName'] as String? ?? '',
      appName: map['appName'] as String? ?? '',
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 5,
      expiresAtTimestamp: (map['expiresAtTimestamp'] as num?)?.toInt() ?? 0,
    );
  }
}
