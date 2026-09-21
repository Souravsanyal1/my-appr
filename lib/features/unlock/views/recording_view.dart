import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/services/language_service.dart';
import '../../../core/widgets/arabic_text.dart';
import '../../../core/widgets/glowing_action_button.dart';
import '../../../core/widgets/waveform_view.dart';
import '../../learning/models/learning_lesson_model.dart';
import '../../learning/repositories/learning_repository.dart';

class RecordingView extends StatefulWidget {
  const RecordingView({super.key});

  @override
  State<RecordingView> createState() => _RecordingViewState();
}

class _RecordingViewState extends State<RecordingView>
    with WidgetsBindingObserver {
  bool _isRecording = false;
  double _recordingSeconds = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_isRecording) {
        _stopAndAnalyze();
      }
    }
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordingSeconds = 0.0;
    });
    HapticFeedback.mediumImpact();

    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _recordingSeconds += 0.1;
      });
    });
  }

  void _stopAndAnalyze() {
    if (!_isRecording) return;
    _timer?.cancel();
    setState(() => _isRecording = false);
    HapticFeedback.mediumImpact();

    final existingArgs = (Get.arguments is Map)
        ? Map<String, dynamic>.from(Get.arguments as Map)
        : <String, dynamic>{};

    // Advance to multi-step Analysis screen with recorded duration
    Get.offNamed(
      '/analysis',
      arguments: {
        ...existingArgs,
        'durationSeconds': _recordingSeconds.round(),
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
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
            icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
            onPressed: () => Get.back(),
          ),
        ),
        body: ResponsiveScaffoldBody(
          child: Column(
            children: [
              // Header
              Text(
                isBn ? 'স্পষ্ট কণ্ঠে তিলাওয়াত করুন' : 'Recite the phrase',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                isBn
                    ? 'তাজবীদ মেনে ধীরস্থিরভাবে বিশুদ্ধ উচ্চারণে পাঠ করুন।'
                    : 'Try to pronounce it clearly with calm pauses.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Arabic Phrase Card with Pronunciation
              Container(
                width: double.infinity,
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    ArabicText(
                      lesson.arabicText,
                      fontSize: 32,
                      color: AppColors.brightGreen,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isBn
                          ? (lesson.banglaPronunciation ??
                                lesson.transliteration)
                          : lesson.transliteration,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (isBn && lesson.transliteration.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        lesson.transliteration,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const Spacer(),

              // Live Waveform
              WaveformView(isRecording: _isRecording, height: 44, barCount: 22),
              const SizedBox(height: AppSpacing.md),

              // Timer / Status
              Text(
                _isRecording
                    ? (isBn
                          ? 'রেকর্ড হচ্ছে... ${_recordingSeconds.toStringAsFixed(1)}s'
                          : 'Listening... ${_recordingSeconds.toStringAsFixed(1)}s')
                    : (isBn
                          ? 'শুরু করতে মাইক্রোফোনে ট্যাপ করুন'
                          : 'Tap microphone to begin'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _isRecording
                      ? AppColors.brightGreen
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Large Circular Glowing Recording Button
              GlowingActionButton(
                icon: _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                size: context.responsiveSize(104, minSize: 84, maxSize: 120),
                progress: _isRecording
                    ? (_recordingSeconds / 5.0).clamp(0.0, 1.0)
                    : 0.0,
                state: _isRecording
                    ? GlowingButtonState.recording
                    : GlowingButtonState.idle,
                onTap: () {
                  if (!_isRecording) {
                    _startRecording();
                  } else {
                    _stopAndAnalyze();
                  }
                },
              ),

              const Spacer(),

              // Subtitle CTA
              Text(
                _isRecording
                    ? (isBn
                          ? 'মূল্যায়নের জন্য স্টপ বাটনে চাপুন'
                          : 'Tap stop button to evaluate')
                    : (isBn
                          ? 'মাইকে ট্যাপ করে স্পষ্ট স্বরে পাঠ করুন'
                          : 'Press mic and recite clearly'),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
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
