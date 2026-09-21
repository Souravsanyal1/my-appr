import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/arabic_text.dart';
import '../../../core/widgets/glowing_action_button.dart';
import '../../../core/widgets/waveform_view.dart';

class RecordingView extends StatefulWidget {
  const RecordingView({super.key});

  @override
  State<RecordingView> createState() => _RecordingViewState();
}

class _RecordingViewState extends State<RecordingView> {
  bool _isRecording = false;
  double _recordingSeconds = 0.0;
  Timer? _timer;

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordingSeconds = 0.0;
    });
    HapticFeedback.mediumImpact();

    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
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

    // Advance to multi-step Analysis screen with recorded duration
    Get.offNamed('/analysis', arguments: {
      'durationSeconds': _recordingSeconds.round(),
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // Header
              const Text(
                'Recite the phrase',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Try to pronounce it clearly with calm pauses.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 48),

              // Arabic Phrase Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    ArabicText(
                      'أَسْتَغْفِرُ اللَّهَ',
                      fontSize: 36,
                      color: AppColors.brightGreen,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Astaghfirullah',
                      style: TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Live Waveform
              WaveformView(
                isRecording: _isRecording,
                height: 44,
                barCount: 22,
              ),
              const SizedBox(height: 16),

              // Timer / Status
              Text(
                _isRecording
                    ? 'Listening... ${_recordingSeconds.toStringAsFixed(1)}s'
                    : 'Tap microphone to begin',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _isRecording ? AppColors.brightGreen : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Large Circular Glowing Recording Button
              GlowingActionButton(
                icon: _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                size: 104,
                progress: _isRecording ? (_recordingSeconds / 5.0).clamp(0.0, 1.0) : 0.0,
                state: _isRecording ? GlowingButtonState.recording : GlowingButtonState.idle,
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
                _isRecording ? 'Tap stop button to evaluate' : 'Press mic and recite clearly',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
