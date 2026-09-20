class DhikrModel {
  final String id;
  final String arabic;
  final String transliteration;
  final String translation;
  final int targetCount;
  final String virtue;

  const DhikrModel({
    required this.id,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.targetCount,
    required this.virtue,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'arabic': arabic,
      'transliteration': transliteration,
      'translation': translation,
      'targetCount': targetCount,
      'virtue': virtue,
    };
  }

  factory DhikrModel.fromMap(Map<String, dynamic> map) {
    return DhikrModel(
      id: map['id'] as String? ?? '',
      arabic: map['arabic'] as String? ?? '',
      transliteration: map['transliteration'] as String? ?? '',
      translation: map['translation'] as String? ?? '',
      targetCount: (map['targetCount'] as num?)?.toInt() ?? 33,
      virtue: map['virtue'] as String? ?? '',
    );
  }
}
