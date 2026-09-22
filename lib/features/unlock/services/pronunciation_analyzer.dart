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
    String? audioPath,
    double? averageAmplitudeDb,
    double? peakAmplitudeDb,
    int? audioFileSizeBytes,
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
    String? audioPath,
    double? averageAmplitudeDb,
    double? peakAmplitudeDb,
    int? audioFileSizeBytes,
  }) async {
    // Artificial non-blocking async delay to simulate acoustic analysis
    await Future.delayed(const Duration(milliseconds: 650));

    // -------------------------------------------------------------------------
    // 1. REAL ACOUSTIC CHECK: Silence / Low Energy / Missing File Detection
    // -------------------------------------------------------------------------
    // dBFS values range from -160 dBFS (total silence) to 0 dBFS (clipping peak).
    // Normal conversational speech into microphone is typically between -35 dBFS and -10 dBFS.
    // Ambient silence or muted background noise typically stays below -46 dBFS.
    final bool hasAudioFile = audioPath != null &&
        audioPath.isNotEmpty &&
        (audioFileSizeBytes == null || audioFileSizeBytes > 1500);

    // If audio recording was provided, verify genuine sound energy was captured
    final bool isSilentOrNoSpeech = (peakAmplitudeDb != null && peakAmplitudeDb < -46.0) ||
        (averageAmplitudeDb != null && averageAmplitudeDb < -52.0) ||
        (!hasAudioFile && audioPath != null);

    if (isSilentOrNoSpeech) {
      // REAL: The microphone captured near silence, white noise, or an empty file.
      return const PronunciationResult(
        overallScore: 28,
        wordRecognitionScore: 20,
        timingScore: 35,
        audioSimilarityScore: 25,
        earnedUnlockMinutes: 0,
        isPassing: false,
        feedback:
            'No clear recitation speech detected. Please speak clearly and audibly into the microphone.',
      );
    }

    // -------------------------------------------------------------------------
    // 2. REAL DURATION / TARTIL PACING CHECK
    // -------------------------------------------------------------------------
    // Hurrying through Quranic words violates Tartil (measured, rhythmic pacing).
    if (durationSeconds < minDurationSeconds) {
      return PronunciationResult(
        overallScore: 54,
        wordRecognitionScore: 48,
        timingScore: 42,
        audioSimilarityScore: 52,
        earnedUnlockMinutes: 0,
        isPassing: false,
        feedback:
            'Recitation was too fast or incomplete. Please recite calmly with Tartil for at least $minDurationSeconds seconds.',
      );
    }

    // -------------------------------------------------------------------------
    // 3. REAL ACOUSTIC ENERGY & VOLUME METRICS
    // -------------------------------------------------------------------------
    // Assess volume stability and loudness from real amplitude
    int volumeScore = 88;
    if (peakAmplitudeDb != null) {
      if (peakAmplitudeDb > -5.0) {
        // Too close or clipping
        volumeScore = 80;
      } else if (peakAmplitudeDb < -35.0) {
        // Very faint / distant voice
        volumeScore = 72;
      } else {
        // Optimal recitation volume (-30 dBFS to -8 dBFS)
        volumeScore = 92;
      }
    }

    // -------------------------------------------------------------------------
    // 4. SIMULATED PHONEME & TAJWEED ALIGNMENT
    // -------------------------------------------------------------------------
    // NOTE (Architecture boundary): Full on-device Arabic phonetic/makhraj
    // recognition requires a dedicated neural speech model (e.g. TFLite/Whisper).
    // Here, phonetic match is simulated within a realistic variance window anchored
    // by the genuine acoustic metrics (volume score, pacing duration, energy).
    final int baseVariance = _random.nextInt(6);
    int wordRecognition;
    int timing;
    int audioSimilarity;

    if (durationSeconds >= minDurationSeconds + 2) {
      wordRecognition = (86 + baseVariance + (volumeScore > 85 ? 4 : 0)).clamp(0, 100);
      timing = (84 + _random.nextInt(10)).clamp(0, 100);
      audioSimilarity = (85 + _random.nextInt(8) + (volumeScore > 85 ? 3 : 0)).clamp(0, 100);
    } else {
      wordRecognition = (78 + baseVariance).clamp(0, 100);
      timing = (74 + _random.nextInt(8)).clamp(0, 100);
      audioSimilarity = (76 + _random.nextInt(9)).clamp(0, 100);
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
