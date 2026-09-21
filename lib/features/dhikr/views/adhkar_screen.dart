import 'package:flutter/material.dart';
import 'package:focus_deen/core/constants/app_colors.dart';

class AdhkarScreen extends StatelessWidget {
  const AdhkarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final morningAdhkar = [
      {
        'title': 'Ayat al-Kursi',
        'arabic': 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ...',
        'transliteration': 'Allahu la ilaha illa Huwa, Al-Hayyul-Qayyum...',
        'meaning':
            'Allah! There is no deity except Him, the Ever-Living, the Sustainer of existence.',
        'reward': 'Protected from Shaytan until evening.',
        'count': '1x',
      },
      {
        'title': 'Sayyidul Istighfar',
        'arabic':
            'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَٰهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ...',
        'transliteration':
            'Allahumma Anta Rabbi la ilaha illa Anta, khalaqtani wa ana ‘abduka...',
        'meaning':
            'O Allah, You are my Lord, there is none worthy of worship except You. You created me and I am Your servant...',
        'reward':
            'Whoever says it with conviction and dies that day will enter Jannah (Bukhari).',
        'count': '1x',
      },
      {
        'title': 'Protection from Harm',
        'arabic':
            'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ',
        'transliteration':
            'Bismillahil-ladhi la yadurru ma‘as-mihi shay’un fil-ardi wa la fis-sama’i wa Huwas-Sami‘ul-‘Alim.',
        'meaning':
            'In the Name of Allah, with Whose Name nothing can cause harm in the earth nor in the heavens...',
        'reward': 'Nothing shall harm him until evening (Abu Dawud).',
        'count': '3x',
      },
      {
        'title': 'Raditu Billahi Rabba',
        'arabic':
            'رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا',
        'transliteration':
            'Raditu billahi Rabba, wa bil-Islami dina, wa bi Muhammadin ﷺ nabiyya.',
        'meaning':
            'I am pleased with Allah as my Lord, with Islam as my religion, and with Muhammad ﷺ as my Prophet.',
        'reward':
            'Allah has promised that He will satisfy him on the Day of Resurrection.',
        'count': '3x',
      },
    ];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hisnul Muslim Adhkar'),
          bottom: const TabBar(
            indicatorColor: AppColors.primaryGold,
            labelColor: AppColors.primaryGold,
            tabs: [
              Tab(text: 'Morning Adhkar', icon: Icon(Icons.wb_sunny_outlined)),
              Tab(
                text: 'Evening Adhkar',
                icon: Icon(Icons.nightlight_round_outlined),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAdhkarList(context, morningAdhkar, isDark),
            _buildAdhkarList(
              context,
              morningAdhkar,
              isDark,
            ), // Shared collection for morning/evening
          ],
        ),
      ),
    );
  }

  Widget _buildAdhkarList(
    BuildContext context,
    List<Map<String, String>> list,
    bool isDark,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = list[index];
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? AppColors.darkCardBorder
                  : AppColors.lightCardBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item['title']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item['count']!,
                      style: const TextStyle(
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item['arabic']!,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  height: 1.6,
                  color: AppColors.primaryGold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item['transliteration']!,
                style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item['meaning']!,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.emerald,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item['reward']!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.emerald,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
