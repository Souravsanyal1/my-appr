import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/language_service.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageService = LanguageService.to;

    return Obx(() {
      final isBn = languageService.isBangla;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableHeight = constraints.maxHeight;
              final isShortScreen = availableHeight < 700;
              final isVeryShortScreen = availableHeight < 600;

              final mockupHeight = isVeryShortScreen
                  ? 140.0
                  : (isShortScreen ? 175.0 : 220.0);
              final mockupWidth = isVeryShortScreen
                  ? 120.0
                  : (isShortScreen ? 145.0 : 170.0);
              final iconBoxSize = isVeryShortScreen
                  ? 38.0
                  : (isShortScreen ? 44.0 : 50.0);
              final iconSize = isVeryShortScreen
                  ? 20.0
                  : (isShortScreen ? 24.0 : 28.0);
              final sectionSpacing = isVeryShortScreen
                  ? 12.0
                  : (isShortScreen ? 18.0 : 32.0);
              final headlineFontSize = isVeryShortScreen
                  ? 20.0
                  : (isShortScreen ? 23.0 : 26.0);

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 12.0,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Top Bar: Interactive Language pill
                            Align(
                              alignment: Alignment.topRight,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => languageService
                                      .showLanguageSelector(context),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
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
                                          Icons.keyboard_arrow_down,
                                          size: 16,
                                          color: AppColors.textSecondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Center hero: Mockup + Headline + Description
                            Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: isVeryShortScreen ? 8.0 : 16.0,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Phone Preview Mockup Graphic
                                  Container(
                                    width: mockupWidth,
                                    height: mockupHeight,
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: AppColors.border,
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primaryGreen
                                              .withValues(alpha: 0.18),
                                          blurRadius: 28,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: iconBoxSize,
                                          height: iconBoxSize,
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryGreen
                                                .withValues(alpha: 0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.self_improvement,
                                            color: AppColors.brightGreen,
                                            size: iconSize,
                                          ),
                                        ),
                                        SizedBox(
                                          height: isVeryShortScreen ? 6 : 10,
                                        ),
                                        Text(
                                          isBn
                                              ? 'বিরতি ও আমল'
                                              : 'Pause & Recite',
                                          style: TextStyle(
                                            fontSize: isVeryShortScreen
                                                ? 11
                                                : 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        SizedBox(
                                          height: isVeryShortScreen ? 4 : 6,
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.brightGreen
                                                .withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            isBn ? 'অ্যাপ আনলক' : 'Unlock Apps',
                                            style: TextStyle(
                                              fontSize: isVeryShortScreen
                                                  ? 9
                                                  : 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.brightGreen,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(height: sectionSpacing),

                                  // Main Headline
                                  Text(
                                    isBn
                                        ? 'স্ক্রিন টাইমকে আবার\nঅর্থপূর্ণ করে তুলুন'
                                        : 'Make your screen time\nmeaningful again',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: headlineFontSize,
                                      fontWeight: FontWeight.bold,
                                      height: 1.25,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Description
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                    ),
                                    child: Text(
                                      isBn
                                          ? 'অন্য অ্যাপে ঢোকার আগে একটি ছোট ইসলামিক আমল সম্পন্ন করুন।'
                                          : 'Do a short Islamic learning task before opening distracting apps.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: isVeryShortScreen ? 13 : 14,
                                        height: 1.35,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Bottom Action CTA & Footer
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          Get.toNamed('/choose-apps'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryGreen,
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            28,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              isBn
                                                  ? 'শুরু করা যাক'
                                                  : "Let's get started",
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    isBn
                                        ? 'চালিয়ে যাওয়ার মাধ্যমে আপনি শর্তাবলী ও গোপনীয়তা নীতিতে সম্মত হচ্ছেন'
                                        : 'By continuing, you agree to Terms & Privacy Policy',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    });
  }
}
