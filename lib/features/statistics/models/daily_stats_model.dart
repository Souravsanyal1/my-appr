class DailyStatsModel {
  final String dateString; // YYYY-MM-DD
  final int totalScreenTimeMinutes;
  final int socialMediaMinutes;
  final int focusMinutes;
  final int blockedAttempts;
  final int lessonsCompleted;
  final int recitationsCount;
  final int averagePracticeScore;

  const DailyStatsModel({
    required this.dateString,
    this.totalScreenTimeMinutes = 0,
    this.socialMediaMinutes = 0,
    this.focusMinutes = 0,
    this.blockedAttempts = 0,
    this.lessonsCompleted = 0,
    this.recitationsCount = 0,
    this.averagePracticeScore = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'dateString': dateString,
      'totalScreenTimeMinutes': totalScreenTimeMinutes,
      'socialMediaMinutes': socialMediaMinutes,
      'focusMinutes': focusMinutes,
      'blockedAttempts': blockedAttempts,
      'lessonsCompleted': lessonsCompleted,
      'recitationsCount': recitationsCount,
      'averagePracticeScore': averagePracticeScore,
    };
  }

  factory DailyStatsModel.fromMap(Map<String, dynamic> map) {
    return DailyStatsModel(
      dateString: map['dateString'] as String? ?? '',
      totalScreenTimeMinutes: map['totalScreenTimeMinutes'] as int? ?? 0,
      socialMediaMinutes: map['socialMediaMinutes'] as int? ?? 0,
      focusMinutes: map['focusMinutes'] as int? ?? 0,
      blockedAttempts: map['blockedAttempts'] as int? ?? 0,
      lessonsCompleted: map['lessonsCompleted'] as int? ?? 0,
      recitationsCount: map['recitationsCount'] as int? ?? 0,
      averagePracticeScore: map['averagePracticeScore'] as int? ?? 0,
    );
  }

  DailyStatsModel copyWith({
    String? dateString,
    int? totalScreenTimeMinutes,
    int? socialMediaMinutes,
    int? focusMinutes,
    int? blockedAttempts,
    int? lessonsCompleted,
    int? recitationsCount,
    int? averagePracticeScore,
  }) {
    return DailyStatsModel(
      dateString: dateString ?? this.dateString,
      totalScreenTimeMinutes:
          totalScreenTimeMinutes ?? this.totalScreenTimeMinutes,
      socialMediaMinutes: socialMediaMinutes ?? this.socialMediaMinutes,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      blockedAttempts: blockedAttempts ?? this.blockedAttempts,
      lessonsCompleted: lessonsCompleted ?? this.lessonsCompleted,
      recitationsCount: recitationsCount ?? this.recitationsCount,
      averagePracticeScore: averagePracticeScore ?? this.averagePracticeScore,
    );
  }
}
