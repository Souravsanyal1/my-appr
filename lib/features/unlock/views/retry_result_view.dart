import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/services/language_service.dart';
import '../../../core/widgets/progress_ring.dart';

class RetryResultView extends StatelessWidget {
  final int score;
  final String tip;

  const RetryResultView({
    super.key,
    this.score = 68,
    this.tip = 'Focus on the throat letter (ع / غ) and avoid rushing.',
  });

  @override
  Widget build(BuildContext context) {
    final languageService = LanguageService.to;

    return Obx(() {
      final isBn = languageService.isBangla;

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
            onPressed: () => Get.offNamed('/home'),
          ),
        ),
        body: ResponsiveScaffoldBody(
          child: Column(
            children: [
              Text(
                isBn ? 'প্রায় কাছাকাছি!' : 'Almost there',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                isBn
                    ? 'আরেকটু মনোযোগ দিয়ে পাঠ করলে সহজেই উত্তীর্ণ হতে পারবেন।'
                    : 'A little more clarity will unlock your access.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Animated Red-Amber Circular Progress Ring
              ProgressRing(
                progress: (score / 100.0).clamp(0.0, 1.0),
                size: context.responsiveSize(130, minSize: 100, maxSize: 150),
                strokeWidth: 10,
                progressColor: const Color(0xFFF59E0B),
                backgroundColor: const Color(0xFF332014),
                centerChild: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score%',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFBBF24),
                      ),
                    ),
                    Text(
                      isBn ? 'লক্ষ্য ৮০%' : 'Goal: 80%',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Guidance Card
              AppCard(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          color: Color(0xFFFBBF24),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isBn ? 'উচ্চারণের টিপস' : 'Focus Tips',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isBn
                          ? 'মাখরাজ ও উচ্চারণে আরেকটু স্পষ্টতা আনুন। কণ্ঠনালীর মধ্যখান থেকে অক্ষরের সঠিক উচ্চারণ আদায় করার চেষ্টা করুন।'
                          : tip,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Primary Action: Try Again
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Get.offNamed('/recording'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isBn ? 'আবার চেষ্টা করুন' : 'Try Again',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Secondary Action: Practice First
              TextButton(
                onPressed: () => Get.offNamed('/learning-mode'),
                child: Text(
                  isBn
                      ? 'আগে বিশুদ্ধ উচ্চারণ শুনুন'
                      : 'Practice First in Learning Mode',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      );
    });
  }
}
