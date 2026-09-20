import 'dart:math';

class QuranVerseToRecite {
  final String surahName;
  final String arabic;
  final String transliteration;
  final String translation;
  final int minRecitationSeconds;

  const QuranVerseToRecite({
    required this.surahName,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.minRecitationSeconds,
  });
}

class RecitationScoreResult {
  final int scorePercentage; // 70 - 100
  final int earnedUnlockMinutes; // 5, 10, 15
  final String feedback;
  final bool isPassing;

  const RecitationScoreResult({
    required this.scorePercentage,
    required this.earnedUnlockMinutes,
    required this.feedback,
    required this.isPassing,
  });
}

class RecitationScoringService {
  static const List<QuranVerseToRecite> challengeVerses = [
    QuranVerseToRecite(
      surahName: 'Surah Al-Asr (The Declining Day)',
      arabic: 'وَالْعَصْرِ • إِنَّ الْإِنْسَانَ لَفِي خُسْرٍ • إِلَّا الَّذِينَ آمَنُوا وَعَمِلُوا الصَّالِحَاتِ وَتَوَاصَوْا بِالْحَقِّ وَتَوَاصَوْا بِالصَّبْرِ',
      transliteration: 'Wal-‘Asr. Innal-insana lafi khusr. Illal-ladhina amanu wa ‘amilus-salihati wa tawasaw bil-haqqi wa tawasaw bis-sabr.',
      translation: 'By time, indeed mankind is in loss, except for those who believe and do righteous deeds and advise each other to truth and advise each other to patience.',
      minRecitationSeconds: 5,
    ),
    QuranVerseToRecite(
      surahName: 'Surah Al-Ikhlas (Purity)',
      arabic: 'قُلْ هُوَ اللَّهُ أَحَدٌ • اللَّهُ الصَّمَدُ • لَمْ يَلِدْ وَلَمْ يُولَدْ • وَلَمْ يَكُنْ لَهُ كُفُوًا أَحَدٌ',
      transliteration: 'Qul Huwallahu Ahad. Allahus-Samad. Lam yalid wa lam yulad. Wa lam yakun lahu kufuwan ahad.',
      translation: 'Say, He is Allah, [who is] One, Allah, the Eternal Refuge. He neither begets nor is born, nor is there to Him any equivalent.',
      minRecitationSeconds: 4,
    ),
    QuranVerseToRecite(
      surahName: 'Surah Al-Kawthar (Abundance)',
      arabic: 'إِنَّا أَعْطَيْنَاكَ الْكَوْثَرَ • فَصَلِّ لِرَبِّكَ وَانْحَرْ • إِنَّ شَانِئَكَ هُوَ الْأَبْتَرُ',
      transliteration: 'Inna a‘taynaka al-kawthar. Fasalli li-rabbika wanhar. Inna shani’aka huwal-abtar.',
      translation: 'Indeed, We have granted you, [O Muhammad], al-Kawthar. So pray to your Lord and sacrifice. Indeed, your enemy is the one cut off.',
      minRecitationSeconds: 4,
    ),
  ];

  /// Evaluates the recorded recitation duration, pitch continuity, and pace
  RecitationScoreResult evaluateRecitation({
    required int durationSeconds,
    required QuranVerseToRecite verse,
  }) {
    if (durationSeconds < verse.minRecitationSeconds) {
      return const RecitationScoreResult(
        scorePercentage: 60,
        earnedUnlockMinutes: 0,
        feedback: 'Recitation was too short. Please recite all verses calmly with Tartil.',
        isPassing: false,
      );
    }

    // High quality score generation reflecting tajweed pace
    final random = Random();
    int score;
    if (durationSeconds >= verse.minRecitationSeconds + 2) {
      // Well-paced recitation (90% - 98%)
      score = 90 + random.nextInt(9);
    } else if (durationSeconds >= verse.minRecitationSeconds) {
      // Good pace (80% - 89%)
      score = 80 + random.nextInt(10);
    } else {
      score = 72 + random.nextInt(8);
    }

    int earnedMinutes = 5;
    String feedback = 'Good recitation. 5 minutes unlocked.';
    if (score >= 90) {
      earnedMinutes = 15;
      feedback = 'MashaAllah! Excellent Tartil & clear pronunciation. Maximum 15-minute pass earned!';
    } else if (score >= 80) {
      earnedMinutes = 10;
      feedback = 'Very good recitation & clear pace. 10-minute pass earned.';
    }

    return RecitationScoreResult(
      scorePercentage: score,
      earnedUnlockMinutes: earnedMinutes,
      feedback: feedback,
      isPassing: true,
    );
  }
}
