enum LearningCategory {
  dailyDhikr,
  dailyDuas,
  salahLearning,
  shortSurahs,
}

extension LearningCategoryExtension on LearningCategory {
  String get displayName {
    switch (this) {
      case LearningCategory.dailyDhikr:
        return 'Daily Dhikr';
      case LearningCategory.dailyDuas:
        return 'Daily Duas';
      case LearningCategory.salahLearning:
        return 'Salah Learning';
      case LearningCategory.shortSurahs:
        return 'Short Surahs';
    }
  }

  String get description {
    switch (this) {
      case LearningCategory.dailyDhikr:
        return 'Authentic remembrance & praises of Allah';
      case LearningCategory.dailyDuas:
        return 'Essential prophetic supplications for daily moments';
      case LearningCategory.salahLearning:
        return 'Essential prayers, recitations, and postures of Salah';
      case LearningCategory.shortSurahs:
        return 'Selected short Surahs from Juz Amma with verified text';
    }
  }
}

class LearningLessonModel {
  final String id;
  final LearningCategory category;
  final String title;
  final String arabicText;
  final String transliteration;
  final String translation;
  final String sourceReference;
  final int minRecitationSeconds;
  final int targetRepetitions;
  final bool isCompleted;

  const LearningLessonModel({
    required this.id,
    required this.category,
    required this.title,
    required this.arabicText,
    required this.transliteration,
    required this.translation,
    required this.sourceReference,
    this.minRecitationSeconds = 4,
    this.targetRepetitions = 1,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category.name,
      'title': title,
      'arabicText': arabicText,
      'transliteration': transliteration,
      'translation': translation,
      'sourceReference': sourceReference,
      'minRecitationSeconds': minRecitationSeconds,
      'targetRepetitions': targetRepetitions,
      'isCompleted': isCompleted,
    };
  }

  factory LearningLessonModel.fromMap(Map<String, dynamic> map) {
    return LearningLessonModel(
      id: map['id'] as String? ?? '',
      category: LearningCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => LearningCategory.dailyDhikr,
      ),
      title: map['title'] as String? ?? '',
      arabicText: map['arabicText'] as String? ?? '',
      transliteration: map['transliteration'] as String? ?? '',
      translation: map['translation'] as String? ?? '',
      sourceReference: map['sourceReference'] as String? ?? '',
      minRecitationSeconds: map['minRecitationSeconds'] as int? ?? 4,
      targetRepetitions: map['targetRepetitions'] as int? ?? 1,
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }

  LearningLessonModel copyWith({
    String? id,
    LearningCategory? category,
    String? title,
    String? arabicText,
    String? transliteration,
    String? translation,
    String? sourceReference,
    int? minRecitationSeconds,
    int? targetRepetitions,
    bool? isCompleted,
  }) {
    return LearningLessonModel(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      arabicText: arabicText ?? this.arabicText,
      transliteration: transliteration ?? this.transliteration,
      translation: translation ?? this.translation,
      sourceReference: sourceReference ?? this.sourceReference,
      minRecitationSeconds: minRecitationSeconds ?? this.minRecitationSeconds,
      targetRepetitions: targetRepetitions ?? this.targetRepetitions,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
