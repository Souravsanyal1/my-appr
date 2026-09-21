import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/language_service.dart';
import '../../../core/widgets/arabic_text.dart';
import '../models/learning_lesson_model.dart';
import '../repositories/learning_repository.dart';

class LearningModeView extends StatefulWidget {
  const LearningModeView({super.key});

  @override
  State<LearningModeView> createState() => _LearningModeViewState();
}

class _LearningModeViewState extends State<LearningModeView> {
  bool _isPlaying = false;

  void _playAudio() async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);
    HapticFeedback.lightImpact();

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isPlaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageService = LanguageService.to;
    final lesson = Get.arguments is LearningLessonModel
        ? Get.arguments as LearningLessonModel
        : LearningRepository.allLessons.firstWhere(
            (l) => l.id == 'dhikr_astaghfirullah',
            orElse: () => LearningRepository.allLessons.first,
          );

    return Obx(() {
      final isBn = languageService.isBangla;

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: AppColors.textPrimary,
            ),
            onPressed: () => Get.back(),
          ),
          actions: [
            GestureDetector(
              onTap: () => languageService.showLanguageSelector(context),
              child: Container(
                margin: const EdgeInsets.only(right: 16),
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
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 12.0,
            ),
            child: Column(
              children: [
                Text(
                  isBn ? 'বিশুদ্ধ উচ্চারণ শিখুন' : 'Learn the pronunciation',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isBn
                      ? 'তাজবীদ ও ছন্দ আয়ত্ত করতে মনোযোগ দিয়ে শুনুন।'
                      : 'Listen first to master the rhythm and tajweed.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),

                const Spacer(),

                // Audio Playback Disc
                GestureDetector(
                  onTap: _playAudio,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isPlaying
                            ? AppColors.brightGreen
                            : AppColors.border,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGreen.withValues(
                            alpha: _isPlaying ? 0.35 : 0.12,
                          ),
                          blurRadius: 28,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _isPlaying
                            ? Icons.graphic_eq_rounded
                            : Icons.volume_up_rounded,
                        color: AppColors.brightGreen,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _isPlaying
                      ? (isBn ? 'তিলাওয়াত বাজছে...' : 'Playing recitation...')
                      : (isBn ? 'শুনতে ট্যাপ করুন' : 'Tap to listen'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 32),

                // Arabic & Pronunciation Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 26,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      ArabicText(
                        lesson.arabicText,
                        fontSize: 28,
                        color: AppColors.brightGreen,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isBn ? 'বাংলা উচ্চারণ' : 'Pronunciation',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isBn
                            ? (lesson.banglaPronunciation ??
                                  lesson.transliteration)
                            : lesson.transliteration,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '“${lesson.getTranslation(isBn)}”',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _playAudio,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Text(isBn ? 'পুনরায় শুনুন' : 'Hear Again'),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Get.offNamed('/recording'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isBn ? 'আমি প্রস্তুত' : "I'm Ready",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      );
    });
  }
}
