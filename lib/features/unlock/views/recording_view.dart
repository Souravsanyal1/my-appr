import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
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
  final AudioRecorder _audioRecorder = AudioRecorder();
  StreamSubscription<Amplitude>? _amplitudeSub;

  bool _isRecording = false;
  bool _isProcessing = false;
  double _recordingSeconds = 0.0;
  Timer? _timer;

  // Real audio metrics
  final List<double> _amplitudes = [];
  double _peakAmplitude = -160.0;
  double _currentNormalizedAmplitude = 0.0;
  String? _recordedFilePath;

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

  Future<void> _startRecording() async {
    if (_isProcessing) return;

    try {
      // 1. Verify / Request runtime microphone permission
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        _showPermissionDeniedMessage();
        return;
      }

      // 2. Prepare temporary audio storage path
      final tempDir = await getTemporaryDirectory();
      final String filePath =
          '${tempDir.path}/recitation_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _recordedFilePath = filePath;

      // 3. Reset acoustic tracking
      _amplitudes.clear();
      _peakAmplitude = -160.0;
      _currentNormalizedAmplitude = 0.0;

      // 4. Start native recording stream
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      // 5. Track live amplitude updates for real visualizer feedback
      _amplitudeSub = _audioRecorder
          .onAmplitudeChanged(const Duration(milliseconds: 80))
          .listen((amp) {
            if (!mounted) return;
            _amplitudes.add(amp.current);
            if (amp.max > _peakAmplitude) {
              _peakAmplitude = amp.max;
            }
            // Normalize dBFS (-60 dB to -5 dB) to 0.0..1.0 for dynamic UI waveform
            final double normalized =
                ((amp.current + 55.0) / 50.0).clamp(0.0, 1.0);
            setState(() {
              _currentNormalizedAmplitude = normalized;
            });
          });

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
    } catch (e) {
      debugPrint('Error starting audio recording: $e');
      _showErrorSnackbar(e.toString());
    }
  }

  Future<void> _stopAndAnalyze() async {
    if (!_isRecording || _isProcessing) return;
    _isProcessing = true;

    _timer?.cancel();
    await _amplitudeSub?.cancel();

    String? finalPath;
    int fileSizeBytes = 0;

    try {
      finalPath = await _audioRecorder.stop();
      if (finalPath != null && finalPath.isNotEmpty) {
        final file = File(finalPath);
        if (await file.exists()) {
          fileSizeBytes = await file.length();
        }
      }
    } catch (e) {
      debugPrint('Error stopping audio recorder: $e');
      finalPath = _recordedFilePath;
    }

    setState(() {
      _isRecording = false;
      _currentNormalizedAmplitude = 0.0;
    });
    HapticFeedback.mediumImpact();

    // Compute average amplitude
    double averageAmplitude = -160.0;
    if (_amplitudes.isNotEmpty) {
      averageAmplitude =
          _amplitudes.reduce((a, b) => a + b) / _amplitudes.length;
    }

    final existingArgs = (Get.arguments is Map)
        ? Map<String, dynamic>.from(Get.arguments as Map)
        : <String, dynamic>{};

    final lesson = Get.arguments is LearningLessonModel
        ? Get.arguments as LearningLessonModel
        : (Get.arguments is Map &&
                Get.arguments['lesson'] is LearningLessonModel)
            ? Get.arguments['lesson'] as LearningLessonModel
            : null;

    // Advance to multi-step Analysis screen with genuine audio metrics
    Get.offNamed(
      '/analysis',
      arguments: {
        ...existingArgs,
        'durationSeconds': _recordingSeconds.round(),
        'audioPath': finalPath,
        'averageAmplitude': averageAmplitude,
        'peakAmplitude': _peakAmplitude,
        'audioFileSizeBytes': fileSizeBytes,
        if (lesson != null) ...{
          'expectedArabic': lesson.arabicText,
          'expectedTransliteration': lesson.transliteration,
        },
      },
    );
  }

  void _showPermissionDeniedMessage() {
    final isBn = LanguageService.to.isBangla;
    Get.snackbar(
      isBn ? 'মাইক্রোফোন অনুমতি আবশ্যক' : 'Microphone Permission Required',
      isBn
          ? 'আপনার তিলাওয়াত রেকর্ড ও মূল্যায়নের জন্য মাইক্রোফোন পারমিশন দিন।'
          : 'Please enable microphone access in settings to evaluate recitation.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface,
      colorText: AppColors.textPrimary,
      margin: const EdgeInsets.all(AppSpacing.md),
      duration: const Duration(seconds: 4),
      icon: const Icon(Icons.mic_off_rounded, color: Colors.amberAccent),
    );
  }

  void _showErrorSnackbar(String error) {
    final isBn = LanguageService.to.isBangla;
    Get.snackbar(
      isBn ? 'রেকর্ডিং ত্রুটি' : 'Recording Error',
      isBn
          ? 'অডিও রেকর্ড শুরু করা যায়নি। পুনরায় চেষ্টা করুন।'
          : 'Could not initialize audio capture. Please try again.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface,
      colorText: AppColors.textPrimary,
      margin: const EdgeInsets.all(AppSpacing.md),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _amplitudeSub?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageService = LanguageService.to;
    final lesson = Get.arguments is LearningLessonModel
        ? Get.arguments as LearningLessonModel
        : (Get.arguments is Map &&
                Get.arguments['lesson'] is LearningLessonModel)
            ? Get.arguments['lesson'] as LearningLessonModel
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

              // Live Waveform reacting to genuine microphone audio
              WaveformView(
                isRecording: _isRecording,
                height: 44,
                barCount: 22,
                normalizedAmplitude: _currentNormalizedAmplitude,
              ),
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
