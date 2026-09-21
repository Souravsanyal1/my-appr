class AchievementModel {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final int targetValue;
  final int currentValue;
  final bool isUnlocked;

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.targetValue,
    this.currentValue = 0,
    this.isUnlocked = false,
  });

  double get progressPercentage => (currentValue / targetValue).clamp(0.0, 1.0);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconName': iconName,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'isUnlocked': isUnlocked,
    };
  }

  factory AchievementModel.fromMap(Map<String, dynamic> map) {
    return AchievementModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      iconName: map['iconName'] as String? ?? 'star',
      targetValue: map['targetValue'] as int? ?? 1,
      currentValue: map['currentValue'] as int? ?? 0,
      isUnlocked: map['isUnlocked'] as bool? ?? false,
    );
  }

  AchievementModel copyWith({
    String? id,
    String? title,
    String? description,
    String? iconName,
    int? targetValue,
    int? currentValue,
    bool? isUnlocked,
  }) {
    return AchievementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }
}
