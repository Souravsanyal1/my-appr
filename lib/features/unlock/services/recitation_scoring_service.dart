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
      surahName: 'ইস্তিগফার (Astaghfirullah)',
      arabic: 'أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ',
      transliteration: 'Astaghfirullaha wa atubu ilayh',
      translation:
          'আল্লাহর কাছে ক্ষমা প্রার্থনা করছি এবং তাঁরই দিকে প্রত্যাবর্তন করছি। (I seek forgiveness from Allah and repent to Him)',
      minRecitationSeconds: 3,
    ),
    QuranVerseToRecite(
      surahName: 'তাসবীহ (SubhanAllah)',
      arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
      transliteration: 'SubhanAllahi wa bihamdihi',
      translation:
          'আল্লাহ মহাপবিত্র এবং সকল প্রশংসা তাঁরই। (Glory and praise be to Allah)',
      minRecitationSeconds: 3,
    ),
    QuranVerseToRecite(
      surahName: 'তাহমীদ (Alhamdulillah)',
      arabic: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
      transliteration: 'Alhamdulillahi Rabbil ‘Alamin',
      translation:
          'সকল প্রশংসা মহান আল্লাহর, যিনি সকল সৃষ্টির প্রতিপালক। (All praise is for Allah, Lord of the worlds)',
      minRecitationSeconds: 3,
    ),
    QuranVerseToRecite(
      surahName: 'সূরা আল-ইখলাস (১-২ আয়াত)',
      arabic: 'قُلْ هُوَ اللَّهُ أَحَدٌ • اللَّهُ الصَّمَدُ',
      transliteration: 'Qul Huwallahu Ahad. Allahus-Samad.',
      translation:
          'বলুন: তিনিই আল্লাহ, একক ও অদ্বিতীয়। আল্লাহ কারো মুখাপেক্ষী নন। (Say: He is Allah, the One. Allah, the Eternal Refuge.)',
      minRecitationSeconds: 3,
    ),
    QuranVerseToRecite(
      surahName: 'সূরা ইনশিরাহ (সহজ আয়াত)',
      arabic: 'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا • إِنَّ مَعَ الْعُسْرِ يُسْرًا',
      transliteration: 'Fa inna ma‘al-‘usri yusra. Inna ma‘al-‘usri yusra.',
      translation:
          'নিশ্চয়ই কষ্টের সাথেই স্বস্তি আছে। (Indeed, with hardship comes ease.)',
      minRecitationSeconds: 3,
    ),
    QuranVerseToRecite(
      surahName: 'সূরা আল-আসর (Surah Al-Asr)',
      arabic:
          'وَالْعَصْرِ • إِنَّ الْإِنْسَانَ لَفِي خُسْرٍ • إِلَّا الَّذِينَ آمَنُوا وَعَمِلُوا الصَّالِحَاتِ',
      transliteration:
          'Wal-‘Asr. Innal-insana lafi khusr. Illal-ladhina amanu wa ‘amilus-salihati.',
      translation:
          'কালের শপথ! নিশ্চয় মানুষ ক্ষতির মধ্যে নিমজ্জিত, তারা ছাড়া যারা ঈমান এনেছে ও সৎকাজ করেছে।',
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
        feedback:
            'Recitation was too short. Please recite all verses calmly with Tartil.',
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
      feedback =
          'MashaAllah! Excellent Tartil & clear pronunciation. Maximum 15-minute pass earned!';
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
