import '../models/learning_lesson_model.dart';

class LearningRepository {
  static const List<LearningLessonModel> allLessons = [
    // ══════════════════════════════════════════════════════════════
    // CATEGORY 1: DAILY DHIKR (দৈনিক যিকির)
    // ══════════════════════════════════════════════════════════════
    LearningLessonModel(
      id: 'dhikr_subhanallah',
      category: LearningCategory.dailyDhikr,
      title: 'Tasbih (SubhanAllah)',
      banglaTitle: 'তাসবীহ (সুবহানাল্লাহ)',
      arabicText: 'سُبْحَانَ اللَّهِ',
      transliteration: 'Subḥān Allāh',
      banglaPronunciation: 'সুবহানাল্লাহ',
      translation: 'Glory be to Allah, free is He from all imperfections.',
      banglaTranslation:
          'আল্লাহ মহাপবিত্র, সকল প্রকার ত্রুটি ও দুর্বলতা থেকে তিনি মুক্ত।',
      sourceReference: 'Sahih Muslim 2691',
      minRecitationSeconds: 3,
      targetRepetitions: 33,
    ),
    LearningLessonModel(
      id: 'dhikr_alhamdulillah',
      category: LearningCategory.dailyDhikr,
      title: 'Tahmid (Alhamdulillah)',
      banglaTitle: 'তাহমীদ (আলহামদুলিল্লাহ)',
      arabicText: 'الْحَمْدُ لِلَّهِ',
      transliteration: 'Al-ḥamdu lillāh',
      banglaPronunciation: 'আলহামদুলিল্লাহ',
      translation: 'All praise and gratitude belong to Allah alone.',
      banglaTranslation: 'সকল প্রশংসা ও শুকরিয়া কেবলই মহান আল্লাহর জন্য।',
      sourceReference: 'Sahih Muslim 223',
      minRecitationSeconds: 3,
      targetRepetitions: 33,
    ),
    LearningLessonModel(
      id: 'dhikr_allahuakbar',
      category: LearningCategory.dailyDhikr,
      title: 'Takbir (Allahu Akbar)',
      banglaTitle: 'তাকবীর (আল্লাহু আকবার)',
      arabicText: 'اللَّهُ أَكْبَرُ',
      transliteration: 'Allāhu Akbar',
      banglaPronunciation: 'আল্লাহু আকবার',
      translation: 'Allah is the Greatest, above all in majesty.',
      banglaTranslation:
          'আল্লাহ সর্বশ্রেষ্ঠ, তাঁর মহিমা ও প্রতাপ সবকিছুর ঊর্ধ্বে।',
      sourceReference: 'Sahih al-Bukhari 6329',
      minRecitationSeconds: 3,
      targetRepetitions: 34,
    ),
    LearningLessonModel(
      id: 'dhikr_astaghfirullah',
      category: LearningCategory.dailyDhikr,
      title: 'Istighfar (Astaghfirullah)',
      banglaTitle: 'ইস্তিগফার (আস্তাগফিরুল্লাহ)',
      arabicText: 'أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ',
      transliteration: 'Astaghfirullāha wa atūbu ilayh',
      banglaPronunciation: 'আস্তাগফিরুল্লাহা ওয়া আতূবু ইলাইহি',
      translation:
          'I seek the forgiveness of Allah and I turn to Him in repentance.',
      banglaTranslation:
          'আমি আল্লাহর কাছে ক্ষমা চাই এবং তওবা করে তাঁর দিকেই প্রত্যাবর্তন করছি।',
      sourceReference: 'Sahih al-Bukhari 6307',
      minRecitationSeconds: 4,
      targetRepetitions: 100,
    ),
    LearningLessonModel(
      id: 'dhikr_salawat',
      category: LearningCategory.dailyDhikr,
      title: 'Salawat upon the Prophet ﷺ',
      banglaTitle: 'নবীজী ﷺ-এর প্রতি দরূদ',
      arabicText: 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ',
      transliteration: 'Allāhumma ṣalli ‘alā Muḥammadin wa ‘alā āli Muḥammad',
      banglaPronunciation:
          'আল্লাহুম্মা সাল্লি ‘আলা মুহাম্মাদিঁও ওয়া ‘আলা আলি মুহাম্মাদ',
      translation:
          'O Allah, bestow peace and blessings upon Muhammad and the family of Muhammad.',
      banglaTranslation:
          'হে আল্লাহ! মুহাম্মদ ﷺ এবং তাঁর বংশধরদের উপর শান্তি ও করুণা বর্ষণ করুন।',
      sourceReference: 'Sahih al-Bukhari 3370',
      minRecitationSeconds: 4,
      targetRepetitions: 10,
    ),

    // ══════════════════════════════════════════════════════════════
    // CATEGORY 2: DAILY DUAS (দৈনিক দোয়া)
    // ══════════════════════════════════════════════════════════════
    LearningLessonModel(
      id: 'dua_before_eating',
      category: LearningCategory.dailyDuas,
      title: 'Dua Before Eating',
      banglaTitle: 'খাবার শুরুর দোয়া',
      arabicText: 'بِسْمِ اللَّهِ',
      transliteration: 'Bismillāh',
      banglaPronunciation: 'বিসমিল্লাহ',
      translation: 'In the name of Allah.',
      banglaTranslation: 'আল্লাহর নামে শুরু করছি।',
      sourceReference: 'Sahih al-Bukhari 5376',
      minRecitationSeconds: 2,
    ),
    LearningLessonModel(
      id: 'dua_after_eating',
      category: LearningCategory.dailyDuas,
      title: 'Dua After Eating',
      banglaTitle: 'খাবার সমাপ্তির দোয়া',
      arabicText:
          'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنِي هَذَا وَرَزَقَنِيهِ مِنْ غَيْرِ حَوْلٍ مِنِّي وَلَا قُوَّةٍ',
      transliteration:
          'Al-ḥamdu lillāhilladhī aṭ‘amanī hādhā wa razaqanīhi min ghayri ḥawlin minnī wa lā quwwah',
      banglaPronunciation:
          'আলহামদু লিল্লাহিল্লাযী আত‘আমানী হাযা ওয়া রাযাকানীহি মিন গাইরি হাওলিম মিন্নী ওয়ালা কুওয়াহ',
      translation:
          'Praise belongs to Allah Who has fed me this and provided it for me without any strength or power on my part.',
      banglaTranslation:
          'সকল প্রশংসা সেই আল্লাহর, যিনি আমাকে এটি আহার করালেন এবং আমার কোনো শক্তি ও সামর্থ্য ছাড়াই আমাকে রিযিক দিলেন।',
      sourceReference: 'Sunan Abi Dawud 4023 (Sahih by Al-Albani)',
      minRecitationSeconds: 6,
    ),
    LearningLessonModel(
      id: 'dua_before_sleeping',
      category: LearningCategory.dailyDuas,
      title: 'Dua Before Sleeping',
      banglaTitle: 'ঘুমানোর পূর্বের দোয়া',
      arabicText: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
      transliteration: 'Bismika Allāhumma amūtu wa aḥyā',
      banglaPronunciation: 'বিসমিকাল্লাহুম্মা আমূতু ওয়া আহইয়া',
      translation: 'In Your name, O Allah, I die and I live.',
      banglaTranslation:
          'হে আল্লাহ! আপনারই নামে আমি শয়ন (মৃত্যুবরণ) করি এবং আপনারই ইচ্ছায় জাগ্রত (জীবিত) হই।',
      sourceReference: 'Sahih al-Bukhari 6312',
      minRecitationSeconds: 3,
    ),
    LearningLessonModel(
      id: 'dua_after_waking',
      category: LearningCategory.dailyDuas,
      title: 'Dua Upon Waking Up',
      banglaTitle: 'ঘুম থেকে ওঠার দোয়া',
      arabicText:
          'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
      transliteration:
          'Al-ḥamdu lillāhilladhī aḥyānā ba‘da mā amātanā wa ilayhin-nushūr',
      banglaPronunciation:
          'আলহামদু লিল্লাহিল্লাযী আহইয়ানা বা‘দা মা আমাতানা ওয়া ইলাইহিন নুশূর',
      translation:
          'Praise be to Allah Who brought us to life after having caused us to die, and unto Him is the resurrection.',
      banglaTranslation:
          'সমস্ত প্রশংসা আল্লাহর, যিনি আমাদের নির্জীব (ঘুমন্ত) করার পর পুনরায় জীবিত করলেন, আর তাঁরই দিকে আমাদের পুনরুত্থান।',
      sourceReference: 'Sahih al-Bukhari 6312',
      minRecitationSeconds: 5,
    ),
    LearningLessonModel(
      id: 'dua_entering_home',
      category: LearningCategory.dailyDuas,
      title: 'Dua Entering Home',
      banglaTitle: 'ঘরে প্রবেশের দোয়া',
      arabicText:
          'بِسْمِ اللَّهِ وَلَجْنَا، وَبِسْمِ اللَّهِ خَرَجْنَا، وَعَلَى رَبِّنَا تَوَكَّلْنَا',
      transliteration:
          'Bismillāhi walajnā, wa bismillāhi kharajnā, wa ‘alā rabbinā tawakkalnā',
      banglaPronunciation:
          'বিসমিল্লাহি ওয়ালাজনা, ওয়া বিসমিল্লাহি খারাজনা, ওয়া ‘আলা রাব্বিনা তাওয়াক্কালনা',
      translation:
          'In the name of Allah we enter, and in the name of Allah we leave, and upon our Lord we rely.',
      banglaTranslation:
          'আল্লাহর নামে আমরা প্রবেশ করলাম, আল্লাহর নামে বের হলাম এবং আমাদের রবের ওপরই ভরসা করলাম।',
      sourceReference: 'Sunan Abi Dawud 5096',
      minRecitationSeconds: 5,
    ),
    LearningLessonModel(
      id: 'dua_leaving_home',
      category: LearningCategory.dailyDuas,
      title: 'Dua Leaving Home',
      banglaTitle: 'ঘর থেকে বের হওয়ার দোয়া',
      arabicText:
          'بِسْمِ اللَّهِ، تَوَكَّلْتُ عَلَى اللَّهِ، وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
      transliteration:
          'Bismillāhi, tawakkaltu ‘alallāh, wa lā ḥawla wa lā quwwata illā billāh',
      banglaPronunciation:
          'বিসমিল্লাহি তাওয়াক্কালতু ‘আলাল্লাহি, ওয়ালা হাওলা ওয়ালা কুওয়াতা ইল্লা বিল্লাহ',
      translation:
          'In the name of Allah, I trust in Allah; there is no might and no power except with Allah.',
      banglaTranslation:
          'আল্লাহর নামে, আল্লাহর ওপরই ভরসা করলাম। আল্লাহর তৌফিক ও সাহায্য ছাড়া কোনো শক্তি ও সামর্থ্য নেই।',
      sourceReference: 'Sunan Abi Dawud 5095 (Sahih)',
      minRecitationSeconds: 5,
    ),
    LearningLessonModel(
      id: 'dua_entering_mosque',
      category: LearningCategory.dailyDuas,
      title: 'Dua Entering the Mosque',
      banglaTitle: 'মসজিদে প্রবেশের দোয়া',
      arabicText: 'اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ',
      transliteration: 'Allāhummaf-taḥ lī abwāba raḥmatik',
      banglaPronunciation: 'আল্লাহুম্মাফ তাহলী আবওয়াবা রাহমাতিক',
      translation: 'O Allah, open for me the gates of Your mercy.',
      banglaTranslation: 'হে আল্লাহ! আমার জন্য আপনার রহমতের দরজাগুলো খুলে দিন।',
      sourceReference: 'Sahih Muslim 713',
      minRecitationSeconds: 3,
    ),
    LearningLessonModel(
      id: 'dua_leaving_mosque',
      category: LearningCategory.dailyDuas,
      title: 'Dua Leaving the Mosque',
      banglaTitle: 'মসজিদ থেকে বের হওয়ার দোয়া',
      arabicText: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنْ فَضْلِكَ',
      transliteration: 'Allāhumma innī as’aluka min faḍlik',
      banglaPronunciation: 'আল্লাহুম্মা ইন্নী আসআলুকা মিন ফাদলিক',
      translation: 'O Allah, I ask You from Your bounty.',
      banglaTranslation: 'হে আল্লাহ! আমি আপনার অনুগ্রহ ও বরকত প্রার্থনা করছি।',
      sourceReference: 'Sahih Muslim 713',
      minRecitationSeconds: 3,
    ),

    // ══════════════════════════════════════════════════════════════
    // CATEGORY 3: SALAH LEARNING (নামাজ শিক্ষা)
    // ══════════════════════════════════════════════════════════════
    LearningLessonModel(
      id: 'salah_takbir',
      category: LearningCategory.salahLearning,
      title: 'Takbiratul Ihram (Opening)',
      banglaTitle: 'তাকবীরে তাহরীমা',
      arabicText: 'اللَّهُ أَكْبَرُ',
      transliteration: 'Allāhu Akbar',
      banglaPronunciation: 'আল্লাহু আকবার',
      translation: 'Allah is the Greatest.',
      banglaTranslation: 'আল্লাহ সর্বশ্রেষ্ঠ।',
      sourceReference: 'Sahih al-Bukhari 735',
      minRecitationSeconds: 2,
    ),
    LearningLessonModel(
      id: 'salah_sana',
      category: LearningCategory.salahLearning,
      title: 'Sana (Opening Supplication)',
      banglaTitle: 'ছানা (নামাজের শুরুর দোয়া)',
      arabicText:
          'سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَ، وَتَبَارَكَ اسْمُكَ، وَتَعَالَى جَدُّكَ، وَلَا إِلَهَ غَيْرُكَ',
      transliteration:
          'Subḥānakallāhumma wa biḥamdika, wa tabārakasmuka, wa ta‘ālā jadduka, wa lā ilāha ghayruk',
      banglaPronunciation:
          'সুবহানাকাল্লাহুম্মা ওয়া বিহামদিকা, ওয়া তাবারাকাসমুকা, ওয়া তা‘আলা জাদ্দুকা, ওয়া লা ইলাহা গাইরুক',
      translation:
          'Glory be to You, O Allah, and all praise. Blessed is Your name, exalted is Your majesty, and there is no deity worthy of worship besides You.',
      banglaTranslation:
          'হে আল্লাহ! আপনার প্রশংসার সাথে পবিত্রতা ঘোষণা করছি। আপনার নাম পরম বরকতময়, আপনার মর্যাদা সমুন্নত এবং আপনি ছাড়া আর কোনো উপাস্য নেই।',
      sourceReference: 'Sunan an-Nasa’i 899 (Sahih)',
      minRecitationSeconds: 6,
    ),
    LearningLessonModel(
      id: 'salah_fatihah',
      category: LearningCategory.salahLearning,
      title: 'Surah Al-Fatihah (The Opening)',
      banglaTitle: 'সূরা আল-ফাতিহা',
      arabicText:
          'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ • الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ • الرَّحْمَنِ الرَّحِيمِ • مَالِكِ يَوْمِ الدِّينِ • إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ • اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ • صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ',
      transliteration:
          'Bismillāhir-Raḥmānir-Raḥīm. Al-ḥamdu lillāhi Rabbil-‘ālamīn. Ar-Raḥmānir-Raḥīm. Māliki yawmid-dīn. Iyyāka na‘budu wa iyyāka nasta‘īn. Ihdinaṣ-ṣirāṭal-mustaqīm. Ṣirāṭalladhīna an‘amta ‘alayhim ghayril-maghḍūbi ‘alayhim wa laḍ-ḍāllīn.',
      banglaPronunciation:
          'বিসমিল্লাহির রাহমানির রাহীম। আলহামদু লিল্লাহি রাব্বিল ‘আলামীন। আর-রাহমানির রাহীম। মালিকি ইয়াওমিদ্দীন। ইয়্যাকা না‘বুদু ওয়া ইয়্যাকা নাসতা‘ঈন। ইহদিনাস সিরাতাল মুসতাকীম। সিরাতাল্লাযীনা আন‘আমতা ‘আলাইহিম গাইরিল মাগদূবি ‘আলাইহিম ওয়ালাদ্দাল্লীন।',
      translation:
          'In the name of Allah, Most Gracious, Most Merciful. All praise is due to Allah, Lord of the worlds. The Most Gracious, the Most Merciful. Master of the Day of Judgment. You alone we worship and You alone we ask for help. Guide us to the straight path: the path of those whom You have blessed, not of those who have evoked Your anger or of those who are astray.',
      banglaTranslation:
          'পরম করুণাময় অসীম দয়ালু আল্লাহর নামে। সমস্ত প্রশংসা বিশ্বজগতের প্রতিপালক আল্লাহর। যিনি পরম দয়ালু ও অতি মেহেরবান। বিচার দিবসের মালিক। আমরা কেবল আপনারই ইবাদত করি এবং আপনারই সাহায্য চাই। আমাদের সরল পথ দেখান। তাদের পথ যাদের আপনি অনুগ্রহ করেছেন; তাদের পথ নয় যারা ক্রোধের শিকার বা পথভ্রষ্ট।',
      sourceReference: 'Quran 1:1-7',
      minRecitationSeconds: 12,
    ),
    LearningLessonModel(
      id: 'salah_ruku',
      category: LearningCategory.salahLearning,
      title: 'Dhikr in Ruku (Bowing)',
      banglaTitle: 'রুকুর তাসবীহ',
      arabicText: 'سُبْحَانَ رَبِّيَ الْعَظِيمِ',
      transliteration: 'Subḥāna Rabbiyal-‘Aẓīm',
      banglaPronunciation: 'সুবহানা রাব্বিয়াল ‘আযীম',
      translation: 'Glory be to my Lord, the Most Magnificent.',
      banglaTranslation: 'আমার মহান প্রতিপালকের পবিত্রতা ও মহিমা ঘোষণা করছি।',
      sourceReference: 'Sahih Muslim 772',
      minRecitationSeconds: 3,
      targetRepetitions: 3,
    ),
    LearningLessonModel(
      id: 'salah_sujood',
      category: LearningCategory.salahLearning,
      title: 'Dhikr in Sujood (Prostration)',
      banglaTitle: 'সিজদার তাসবীহ',
      arabicText: 'سُبْحَانَ رَبِّيَ الْأَعْلَى',
      transliteration: 'Subḥāna Rabbiyal-A‘lā',
      banglaPronunciation: 'সুবহানা রাব্বিয়াল আ‘লা',
      translation: 'Glory be to my Lord, the Most High.',
      banglaTranslation:
          'আমার মহিমান্বিত সর্বোচ্চ প্রতিপালকের পবিত্রতা ঘোষণা করছি।',
      sourceReference: 'Sahih Muslim 772',
      minRecitationSeconds: 3,
      targetRepetitions: 3,
    ),
    LearningLessonModel(
      id: 'salah_tashahhud',
      category: LearningCategory.salahLearning,
      title: 'At-Tashahhud',
      banglaTitle: 'আত্তাহিয়্যাতু (তাশাহহুদ)',
      arabicText:
          'التَّحِيَّاتُ لِلَّهِ وَالصَّلَوَاتُ وَالطَّيِّبَاتُ، السَّلَامُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ، السَّلَامُ عَلَيْنَا وَعَلَى عِبَادِ اللَّهِ الصَّالِحِينَ، أَشْهَدُ أَنْ لَا إِلَهَ إِلَّا اللَّهُ وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ',
      transliteration:
          'At-taḥiyyātu lillāhi waṣ-ṣalawātu waṭ-ṭayyibāt. As-salāmu ‘alayka ayyuhan-Nabiyyu wa raḥmatullāhi wa barakātuh. As-salāmu ‘alaynā wa ‘alā ‘ibādillāhiṣ-ṣāliḥīn. Ash-hadu allā ilāha illallāhu wa ash-hadu anna Muḥammadan ‘abduhū wa rasūluh.',
      banglaPronunciation:
          'আত্তাহিয়্যাতু লিল্লাহি ওয়াস-সালাওয়াতু ওয়াত-ত্বায়্যিবাত। আস-সালামু ‘আলাইকা আইয়্যুহান নাবিয়্যু ওয়া রাহমাতুল্লাহি ওয়া বারাকাতুহু। আস-সালামু ‘আলাইনা ওয়া ‘আলা ‘ইবাদিল্লাহিস সালিহীন। আশহাদু আল-লা ইলাহা ইল্লাল্লাহু ওয়া আশহাদু আন্না মুহাম্মাদান ‘আবদুহু ওয়া রাসূলুহ।',
      translation:
          'All compliments, prayers and pure words are due to Allah. Peace be upon you, O Prophet, and the mercy of Allah and His blessings. Peace be upon us and upon the righteous servants of Allah. I bear witness that none has the right to be worshipped except Allah, and I bear witness that Muhammad is His servant and messenger.',
      banglaTranslation:
          'সমস্ত মৌখিক, শারীরিক ও আর্থিক ইবাদত আল্লাহর জন্য। হে নবী! আপনার প্রতি শান্তি, আল্লাহর রহমত ও বরকত বর্ষিত হোক। আমাদের ওপর এবং আল্লাহর সৎ বান্দাদের ওপর শান্তি বর্ষিত হোক। আমি সাক্ষ্য দিচ্ছি আল্লাহ ছাড়া সত্য কোনো উপাস্য নেই এবং মুহাম্মদ ﷺ তাঁর বান্দা ও রাসূল।',
      sourceReference: 'Sahih al-Bukhari 1202',
      minRecitationSeconds: 8,
    ),
    LearningLessonModel(
      id: 'salah_durood',
      category: LearningCategory.salahLearning,
      title: 'Durood Ibrahimiyyah',
      banglaTitle: 'দরূদে ইবরাহীম',
      arabicText:
          'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ، اللَّهُمَّ بَارِكْ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا بَارَكْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ',
      transliteration:
          'Allāhumma ṣalli ‘alā Muḥammadin wa ‘alā āli Muḥammad, kamā ṣallayta ‘alā Ibrāhīma wa ‘alā āli Ibrāhīm, innaka Ḥamīdun Majīd. Allāhumma bārik ‘alā Muḥammadin wa ‘alā āli Muḥammad, kamā bārakta ‘alā Ibrāhīma wa ‘alā āli Ibrāhīm, innaka Ḥamīdun Majīd.',
      banglaPronunciation:
          'আল্লাহুম্মা সাল্লি ‘আলা মুহাম্মাদিঁও ওয়া ‘আলা আলি মুহাম্মাদ, কামা সাল্লাইতা ‘আলা ইবরাহীমা ওয়া ‘আলা আলি ইবরাহীম, ইন্নাকা হামীদুম মাজীদ। আল্লাহুম্মা বারিক ‘আলা মুহাম্মাদিঁও ওয়া ‘আলা আলি মুহাম্মাদ, কামা বারাকতা ‘আলা ইবরাহীমা ওয়া ‘আলা আলি ইবরাহীম, ইন্নাকা হামীদুম মাজীদ।',
      translation:
          'O Allah, send prayers upon Muhammad and upon the family of Muhammad, as You sent prayers upon Ibrahim and the family of Ibrahim; indeed, You are Praiseworthy and Glorious. O Allah, send blessings upon Muhammad and upon the family of Muhammad, as You sent blessings upon Ibrahim and the family of Ibrahim; indeed, You are Praiseworthy and Glorious.',
      banglaTranslation:
          'হে আল্লাহ! মুহাম্মদ ﷺ ও তাঁর পরিবারের ওপর করুণা বর্ষণ করুন যেমন আপনি ইবরাহীম (আ.) ও তাঁর পরিবারের ওপর করেছিলেন; নিশ্চয় আপনি প্রশংসিত ও মহিমান্বিত। হে আল্লাহ! মুহাম্মদ ﷺ ও তাঁর পরিবারের ওপর বরকত দান করুন যেমন আপনি ইবরাহীম (আ.) ও তাঁর পরিবারের ওপর করেছিলেন; নিশ্চয় আপনি প্রশংসিত ও মহিমান্বিত।',
      sourceReference: 'Sahih al-Bukhari 3370',
      minRecitationSeconds: 10,
    ),
    LearningLessonModel(
      id: 'salah_dua_after',
      category: LearningCategory.salahLearning,
      title: 'Dua After Taslim',
      banglaTitle: 'সালাম ফিরানোর পর দোয়া',
      arabicText:
          'اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
      transliteration:
          'Allāhumma Antas-Salāmu wa minkas-salām, tabārakta yā Dhal-Jalāli wal-Ikrām',
      banglaPronunciation:
          'আল্লাহুম্মা আনতাস সালামু ওয়া মিনকাস সালাম, তাবারাকতা ইয়া যাল জালালি ওয়াল ইকরাম',
      translation:
          'O Allah, You are Peace and from You comes peace. Blessed are You, O Owner of majesty and honor.',
      banglaTranslation:
          'হে আল্লাহ! আপনিই শান্তিময় এবং আপনার থেকেই শান্তি আসে। আপনি কল্যাণময় ও বরকতময়, হে প্রতাপ ও মর্যাদার অধিকারী।',
      sourceReference: 'Sahih Muslim 592',
      minRecitationSeconds: 4,
    ),

    // ══════════════════════════════════════════════════════════════
    // CATEGORY 4: SHORT SURAHS (ছোট সূরাসমূহ)
    // ══════════════════════════════════════════════════════════════
    LearningLessonModel(
      id: 'surah_ikhlas',
      category: LearningCategory.shortSurahs,
      title: 'Surah Al-Ikhlas (Purity of Faith)',
      banglaTitle: 'সূরা আল-ইখলাস',
      arabicText:
          'قُلْ هُوَ اللَّهُ أَحَدٌ • اللَّهُ الصَّمَدُ • لَمْ يَلِدْ وَلَمْ يُولَدْ • وَلَمْ يَكُنْ لَهُ كُفُوًا أَحَدٌ',
      transliteration:
          'Qul Huwallāhu Aḥad. Allāhuṣ-Ṣamad. Lam yalid wa lam yūlad. Wa lam yakun lahū kufuwan aḥad.',
      banglaPronunciation:
          'কুল হুওয়াল্লাহু আহাদ। আল্লাহুস সামাদ। লাম ইয়ালিদ ওয়া লাম ইয়ূলাদ। ওয়া লাম ইয়াকুল লাহু কুফুওয়ান আহাদ।',
      translation:
          'Say, He is Allah, [who is] One. Allah, the Eternal Refuge. He neither begets nor is born. Nor is there to Him any equivalent.',
      banglaTranslation:
          'বলুন, তিনিই আল্লাহ, অদ্বিতীয়। আল্লাহ কারো মুখাপেক্ষী নন, সকলেই তাঁর মুখাপেক্ষী। তিনি কাউকে জন্ম দেননি এবং তাঁকেও জন্ম দেওয়া হয়নি। এবং তাঁর সমতুল্য কেউই নেই।',
      sourceReference: 'Quran 112:1-4',
      minRecitationSeconds: 5,
    ),
    LearningLessonModel(
      id: 'surah_falaq',
      category: LearningCategory.shortSurahs,
      title: 'Surah Al-Falaq (The Daybreak)',
      banglaTitle: 'সূরা আল-ফালাক',
      arabicText:
          'قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ • مِنْ شَرِّ مَا خَلَقَ • وَمِنْ شَرِّ غَاسِقٍ إِذَا وَقَبَ • وَمِنْ شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ • وَمِنْ شَرِّ حَاسِدٍ إِذَا حَسَدَ',
      transliteration:
          'Qul a‘ūdhu bi-Rabbil-falaq. Min sharri mā khalaq. Wa min sharri ghāsiqin idhā waqab. Wa min sharrin-naffāthāti fil-‘uqad. Wa min sharri ḥāsidin idhā ḥasad.',
      banglaPronunciation:
          'কুল আ‘উযু বিরাব্বিল ফালাক। মিন শাররি মা খালাক। ওয়া মিন শাররি গাসিকিন ইযা ওয়াকাব। ওয়া মিন শাররিন নাফ্ফাছাতি ফিল ‘উকাদ। ওয়া মিন শাররি হাসিদিন ইযা হাসাদ।',
      translation:
          'Say, I seek refuge in the Lord of daybreak. From the evil of that which He created. And from the evil of darkness when it settles. And from the evil of the blowers in knots. And from the evil of an envier when he envies.',
      banglaTranslation:
          'বলুন, আমি আশ্রয় প্রার্থনা করছি প্রভাতের রবের কাছে। তাঁর সৃষ্টির সকল অনিষ্ট থেকে। অন্ধকার রাতের অনিষ্ট থেকে যখন তা সমাগত হয়। এবং গিরায় ফুঁকদানকারিণীদের অনিষ্ট থেকে। এবং হিংসুকের অনিষ্ট থেকে যখন সে হিংসা করে।',
      sourceReference: 'Quran 113:1-5',
      minRecitationSeconds: 7,
    ),
    LearningLessonModel(
      id: 'surah_nas',
      category: LearningCategory.shortSurahs,
      title: 'Surah An-Nas (Mankind)',
      banglaTitle: 'সূরা আন-নাস',
      arabicText:
          'قُلْ أَعُوذُ بِرَبِّ النَّاسِ • مَلِكِ النَّاسِ • إِلَهِ النَّاسِ • مِنْ شَرِّ الْوَسْوَاسِ الْخَنَّاسِ • الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ • مِنَ الْجِنَّةِ وَالنَّاسِ',
      transliteration:
          'Qul a‘ūdhu bi-Rabbin-nās. Malikin-nās. Ilāhin-nās. Min sharril-waswāsil-khannās. Alladhī yuwaswisu fī ṣudūrin-nās. Minal-jinnati wan-nās.',
      banglaPronunciation:
          'কুল আ‘উযু বিরাব্বিন নাস। মালিকিন নাস। ইলাহিন নাস। মিন শাররিল ওয়াসওয়াসিল খান্নাস। আল্লাযী ইউওয়াসউইসু ফী সুদূরিন নাস। মিনাল জিন্নাতি ওয়ান নাস।',
      translation:
          'Say, I seek refuge in the Lord of mankind. The Sovereign of mankind. The God of mankind. From the evil of the retreating whisperer — who whispers into the breasts of mankind — from among the jinn and mankind.',
      banglaTranslation:
          'বলুন, আমি আশ্রয় প্রার্থনা করছি মানুষের প্রতিপালকের কাছে। মানুষের অধিপতির কাছে। মানুষের সত্য উপাস্যের কাছে। আত্মগোপনকারী কুমন্ত্রণাদাতার অনিষ্ট থেকে—যে মানুষের অন্তরে কুমন্ত্রণা দেয়—জিন ও মানুষের মধ্য থেকে।',
      sourceReference: 'Quran 114:1-6',
      minRecitationSeconds: 8,
    ),
    LearningLessonModel(
      id: 'surah_kawthar',
      category: LearningCategory.shortSurahs,
      title: 'Surah Al-Kawthar (Abundance)',
      banglaTitle: 'সূরা আল-কাওসার',
      arabicText:
          'إِنَّا أَعْطَيْنَاكَ الْكَوْثَرَ • فَصَلِّ لِرَبِّكَ وَانْحَرْ • إِنَّ شَانِئَكَ هُوَ الْأَبْتَرُ',
      transliteration:
          'Innā a‘ṭaynākal-kawthar. Faṣalli li-Rabbika wanḥar. Inna shāni’aka huwal-abtar.',
      banglaPronunciation:
          'ইন্না আ‘ত্বাইনাকাল কাওসার। ফাসাল্লি লিরাব্বিকা ওয়ানহার। ইন্না শানি’আকা হুওয়াল আবতার।',
      translation:
          'Indeed, We have granted you, [O Muhammad], al-Kawthar. So pray to your Lord and sacrifice. Indeed, your enemy is the one cut off.',
      banglaTranslation:
          'নিশ্চয় আমি আপনাকে কাওসার (অফুরন্ত কল্যাণ) দান করেছি। অতএব আপনার রবের উদ্দেশ্যে নামাজ পড়ুন ও কোরবানি করুন। নিশ্চয় আপনার শত্রুই তো নির্বংশ।',
      sourceReference: 'Quran 108:1-3',
      minRecitationSeconds: 5,
    ),
    LearningLessonModel(
      id: 'surah_asr',
      category: LearningCategory.shortSurahs,
      title: 'Surah Al-Asr (The Declining Day)',
      banglaTitle: 'সূরা আল-আসর',
      arabicText:
          'وَالْعَصْرِ • إِنَّ الْإِنْسَانَ لَفِي خُسْرٍ • إِلَّا الَّذِينَ آمَنُوا وَعَمِلُوا الصَّالِحَاتِ وَتَوَاصَوْا بِالْحَقِّ وَتَوَاصَوْا بِالصَّبْرِ',
      transliteration:
          'Wal-‘aṣr. Innal-insāna lafī khusr. Illalladhīna āmanū wa ‘amiluṣ-ṣāliḥāti wa tawāṣaw bil-ḥaqqi wa tawāṣaw biṣ-ṣabr.',
      banglaPronunciation:
          'ওয়াল ‘আসর। ইন্নাল ইনসানা লাফী খুসর। ইল্লাল্লাযীনা আমানূ ওয়া ‘আমিলুস সালিহাতি ওয়া তাওয়াসাও বিলহাক্কি ওয়া তাওয়াসাও বিসসাবর।',
      translation:
          'By time, indeed, mankind is in loss, except for those who have believed and done righteous deeds and advised each other to truth and advised each other to patience.',
      banglaTranslation:
          'সময়ের শপথ! নিশ্চয় সমগ্র মানবজাতি ক্ষতির মধ্যে নিমজ্জিত। তারা ব্যতীত যারা ঈমান এনেছে, সৎকাজ করেছে এবং পরস্পরকে সত্যের ও ধৈর্যের উপদেশ দিয়েছে।',
      sourceReference: 'Quran 103:1-3',
      minRecitationSeconds: 6,
    ),
    LearningLessonModel(
      id: 'surah_nasr',
      category: LearningCategory.shortSurahs,
      title: 'Surah An-Nasr (The Divine Help)',
      banglaTitle: 'সূরা আন-নাসর',
      arabicText:
          'إِذَا جَاءَ نَصْرُ اللَّهِ وَالْفَتْحُ • وَرَأَيْتَ النَّاسَ يَدْخُلُونَ فِي دِينِ اللَّهِ أَفْوَاجًا • فَسَبِّحْ بِحَمْدِ رَبِّكَ وَاسْتَغْفِرْهُ إِنَّهُ كَانَ تَوَّابًا',
      transliteration:
          'Idhā jā’a naṣrullāhi wal-fatḥ. Wa ra’aytan-nāsa yadkhulūna fī dīnillāhi afwājā. Fa-sabbiḥ bi-ḥamdi Rabbika wastaghfirh, innahū kāna Tawwābā.',
      banglaPronunciation:
          'ইযা জা’আ নাসরুল্লাহি ওয়াল ফাতহ। ওয়া রাআইতান নাসা ইয়াদখুলূনা ফী দীনিল্লাহি আফওয়াজা। ফাসাব্বিহ বিহামদি রাব্বিকা ওয়াসতাগফিরহু, ইন্নাহূ কানা তাওওয়াবা।',
      translation:
          'When the victory of Allah has come and the conquest, and you see the people entering into the religion of Allah in multitudes, then exalt [Him] with praise of your Lord and ask forgiveness of Him. Indeed, He is ever Accepting of repentance.',
      banglaTranslation:
          'যখন আল্লাহর সাহায্য ও বিজয় আসবে, এবং আপনি মানুষকে দলে দলে আল্লাহর দ্বীনে প্রবেশ করতে দেখবেন, তখন আপনার রবের প্রশংসাসহ পবিত্রতা বর্ণনা করুন এবং তাঁর কাছে ক্ষমা প্রার্থনা করুন; নিশ্চয় তিনি মহা তওবা কবুলকারী।',
      sourceReference: 'Quran 110:1-3',
      minRecitationSeconds: 7,
    ),
    LearningLessonModel(
      id: 'surah_kafirun',
      category: LearningCategory.shortSurahs,
      title: 'Surah Al-Kafirun (The Disbelievers)',
      banglaTitle: 'সূরা আল-কাফিরুন',
      arabicText:
          'قُلْ يَا أَيُّهَا الْكَافِرُونَ • لَا أَعْبُدُ مَا تَعْبُدُونَ • وَلَا أَنْتُمْ عَابِدُونَ مَا أَعْبُدُ • وَلَا أَنَا عَابِدٌ مَا عَبَدْتُّمْ • وَلَا أَنْتُمْ عَابِدُونَ مَا أَعْبُدُ • لَكُمْ دِينُكُمْ وَلِيَ دِينِ',
      transliteration:
          'Qul yā ayyuhal-kāfirūn. Lā a‘budu mā ta‘budūn. Wa lā antum ‘ābidūna mā a‘bud. Wa lā ana ‘ābidum-mā ‘abattum. Wa lā antum ‘ābidūna mā a‘bud. Lakum dīnukum wa liya dīn.',
      banglaPronunciation:
          'কুল ইয়া আইয়্যুহাল কাফিরূন। লা আ‘বুদু মা তা‘বুদূন। ওয়া লা আনতুম ‘আবিদূনা মা আ‘বুদ। ওয়া লা আনা ‘আবিদুম মা ‘আবাওতুম। ওয়া লা আনতুম ‘আবিদূনা মা আ‘বুদ। লাকুম দীনুকুম ওয়ালিয়া দীন।',
      translation:
          'Say, O disbelievers, I do not worship what you worship. Nor are you worshippers of what I worship. Nor will I be a worshipper of what you worship. Nor will you be worshippers of what I worship. For you is your religion, and for me is my religion.',
      banglaTranslation:
          'বলুন, হে কাফেররা! আমি তার ইবাদত করি না যার ইবাদত তোমরা কর। আর তোমরাও তাঁর ইবাদতকারী নও যাঁর ইবাদত আমি করি। এবং আমি তার ইবাদতকারী নই যার ইবাদত তোমরা করে আসছ। আর তোমরাও তাঁর ইবাদতকারী নও যাঁর ইবাদত আমি করি। তোমাদের জন্য তোমাদের দ্বীন, আর আমার জন্য আমার দ্বীন।',
      sourceReference: 'Quran 109:1-6',
      minRecitationSeconds: 8,
    ),
  ];
}
