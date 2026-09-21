import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/services/language_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/progress_ring.dart';
import '../services/pronunciation_analyzer.dart';

class AnalysisView extends StatefulWidget {
  const AnalysisView({super.key});

  @override
  State<AnalysisView> createState() => _AnalysisViewState();
}

class _AnalysisViewState extends State<AnalysisView> {
  int _progress = 0;
  int _stepIndex = 0;
  Timer? _progressTimer;

  final List<Map<String, String>> _steps = [
    {'en': 'Processing audio input...', 'bn': 'অডিও ইনপুট প্রসেস করা হচ্ছে...'},
    {'en': 'Comparing pronunciation...', 'bn': 'উচ্চারণ তুলনা করা হচ্ছে...'},
    {
      'en': 'Analyzing phonemes & tajweed...',
      'bn': 'হরফের মাখরাজ ও তাজবীদ বিশ্লেষণ হচ্ছে...',
    },
    {
      'en': 'Calculating accuracy score...',
      'bn': 'সঠিকতার স্কোর হিসাব করা হচ্ছে...',
    },
    {'en': 'Analysis complete ✓', 'bn': 'মূল্যায়ন সম্পন্ন হয়েছে ✓'},
  ];

  @override
  void initState() {
    super.initState();
    _startAnalysisSequence();
  }

  void _startAnalysisSequence() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 32), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _progress++;
        if (_progress < 25) {
          _stepIndex = 0;
        } else if (_progress < 50) {
          _stepIndex = 1;
        } else if (_progress < 75) {
          _stepIndex = 2;
        } else if (_progress < 95) {
          _stepIndex = 3;
        } else {
          _stepIndex = 4;
        }

        if (_progress >= 100) {
          _progress = 100;
          _progressTimer?.cancel();

          final durationSeconds = (Get.arguments is Map)
              ? (Get.arguments['durationSeconds'] as int? ?? 4)
              : 4;

          final storage = Get.find<StorageService>();
          final int threshold =
              storage.read<int>('unlock_score_threshold') ?? 80;

          final analyzer = LocalPronunciationAnalyzer();
          analyzer
              .analyze(
                expectedArabic: 'أَسْتَغْفِرُ اللَّهَ',
                expectedTransliteration: 'Astaghfirullah',
                durationSeconds: durationSeconds,
                minDurationSeconds: 3,
                unlockThreshold: threshold,
              )
              .then((res) {
                if (!mounted) return;
                Future.delayed(const Duration(milliseconds: 350), () {
                  if (!mounted) return;
                  final args = (Get.arguments is Map)
                      ? Map<String, dynamic>.from(Get.arguments as Map)
                      : <String, dynamic>{};
                  if (res.isPassing) {
                    Get.offNamed(
                      '/result',
                      arguments: {'result': res, ...args},
                    );
                  } else {
                    Get.offNamed(
                      '/retry-result',
                      arguments: {
                        'result': res,
                        'score': res.overallScore,
                        ...args,
                      },
                    );
                  }
                });
              });
        }
      });
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageService = LanguageService.to;

    return Obx(() {
      final isBn = languageService.isBangla;
      final stepText = isBn
          ? _steps[_stepIndex]['bn']!
          : _steps[_stepIndex]['en']!;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: ResponsiveScaffoldBody(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Headline
              Text(
                isBn
                    ? 'আপনার তিলাওয়াত\nবিশ্লেষণ করা হচ্ছে'
                    : 'Analyzing your\nrecitation',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                '◌ ◌ ◌',
                style: TextStyle(
                  fontSize: 18,
                  letterSpacing: 4.0,
                  color: AppColors.brightGreen,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Progress Ring
              ProgressRing(
                progress: _progress / 100.0,
                size: context.responsiveSize(130, minSize: 100, maxSize: 150),
                strokeWidth: 8,
                centerChild: Text(
                  '$_progress%',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Step text
              Text(
                stepText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),

              const Spacer(),

              // Bottom card
              Container(
                width: double.infinity,
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_clock,
                      size: 20,
                      color: AppColors.brightGreen,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isBn
                            ? '৮০% স্কোর অর্জিত হলে সাময়িক সময়ের জন্য অ্যাপ ব্যবহারের অনুমতি দেওয়া হবে।'
                            : 'Access pass will be granted upon reaching 80% passing threshold.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      );
    });
  }
}
