enum ScheduleRepeatType {
  daily,
  weekdays,
  weekends,
  custom,
}

extension ScheduleRepeatTypeExtension on ScheduleRepeatType {
  String get displayName {
    switch (this) {
      case ScheduleRepeatType.daily:
        return 'Every Day';
      case ScheduleRepeatType.weekdays:
        return 'Weekdays (Mon-Fri)';
      case ScheduleRepeatType.weekends:
        return 'Weekends (Sat-Sun)';
      case ScheduleRepeatType.custom:
        return 'Custom Days';
    }
  }
}

class ScheduleModel {
  final String id;
  final String name;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final ScheduleRepeatType repeatType;
  final List<int> customDays; // 1 = Monday, 7 = Sunday (ISO 8601)
  final List<String> blockedPackages;
  final bool isEnabled;

  const ScheduleModel({
    required this.id,
    required this.name,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.repeatType = ScheduleRepeatType.daily,
    this.customDays = const [1, 2, 3, 4, 5, 6, 7],
    required this.blockedPackages,
    this.isEnabled = true,
  });

  String get timeRangeString {
    final startPeriod = startHour >= 12 ? 'PM' : 'AM';
    final endPeriod = endHour >= 12 ? 'PM' : 'AM';
    final displayStartH = startHour == 0 ? 12 : (startHour > 12 ? startHour - 12 : startHour);
    final displayEndH = endHour == 0 ? 12 : (endHour > 12 ? endHour - 12 : endHour);
    final startMinStr = startMinute.toString().padLeft(2, '0');
    final endMinStr = endMinute.toString().padLeft(2, '0');
    return '$displayStartH:$startMinStr $startPeriod – $displayEndH:$endMinStr $endPeriod';
  }

  bool isTimeActive(DateTime now) {
    if (!isEnabled) return false;

    // Check weekday matching
    final weekday = now.weekday; // 1 = Monday, 7 = Sunday
    bool dayMatches = false;
    switch (repeatType) {
      case ScheduleRepeatType.daily:
        dayMatches = true;
        break;
      case ScheduleRepeatType.weekdays:
        dayMatches = weekday >= 1 && weekday <= 5;
        break;
      case ScheduleRepeatType.weekends:
        dayMatches = weekday == 6 || weekday == 7;
        break;
      case ScheduleRepeatType.custom:
        dayMatches = customDays.contains(weekday);
        break;
    }

    if (!dayMatches) return false;

    final currentTotalMin = now.hour * 60 + now.minute;
    final startTotalMin = startHour * 60 + startMinute;
    final endTotalMin = endHour * 60 + endMinute;

    if (startTotalMin <= endTotalMin) {
      // Normal schedule (e.g. 14:00 to 17:00)
      return currentTotalMin >= startTotalMin && currentTotalMin < endTotalMin;
    } else {
      // Overnight schedule (e.g. 23:00 to 07:00 next morning)
      return currentTotalMin >= startTotalMin || currentTotalMin < endTotalMin;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
      'repeatType': repeatType.name,
      'customDays': customDays,
      'blockedPackages': blockedPackages,
      'isEnabled': isEnabled,
    };
  }

  factory ScheduleModel.fromMap(Map<String, dynamic> map) {
    return ScheduleModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      startHour: map['startHour'] as int? ?? 0,
      startMinute: map['startMinute'] as int? ?? 0,
      endHour: map['endHour'] as int? ?? 0,
      endMinute: map['endMinute'] as int? ?? 0,
      repeatType: ScheduleRepeatType.values.firstWhere(
        (e) => e.name == map['repeatType'],
        orElse: () => ScheduleRepeatType.daily,
      ),
      customDays: (map['customDays'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [1, 2, 3, 4, 5, 6, 7],
      blockedPackages: (map['blockedPackages'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isEnabled: map['isEnabled'] as bool? ?? true,
    );
  }

  ScheduleModel copyWith({
    String? id,
    String? name,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    ScheduleRepeatType? repeatType,
    List<int>? customDays,
    List<String>? blockedPackages,
    bool? isEnabled,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      repeatType: repeatType ?? this.repeatType,
      customDays: customDays ?? this.customDays,
      blockedPackages: blockedPackages ?? this.blockedPackages,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
