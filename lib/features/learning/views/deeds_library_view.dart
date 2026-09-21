import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
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
  String _selectedTab = 'All';
  final List<String> _tabs = ['All', 'Dhikr', 'Dua', 'Quran', 'Prayer'];

  List<LearningLessonModel> get _filteredLessons {
    final all = LearningRepository.allLessons;
    if (_selectedTab == 'All') return all;
    if (_selectedTab == 'Dhikr') {
      return all.where((l) => l.category == LearningCategory.dailyDhikr).toList();
    }
    if (_selectedTab == 'Dua') {
      return all.where((l) => l.category == LearningCategory.dailyDuas).toList();
    }
    if (_selectedTab == 'Quran') {
      return all.where((l) => l.category == LearningCategory.shortSurahs).toList();
    }
    if (_selectedTab == 'Prayer') {
      return all.where((l) => l.category == LearningCategory.salahLearning).toList();
    }
    return all;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Deeds Library',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Select a mindful good deed to learn and unlock.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // Horizontal Category Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _tabs.map((tab) {
                  final isSelected = _selectedTab == tab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(
                        tab,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.black : AppColors.textSecondary,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primaryGreen,
                      backgroundColor: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppColors.primaryGreen : AppColors.border,
                        ),
                      ),
                      onSelected: (_) => setState(() => _selectedTab = tab),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Deeds List
            Expanded(
              child: ListView.separated(
                itemCount: _filteredLessons.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final lesson = _filteredLessons[index];

                  return AppCard(
                    onTap: () => Get.toNamed('/deed-detail'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                lesson.category.displayName.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.brightGreen,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Text(
                              '~ ${lesson.minRecitationSeconds * 5} sec',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          lesson.title,
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
                        Text(
                          lesson.translation,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
  }
}
