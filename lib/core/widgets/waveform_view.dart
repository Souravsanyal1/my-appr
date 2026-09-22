import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class WaveformView extends StatefulWidget {
  final bool isRecording;
  final double height;
  final int barCount;
  final double? normalizedAmplitude;

  const WaveformView({
    super.key,
    required this.isRecording,
    this.height = 42.0,
    this.barCount = 18,
    this.normalizedAmplitude,
  });

  @override
  State<WaveformView> createState() => _WaveformViewState();
}

class _WaveformViewState extends State<WaveformView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 180),
        )..addListener(() {
          if (widget.isRecording && mounted) {
            setState(() {});
          }
        });

    if (widget.isRecording) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant WaveformView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isRecording && _controller.isAnimating) {
      _controller.stop();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amp = (widget.normalizedAmplitude ?? 0.0).clamp(0.0, 1.0);
    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(widget.barCount, (index) {
          final double normalized = widget.isRecording
              ? (0.15 +
                  0.85 *
                      (amp > 0.05
                          ? (amp * (0.6 + 0.4 * _random.nextDouble()))
                          : (0.25 * _random.nextDouble())))
              : 0.15;
          final barHeight = (widget.height * normalized).clamp(
            4.0,
            widget.height,
          );

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            width: 3.5,
            height: barHeight,
            decoration: BoxDecoration(
              color: widget.isRecording
                  ? (amp > 0.05
                      ? AppColors.brightGreen
                      : AppColors.brightGreen.withValues(alpha: 0.65))
                  : AppColors.border,
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }
}
