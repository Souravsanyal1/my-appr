class AppLimitModel {
  final String packageName;
  final String appName;
  final int dailyLimitMinutes;
  final int warningThresholdMinutes;
  final String mode; // 'block' or 'warning'
  final bool isEnabled;

  const AppLimitModel({
    required this.packageName,
    required this.appName,
    required this.dailyLimitMinutes,
    this.warningThresholdMinutes = 5,
    this.mode = 'block',
    this.isEnabled = true,
  });

  AppLimitModel copyWith({
    String? packageName,
    String? appName,
    int? dailyLimitMinutes,
    int? warningThresholdMinutes,
    String? mode,
    bool? isEnabled,
  }) {
    return AppLimitModel(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      warningThresholdMinutes: warningThresholdMinutes ?? this.warningThresholdMinutes,
      mode: mode ?? this.mode,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'appName': appName,
      'dailyLimitMinutes': dailyLimitMinutes,
      'warningThresholdMinutes': warningThresholdMinutes,
      'mode': mode,
      'isEnabled': isEnabled,
    };
  }

  factory AppLimitModel.fromMap(Map<String, dynamic> map) {
    return AppLimitModel(
      packageName: map['packageName'] as String? ?? '',
      appName: map['appName'] as String? ?? '',
      dailyLimitMinutes: (map['dailyLimitMinutes'] as num?)?.toInt() ?? 30,
      warningThresholdMinutes: (map['warningThresholdMinutes'] as num?)?.toInt() ?? 5,
      mode: map['mode'] as String? ?? 'block',
      isEnabled: map['isEnabled'] as bool? ?? true,
    );
  }
}
