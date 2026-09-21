import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/progress_ring.dart';
import '../services/pronunciation_analyzer.dart';

class AnalysisView extends StatefulWidget {
  const AnalysisView({super.key});

  @override
  State<AnalysisView> createState() => _AnalysisViewState();
}

class _AnalysisViewState extends State<AnalysisView> {
  int _progress = 0;
  String _currentStep = 'Checking pronunciation...';
  Timer? _progressTimer;

  final List<String> _steps = [
    'Processing audio input...',
    'Comparing pronunciation...',
    'Analyzing phonemes & words...',
    'Checking Tajweed cadence...',
    'Analysis complete ✓',
  ];

  @override
  void initState() {
    super.initState();
    _startAnalysisSequence();
  }

  void _startAnalysisSequence() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 38), (timer) {
      setState(() {
        _progress++;
        if (_progress < 25) {
          _currentStep = _steps[0];
        } else if (_progress < 50) {
          _currentStep = _steps[1];
        } else if (_progress < 75) {
          _currentStep = _steps[2];
        } else if (_progress < 95) {
          _currentStep = _steps[3];
        } else {
          _currentStep = _steps[4];
        }

        if (_progress >= 100) {
          _progress = 100;
          _progressTimer?.cancel();

          // Calculate actual analyzer result and move to result screen
          final durationSeconds = (Get.arguments is Map)
              ? (Get.arguments['durationSeconds'] as int? ?? 4)
              : 4;

          final analyzer = LocalPronunciationAnalyzer();
          analyzer.analyze(
            expectedArabic: 'أَسْتَغْفِرُ اللَّهَ',
            expectedTransliteration: 'Astaghfirullah',
            durationSeconds: durationSeconds,
            minDurationSeconds: 3,
            unlockThreshold: 80,
          ).then((res) {
            Future.delayed(const Duration(milliseconds: 400), () {
              Get.offNamed('/result', arguments: {
                'result': res,
              });
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Headline
              const Text(
                'Analyzing your\nrecitation',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '◌ ◌ ◌',
                style: TextStyle(
                  fontSize: 18,
                  letterSpacing: 4.0,
                  color: AppColors.brightGreen,
                ),
              ),
              const SizedBox(height: 56),

              // Progress Ring
              ProgressRing(
                progress: _progress / 100.0,
                size: 130,
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
              const SizedBox(height: 48),

              // Step text
              Text(
                _currentStep,
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_clock, size: 20, color: AppColors.brightGreen),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'TikTok access pass will be granted upon reaching 80% threshold.',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
