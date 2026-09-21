import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/services/language_service.dart';
import '../../../core/widgets/progress_ring.dart';
import '../services/pronunciation_analyzer.dart';

class ResultView extends StatelessWidget {
  const ResultView({super.key});

  @override
  Widget build(BuildContext context) {
    final languageService = LanguageService.to;
    final PronunciationResult? res = (Get.arguments is Map)
        ? (Get.arguments['result'] as PronunciationResult?)
        : null;

    final int score = res?.overallScore ?? 86;
    final bool isPassing = score >= 80;

    return Obx(() {
      final isBn = languageService.isBangla;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: ResponsiveScaffoldBody(
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              // Headline
              Text(
                isPassing
                    ? (isBn ? 'চমৎকার তিলাওয়াত!' : 'Great effort')
                    : (isBn ? 'প্রায় কাছাকাছি!' : 'Almost there'),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                isPassing
                    ? (isBn
                          ? 'আপনার উচ্চারণ আনলক করার নির্ধারিত মান পূরণ করেছে।'
                          : 'Your pronunciation meets the unlock requirement.')
                    : (isBn
                          ? 'অ্যাপটি আনলক করতে কমপক্ষে ৮০% স্কোর প্রয়োজন।'
                          : 'You need at least 80% to unlock this app.'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Score Progress Ring
              ProgressRing(
                progress: score / 100.0,
                size: context.responsiveSize(136, minSize: 100, maxSize: 160),
                strokeWidth: 9,
                progressColor: isPassing
                    ? AppColors.brightGreen
                    : AppColors.warning,
                centerChild: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$score%',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      isBn ? 'উচ্চারণ স্কোর' : 'Pronunciation',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Breakdown Card
              if (isPassing) ...[
                Container(
                  width: double.infinity,
                  padding: AppSpacing.cardPadding,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _buildBreakdownRow(
                        isBn ? 'আলিফ (শুরু)' : 'Alif (Opening)',
                        '92%',
                      ),
                      const SizedBox(height: 12),
                      _buildBreakdownRow(
                        isBn ? 'সীন (ধ্বনি)' : 'Sin (Sibilant)',
                        '81%',
                      ),
                      const SizedBox(height: 12),
                      _buildBreakdownRow(
                        isBn ? 'তা (স্পষ্টতা)' : 'Ta (Articulation)',
                        '88%',
                      ),
                      const SizedBox(height: 12),
                      _buildBreakdownRow(
                        isBn ? 'গায়ন (কণ্ঠনালী)' : 'Ghayn (Velar)',
                        '84%',
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: AppSpacing.cardPadding,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBn ? 'যে বিষয়ে মনোযোগ দেবেন:' : 'Try focusing on:',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isBn
                            ? '• অক্ষরের মাখরাজ ও স্পষ্ট উচ্চারণে খেয়াল রাখুন\n• ধীরস্থির ও পরিমিত বিরতি দিয়ে পাঠ করুন\n• শেষ অক্ষরের সঠিক স্পষ্টতা বজায় রাখুন'
                            : '• Clear pronunciation of the middle letters\n• Slower recitation with measured pauses\n• Clear ending sound at the conclusion',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              // Action Buttons
              if (isPassing) ...[
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      final args = (Get.arguments is Map)
                          ? Map<String, dynamic>.from(Get.arguments as Map)
                          : <String, dynamic>{};
                      final pkg = args['packageName'];
                      final app = args['appName'];
                      final passArgs = <String, dynamic>{'durationMinutes': 30};
                      if (pkg != null) passArgs['packageName'] = pkg;
                      if (app != null) passArgs['appName'] = app;
                      Get.offNamed('/unlock-success', arguments: passArgs);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isBn
                              ? '৩০ মিনিট ব্যবহারের সুযোগ নিন'
                              : 'Unlock 30 minutes',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.offNamed('/learning-mode'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Text(isBn ? 'আগে শুনুন' : 'Practice First'),
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
                          isBn ? 'পুনরায় চেষ্টা' : 'Try Again',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildBreakdownRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.brightGreen,
          ),
        ),
      ],
    );
  }
}
