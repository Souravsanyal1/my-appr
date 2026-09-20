class FocusSessionModel {
  final String id;
  final DateTime startTime;
  final int durationMinutes;
  final bool isCompleted;
  final String? reflectionNote;

  const FocusSessionModel({
    required this.id,
    required this.startTime,
    required this.durationMinutes,
    this.isCompleted = false,
    this.reflectionNote,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'isCompleted': isCompleted,
      'reflectionNote': reflectionNote,
    };
  }

  factory FocusSessionModel.fromMap(Map<String, dynamic> map) {
    return FocusSessionModel(
      id: map['id'] as String? ?? '',
      startTime: DateTime.tryParse(map['startTime'] as String? ?? '') ?? DateTime.now(),
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 25,
      isCompleted: map['isCompleted'] as bool? ?? false,
      reflectionNote: map['reflectionNote'] as String?,
    );
  }
}
