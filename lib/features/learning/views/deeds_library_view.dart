import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/language_service.dart';
import '../../../core/widgets/arabic_text.dart';
import '../../../core/widgets/progress_ring.dart';
import '../models/learning_lesson_model.dart';
import '../repositories/learning_repository.dart';

class DeedsLibraryView extends StatefulWidget {
  const DeedsLibraryView({super.key});

  @override
  State<DeedsLibraryView> createState() => _DeedsLibraryViewState();
}

class _DeedsLibraryViewState extends State<DeedsLibraryView> {
  int _selectedCategoryIndex = 0;

  final List<Map<String, String>> _categories = [
    {'en': 'All', 'bn': 'সব'},
    {'en': 'Dhikr', 'bn': 'যিকির'},
    {'en': 'Dua', 'bn': 'দোয়া'},
    {'en': 'Quran', 'bn': 'কুরআন'},
    {'en': 'Prayer', 'bn': 'নামাজ'},
  ];

  List<LearningLessonModel> _getFilteredLessons(int index) {
    final all = LearningRepository.allLessons;
    switch (index) {
      case 1:
        return all
            .where((l) => l.category == LearningCategory.dailyDhikr)
            .toList();
      case 2:
        return all
            .where((l) => l.category == LearningCategory.dailyDuas)
            .toList();
      case 3:
        return all
            .where((l) => l.category == LearningCategory.shortSurahs)
            .toList();
      case 4:
        return all
            .where((l) => l.category == LearningCategory.salahLearning)
            .toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageService = LanguageService.to;

    return Obx(() {
      final isBn = languageService.isBangla;
      final filteredLessons = _getFilteredLessons(_selectedCategoryIndex);

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Title and Language Switcher
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBn ? 'আমল লাইব্রেরি' : 'Deeds Library',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isBn
                            ? 'শিখতে ও অ্যাপ আনলক করতে আমল বেছে নিন'
                            : 'Select a good deed to learn and unlock.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => languageService.showLanguageSelector(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isBn ? '🇧🇩 বাং' : '🇬🇧 EN',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.brightGreen,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_drop_down,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Horizontal Category Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_categories.length, (index) {
                    final cat = _categories[index];
                    final label = isBn ? (cat['bn'] ?? cat['en']!) : cat['en']!;
                    final isSelected = _selectedCategoryIndex == index;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.black
                                : AppColors.textSecondary,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primaryGreen,
                        backgroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primaryGreen
                                : AppColors.border,
                          ),
                        ),
                        onSelected: (_) =>
                            setState(() => _selectedCategoryIndex = index),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 18),

              // Deeds List
              Expanded(
                child: ListView.separated(
                  itemCount: filteredLessons.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final lesson = filteredLessons[index];

                    return AppCard(
                      onTap: () =>
                          Get.toNamed('/deed-detail', arguments: lesson),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  lesson.category
                                      .getLocalizedName(isBn)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.brightGreen,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Text(
                                isBn
                                    ? '~ ${lesson.minRecitationSeconds * 4} সেকেন্ড'
                                    : '~ ${lesson.minRecitationSeconds * 4} sec',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            lesson.getTitle(isBn),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ArabicText(
                            lesson.arabicText,
                            fontSize: 20,
                            textAlign: TextAlign.left,
                            maxLines: 1,
                            color: AppColors.brightGreen,
                          ),
                          const SizedBox(height: 8),

                          // Pronunciation (উচ্চারণ) Highlight
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.volume_up,
                                  size: 14,
                                  color: AppColors.brightGreen,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${isBn ? "উচ্চারণ: " : "Pronunciation: "}${lesson.getPronunciation(isBn)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          Text(
                            lesson.getTranslation(isBn),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
