class GoodDeedModel {
  final String id;
  final String titleEn;
  final String titleBn;
  final String arabic;
  final String transliteration;
  final String banglaPronunciation;
  final String translationEn;
  final String translationBn;
  final String difficulty; // 'Easy', 'Medium', 'Hard'
  final int rewardMinutes;
  final int xpEarned;
  final int targetRepetitions;
  final String hadithQuoteEn;
  final String hadithQuoteBn;
  final String reference;

  const GoodDeedModel({
    required this.id,
    required this.titleEn,
    required this.titleBn,
    required this.arabic,
    required this.transliteration,
    required this.banglaPronunciation,
    required this.translationEn,
    required this.translationBn,
    required this.difficulty,
    required this.rewardMinutes,
    required this.xpEarned,
    required this.targetRepetitions,
    required this.hadithQuoteEn,
    required this.hadithQuoteBn,
    required this.reference,
  });

  static const List<GoodDeedModel> pool = [
    GoodDeedModel(
      id: 'subhanallah',
      titleEn: 'Tasbih (SubhanAllah)',
      titleBn: 'তাসবীহ (সুবহানাল্লাহ)',
      arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
      transliteration: 'Subḥān Allāhi wa bi-ḥamdih',
      banglaPronunciation: 'সুবহানাল্লাহি ওয়া বিহামদিহি',
      translationEn: 'Glory be to Allah and His is the praise.',
      translationBn: 'আল্লাহ পবিত্র এবং যাবতীয় প্রশংসা তাঁরই।',
      difficulty: 'Easy',
      rewardMinutes: 30,
      xpEarned: 10,
      targetRepetitions: 3,
      hadithQuoteEn:
          '"Whoever says this 100 times a day, his sins will be wiped away even if they were like the foam of the sea." (Sahih Muslim)',
      hadithQuoteBn:
          '"যে ব্যক্তি দিনে একশত বার এটি পাঠ করে, তার সকল গুনাহ মাফ করে দেওয়া হয়, যদিও তা সমুদ্রের ফেনার মতো হয়।" (সহীহ মুসলিম)',
      reference: 'Sahih Muslim 2691',
    ),
    GoodDeedModel(
      id: 'alhamdulillah',
      titleEn: 'Tahmid (Alhamdulillah)',
      titleBn: 'তাহমীদ (আলহামদুলিল্লাহ)',
      arabic: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
      transliteration: 'Al-ḥamdu lillāhi Rabbil-‘ālamīn',
      banglaPronunciation: 'আলহামদুলিল্লাহি রাব্বিল আলামিন',
      translationEn: 'All praise is due to Allah, Lord of all the worlds.',
      translationBn: 'সকল প্রশংসা সৃষ্টিকুলের প্রতিপালক মহান আল্লাহর জন্য।',
      difficulty: 'Easy',
      rewardMinutes: 30,
      xpEarned: 10,
      targetRepetitions: 3,
      hadithQuoteEn:
          '"Purity is half of iman and Alhamdulillah fills the scale." (Sahih Muslim)',
      hadithQuoteBn:
          '"পবিত্রতা ঈমানের অর্ধেক এবং ‘আলহামদুলিল্লাহ’ নেকের পাল্লাকে পূর্ণ করে দেয়।" (সহীহ মুসলিম)',
      reference: 'Sahih Muslim 223',
    ),
    GoodDeedModel(
      id: 'istighfar',
      titleEn: 'Istighfar (Seeking Forgiveness)',
      titleBn: 'ইস্তিগফার (ক্ষমাপ্রার্থনা)',
      arabic: 'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ وَأَتُوبُ إِلَيْهِ',
      transliteration: 'Astaghfirullāhal-‘Aẓīma wa atūbu ilayh',
      banglaPronunciation: 'আস্তাগফিরুল্লাহাল আজিম ওয়া আতূবু ইলাইহি',
      translationEn:
          'I seek forgiveness of Allah the Magnificent and turn to Him in repentance.',
      translationBn:
          'আমি মহান আল্লাহর নিকট ক্ষমা প্রার্থনা করছি এবং তাঁর দিকেই তওবা করছি।',
      difficulty: 'Medium',
      rewardMinutes: 30,
      xpEarned: 20,
      targetRepetitions: 3,
      hadithQuoteEn:
          '"By Allah, I seek Allah\'s forgiveness and turn to Him more than 70 times a day." (Sahih al-Bukhari)',
      hadithQuoteBn:
          '"আল্লাহর শপথ! আমি প্রতিদিন সত্তরেরও অধিক বার আল্লাহর কাছে ক্ষমাপ্রার্থনা ও তওবা করি।" (সহীহ বুখারী)',
      reference: 'Sahih al-Bukhari 6307',
    ),
    GoodDeedModel(
      id: 'salawat',
      titleEn: 'Salawat upon the Prophet ﷺ',
      titleBn: 'নবীজী ﷺ-এর প্রতি দরূদ',
      arabic: 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ',
      transliteration: 'Allāhumma ṣalli ‘alā Muḥammadin wa ‘alā āli Muḥammad',
      banglaPronunciation:
          'আল্লাহুম্মা সাল্লি ‘আলা মুহাম্মাদিঁও ওয়া ‘আলা আলি মুহাম্মাদ',
      translationEn:
          'O Allah, bestow peace and blessings upon Muhammad and his family.',
      translationBn:
          'হে আল্লাহ! মুহাম্মদ ﷺ এবং তাঁর বংশধরদের উপর শান্তি ও বরকত বর্ষণ করুন।',
      difficulty: 'Medium',
      rewardMinutes: 30,
      xpEarned: 20,
      targetRepetitions: 3,
      hadithQuoteEn:
          '"Whoever sends blessings upon me once, Allah will send blessings upon him ten times." (Sahih Muslim)',
      hadithQuoteBn:
          '"যে ব্যক্তি আমার ওপর একবার দরূদ পাঠ করবে, আল্লাহ তার ওপর দশবার রহমত বর্ষণ করবেন।" (সহীহ মুসলিম)',
      reference: 'Sahih Muslim 384',
    ),
    GoodDeedModel(
      id: 'ayatul_kursi',
      titleEn: 'Ayat al-Kursi (2:255)',
      titleBn: 'আয়াতুল কুরসী (বাক্বারাহ: ২৫৫)',
      arabic:
          'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ',
      transliteration:
          'Allāhu lā ilāha illā Huwal-Ḥayyul-Qayyūm. Lā ta’khudhuhū sinatuw-wa lā nawm. Lahū mā fis-samāwāti wa mā fil-arḍ',
      banglaPronunciation:
          'আল্লাহু লা ইলাহা ইল্লা হুয়াল হাইয়্যুল কাইয়্যুম, লা তা’খুযুহু সিনাতুওঁ ওয়ালা নাওম, লাহু মা ফিস-সামাওয়াতি ওয়ামা ফিল আরদ',
      translationEn:
          'Allah! There is no deity except Him, the Ever-Living, the Sustainer of existence. Neither drowsiness overtakes Him nor sleep.',
      translationBn:
          'আল্লাহ, তিনি ছাড়া কোনো সত্য উপাস্য নেই; তিনি চিরঞ্জীব, সর্বসত্তার ধারক। তন্দ্রা বা নিদ্রা তাঁকে স্পর্শ করে না।',
      difficulty: 'Hard',
      rewardMinutes: 45,
      xpEarned: 30,
      targetRepetitions: 1,
      hadithQuoteEn:
          '"Whoever recites Ayat al-Kursi after every prayer, nothing prevents him from Paradise except death." (An-Nasa\'i)',
      hadithQuoteBn:
          '"যে ব্যক্তি প্রত্যেক ফরজ সালাতের পর আয়াতুল কুরসী পাঠ করে, তার জান্নাতে প্রবেশের পথে মৃত্যু ছাড়া আর কোনো বাধা থাকে না।" (নাসায়ী)',
      reference: 'Sunan an-Nasa\'i 9848',
    ),
    GoodDeedModel(
      id: 'ikhlas',
      titleEn: 'Surah Al-Ikhlas (112:1-4)',
      titleBn: 'সূরা আল-ইখলাস (১১২:১-৪)',
      arabic:
          'قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ',
      transliteration:
          'Qul Huwallāhu Aḥad. Allāhuṣ-Ṣamad. Lam yalid wa lam yūlad. Wa lam yakul-lahū kufuwan aḥad',
      banglaPronunciation:
          'কুল হুয়াল্লাহু আহাদ। আল্লাহুস সামাদ। লাম ইয়ালিদ ওয়া লাম ইউলাদ। ওয়া লাম ইয়াকুল লাহু কুফুওয়ান আহাদ।',
      translationEn:
          'Say: He is Allah, [who is] One. Allah, the Eternal Refuge. He neither begets nor is born, nor is there to Him any equivalent.',
      translationBn:
          'বলুন: তিনিই আল্লাহ, একক। আল্লাহ অমুখাপেক্ষী। তিনি কাউকে জন্ম দেননি এবং তাঁকেও কেউ জন্ম দেয়নি। আর তাঁর সমকক্ষ কেউই নেই।',
      difficulty: 'Easy',
      rewardMinutes: 30,
      xpEarned: 10,
      targetRepetitions: 3,
      hadithQuoteEn:
          '"Reciting Surah Al-Ikhlas is equivalent to reciting one-third of the Quran." (Sahih al-Bukhari)',
      hadithQuoteBn:
          '"সূরা আল-ইখলাস পাঠ করা পবিত্র কুরআনের এক-তৃতীয়াংশ পাঠের সমান।" (সহীহ বুখারী)',
      reference: 'Sahih al-Bukhari 5013',
    ),
  ];
}
