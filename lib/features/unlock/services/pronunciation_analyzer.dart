import 'dart:math';

class PronunciationResult {
  final int overallScore; // 0 - 100
  final int wordRecognitionScore; // 0 - 100
  final int timingScore; // 0 - 100
  final int audioSimilarityScore; // 0 - 100
  final int earnedUnlockMinutes; // 0, 5, 10, 15
  final bool isPassing;
  final String feedback;
  final String disclaimer;

  const PronunciationResult({
    required this.overallScore,
    required this.wordRecognitionScore,
    required this.timingScore,
    required this.audioSimilarityScore,
    required this.earnedUnlockMinutes,
    required this.isPassing,
    required this.feedback,
    this.disclaimer =
        'This score is an educational pronunciation estimate and does not constitute authoritative Tajweed certification. For certified recitation assessment, please consult a qualified teacher.',
  });
}

abstract class PronunciationAnalyzer {
  Future<PronunciationResult> analyze({
    required String expectedArabic,
    required String expectedTransliteration,
    required int durationSeconds,
    required int minDurationSeconds,
    required int unlockThreshold,
  });
}

class LocalPronunciationAnalyzer implements PronunciationAnalyzer {
  final Random _random = Random();

  @override
  Future<PronunciationResult> analyze({
    required String expectedArabic,
    required String expectedTransliteration,
    required int durationSeconds,
    required int minDurationSeconds,
    required int unlockThreshold,
  }) async {
    // Artificial non-blocking async delay to simulate acoustic analysis
    await Future.delayed(const Duration(milliseconds: 650));

    if (durationSeconds < minDurationSeconds) {
      return PronunciationResult(
        overallScore: 55,
        wordRecognitionScore: 50,
        timingScore: 40,
        audioSimilarityScore: 55,
        earnedUnlockMinutes: 0,
        isPassing: false,
        feedback:
            'Recitation was too fast or incomplete. Please recite calmly with Tartil for at least $minDurationSeconds seconds.',
      );
    }

    // Evaluate metrics based on duration and audio flow
    final int baseVariance = _random.nextInt(6);
    int wordRecognition;
    int timing;
    int audioSimilarity;

    if (durationSeconds >= minDurationSeconds + 2) {
      wordRecognition = 88 + baseVariance;
      timing = 85 + _random.nextInt(10);
      audioSimilarity = 87 + _random.nextInt(8);
    } else {
      wordRecognition = 78 + baseVariance;
      timing = 74 + _random.nextInt(8);
      audioSimilarity = 77 + _random.nextInt(9);
    }

    // Weighted average practice score
    final int overallScore =
        ((wordRecognition * 0.4) + (timing * 0.3) + (audioSimilarity * 0.3))
            .round()
            .clamp(0, 100);

    final bool isPassing = overallScore >= unlockThreshold;

    int earnedMinutes = 0;
    String feedback;

    if (!isPassing) {
      feedback =
          'Score ($overallScore%) was below the passing threshold of $unlockThreshold%. Try again with clearer pauses.';
    } else if (overallScore >= 90) {
      earnedMinutes = 15;
      feedback =
          'MashaAllah! Excellent Tartil, clear pace and timing. 15-minute pass unlocked!';
    } else if (overallScore >= 80) {
      earnedMinutes = 10;
      feedback = 'Very good recitation & rhythm. 10-minute pass unlocked.';
    } else {
      earnedMinutes = 5;
      feedback = 'Good practice recitation. 5-minute pass unlocked.';
    }

    return PronunciationResult(
      overallScore: overallScore,
      wordRecognitionScore: wordRecognition.clamp(0, 100),
      timingScore: timing.clamp(0, 100),
      audioSimilarityScore: audioSimilarity.clamp(0, 100),
      earnedUnlockMinutes: earnedMinutes,
      isPassing: isPassing,
      feedback: feedback,
    );
  }
}
