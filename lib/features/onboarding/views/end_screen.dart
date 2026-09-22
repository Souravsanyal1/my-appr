import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/services/language_service.dart';

class EndScreenView extends StatelessWidget {
  const EndScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final languageService = LanguageService.to;

    return Obx(() {
      final isBn = languageService.isBangla;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: ResponsiveScaffoldBody(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Logo with Expanding Emerald Wave Glow
              Container(
                width: context.responsiveSize(100, minSize: 76, maxSize: 120),
                height: context.responsiveSize(100, minSize: 76, maxSize: 120),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryGreen, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withValues(alpha: 0.4),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.eco_rounded,
                    size: 48,
                    color: AppColors.brightGreen,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              const Text(
                'FocusDeen',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              Text(
                isBn
                    ? 'উত্তম অভ্যাস। আল্লাহর নৈকট্য।'
                    : 'Better habits. A closer you.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.brightGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              Text(
                isBn
                    ? 'প্রতিটি স্ক্রল হোক আত্মিক উন্নতির মাধ্যম।'
                    : 'Pause. Remember. Then Continue.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),

              const Spacer(),

              // Return Home CTA
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Get.offNamed('/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isBn ? 'মূল স্ক্রিনে ফিরে যান' : 'Continue to Dashboard',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
