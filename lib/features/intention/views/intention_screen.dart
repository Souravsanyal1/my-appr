import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
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
      setState(() {
        _elapsedSeconds += 0.1;
        if (_elapsedSeconds >= 3.0) {
          _elapsedSeconds = 3.0;
          _isCompleted = true;
          _holdTimer?.cancel();
          HapticFeedback.heavyImpact();

          // Smoothly advance to Islamic Deed screen
          Future.delayed(const Duration(milliseconds: 700), () {
            Get.offNamed('/deed-detail');
          });
        }
      });
    });
  }

  void _cancelHolding() {
    if (_isCompleted) return;
    _holdTimer?.cancel();
    setState(() {
      _elapsedSeconds = 0.0;
    });
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_elapsedSeconds / 3.0).clamp(0.0, 1.0);

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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
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
              const SizedBox(height: 32),

              // Headline & Subtitle
              const Text(
                'Set your intention',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Hold the button for 3 seconds\nto set your intention for Allah.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),

              const Spacer(),

              // Center Glowing Action Button with Hold interaction
              GlowingActionButton(
                icon: _isCompleted ? Icons.check_rounded : Icons.pan_tool_rounded,
                size: 110,
                progress: progress,
                state: _isCompleted
                    ? GlowingButtonState.success
                    : (_elapsedSeconds > 0
                        ? GlowingButtonState.holding
                        : GlowingButtonState.idle),
                subtitle: _isCompleted
                    ? 'Intent set ✓'
                    : '${_elapsedSeconds.toStringAsFixed(1)} / 3.0s',
                onLongPressStart: _startHolding,
                onLongPressEnd: _cancelHolding,
                onTap: () {
                  if (!_isCompleted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please press and hold for 3 seconds to set your intention.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),

              const Spacer(),

              // Hint
              Text(
                _isCompleted ? 'Moving to your recitation...' : 'Press and hold to focus',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
