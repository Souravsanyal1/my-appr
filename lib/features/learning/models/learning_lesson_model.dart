enum LearningCategory { dailyDhikr, dailyDuas, salahLearning, shortSurahs }

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

  String get banglaDisplayName {
    switch (this) {
      case LearningCategory.dailyDhikr:
        return 'দৈনিক যিকির';
      case LearningCategory.dailyDuas:
        return 'দৈনিক দোয়া';
      case LearningCategory.salahLearning:
        return 'নামাজ শিক্ষা';
      case LearningCategory.shortSurahs:
        return 'ছোট সূরাসমূহ';
    }
  }

  String getLocalizedName(bool isBangla) =>
      isBangla ? banglaDisplayName : displayName;

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
  final String? banglaTitle;
  final String arabicText;
  final String transliteration;
  final String? banglaPronunciation;
  final String translation;
  final String? banglaTranslation;
  final String sourceReference;
  final int minRecitationSeconds;
  final int targetRepetitions;
  final bool isCompleted;
  final String? audioUrl;

  const LearningLessonModel({
    required this.id,
    required this.category,
    required this.title,
    this.banglaTitle,
    required this.arabicText,
    required this.transliteration,
    this.banglaPronunciation,
    required this.translation,
    this.banglaTranslation,
    required this.sourceReference,
    this.minRecitationSeconds = 4,
    this.targetRepetitions = 1,
    this.isCompleted = false,
    this.audioUrl,
  });

  String getTitle(bool isBangla) =>
      (isBangla && banglaTitle != null && banglaTitle!.isNotEmpty)
      ? banglaTitle!
      : title;

  String getPronunciation(bool isBangla) =>
      (isBangla &&
          banglaPronunciation != null &&
          banglaPronunciation!.isNotEmpty)
      ? banglaPronunciation!
      : transliteration;

  String getTranslation(bool isBangla) =>
      (isBangla && banglaTranslation != null && banglaTranslation!.isNotEmpty)
      ? banglaTranslation!
      : translation;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category.name,
      'title': title,
      'banglaTitle': banglaTitle,
      'arabicText': arabicText,
      'transliteration': transliteration,
      'banglaPronunciation': banglaPronunciation,
      'translation': translation,
      'banglaTranslation': banglaTranslation,
      'sourceReference': sourceReference,
      'minRecitationSeconds': minRecitationSeconds,
      'targetRepetitions': targetRepetitions,
      'isCompleted': isCompleted,
      'audioUrl': audioUrl,
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
      banglaTitle: map['banglaTitle'] as String?,
      arabicText: map['arabicText'] as String? ?? '',
      transliteration: map['transliteration'] as String? ?? '',
      banglaPronunciation: map['banglaPronunciation'] as String?,
      translation: map['translation'] as String? ?? '',
      banglaTranslation: map['banglaTranslation'] as String?,
      sourceReference: map['sourceReference'] as String? ?? '',
      minRecitationSeconds: map['minRecitationSeconds'] as int? ?? 4,
      targetRepetitions: map['targetRepetitions'] as int? ?? 1,
      isCompleted: map['isCompleted'] as bool? ?? false,
      audioUrl: map['audioUrl'] as String?,
    );
  }

  LearningLessonModel copyWith({
    String? id,
    LearningCategory? category,
    String? title,
    String? banglaTitle,
    String? arabicText,
    String? transliteration,
    String? banglaPronunciation,
    String? translation,
    String? banglaTranslation,
    String? sourceReference,
    int? minRecitationSeconds,
    int? targetRepetitions,
    bool? isCompleted,
    String? audioUrl,
  }) {
    return LearningLessonModel(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      banglaTitle: banglaTitle ?? this.banglaTitle,
      arabicText: arabicText ?? this.arabicText,
      transliteration: transliteration ?? this.transliteration,
      banglaPronunciation: banglaPronunciation ?? this.banglaPronunciation,
      translation: translation ?? this.translation,
      banglaTranslation: banglaTranslation ?? this.banglaTranslation,
      sourceReference: sourceReference ?? this.sourceReference,
      minRecitationSeconds: minRecitationSeconds ?? this.minRecitationSeconds,
      targetRepetitions: targetRepetitions ?? this.targetRepetitions,
      isCompleted: isCompleted ?? this.isCompleted,
      audioUrl: audioUrl ?? this.audioUrl,
    );
  }
}
