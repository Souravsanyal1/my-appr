import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/services/language_service.dart';
import '../../../core/widgets/glowing_action_button.dart';

class IntentionScreen extends StatefulWidget {
  const IntentionScreen({super.key});

  @override
  State<IntentionScreen> createState() => _IntentionScreenState();
}

class _IntentionScreenState extends State<IntentionScreen> {
  double _elapsedSeconds = 0.0;
  Timer? _holdTimer;
  bool _isCompleted = false;

  void _startHolding() {
    if (_isCompleted) return;
    _holdTimer?.cancel();
    _holdTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _elapsedSeconds += 0.1;
        if (_elapsedSeconds >= 3.0) {
          _elapsedSeconds = 3.0;
          _isCompleted = true;
          _holdTimer?.cancel();
          HapticFeedback.heavyImpact();

          // Advance to Intention Complete screen
          Future.delayed(const Duration(milliseconds: 500), () {
            if (!mounted) return;
            Get.offNamed('/intention-complete');
          });
        }
      });
    });
  }

  void _cancelHolding() {
    if (_isCompleted) return;
    _holdTimer?.cancel();
    if (mounted) {
      setState(() {
        _elapsedSeconds = 0.0;
      });
    }
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageService = LanguageService.to;
    final progress = (_elapsedSeconds / 3.0).clamp(0.0, 1.0);

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
              // Top indicator bar
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Headline & Subtitle
              Text(
                isBn ? 'নিয়ত নির্ধারণ করুন' : 'Set your intention',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                isBn
                    ? 'আল্লাহর সন্তুষ্টির উদ্দেশ্যে ৩ সেকেন্ড চেপে ধরে রাখুন।'
                    : 'Hold the button for 3 seconds\nto set your intention for Allah.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),

              const Spacer(),

              // Center Glowing Action Button with Hold interaction
              GlowingActionButton(
                icon: _isCompleted
                    ? Icons.check_rounded
                    : Icons.pan_tool_rounded,
                size: context.responsiveSize(110, minSize: 90, maxSize: 130),
                progress: progress,
                state: _isCompleted
                    ? GlowingButtonState.success
                    : (_elapsedSeconds > 0
                          ? GlowingButtonState.holding
                          : GlowingButtonState.idle),
                subtitle: _isCompleted
                    ? (isBn ? 'নিয়ত সম্পন্ন ✓' : 'Intent set ✓')
                    : '${_elapsedSeconds.toStringAsFixed(1)} / 3.0s',
                onLongPressStart: _startHolding,
                onLongPressEnd: _cancelHolding,
                onTap: () {
                  if (!_isCompleted && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isBn
                              ? 'নিয়ত নির্ধারণ করতে অনুগ্রহ করে ৩ সেকেন্ড চেপে ধরে রাখুন।'
                              : 'Please press and hold for 3 seconds to set your intention.',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),

              const Spacer(),

              // Hint
              Text(
                _isCompleted
                    ? (isBn
                          ? 'আমলে নিয়ে যাওয়া হচ্ছে...'
                          : 'Moving to your recitation...')
                    : (isBn
                          ? 'মনোযোগ সহকারে চেপে ধরে রাখুন'
                          : 'Press and hold to focus'),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      );
    });
  }
}
