import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

enum GlowingButtonState {
  idle,
  holding,
  recording,
  success,
  error,
}

class GlowingActionButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final double progress; // 0.0 to 1.0
  final GlowingButtonState state;
  final String? subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;

  const GlowingActionButton({
    super.key,
    required this.icon,
    this.size = 96.0,
    this.progress = 0.0,
    this.state = GlowingButtonState.idle,
    this.subtitle,
    this.onTap,
    this.onLongPressStart,
    this.onLongPressEnd,
  });

  @override
  State<GlowingActionButton> createState() => _GlowingActionButtonState();
}

class _GlowingActionButtonState extends State<GlowingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color get _glowColor {
    switch (widget.state) {
      case GlowingButtonState.error:
        return AppColors.error;
      case GlowingButtonState.success:
        return AppColors.brightGreen;
      case GlowingButtonState.recording:
        return AppColors.error;
      case GlowingButtonState.holding:
      case GlowingButtonState.idle:
      default:
        return AppColors.primaryGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPulsing = widget.state == GlowingButtonState.recording ||
        widget.state == GlowingButtonState.holding;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapDown: (_) {
            setState(() => _isPressed = true);
            HapticFeedback.lightImpact();
          },
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onTap?.call();
          },
          onTapCancel: () {
            setState(() => _isPressed = false);
          },
          onLongPressStart: (_) {
            setState(() => _isPressed = true);
            HapticFeedback.mediumImpact();
            widget.onLongPressStart?.call();
          },
          onLongPressEnd: (_) {
            setState(() => _isPressed = false);
            HapticFeedback.lightImpact();
            widget.onLongPressEnd?.call();
          },
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              final scale = _isPressed
                  ? 0.94
                  : (isPulsing ? _pulseAnimation.value : 1.0);

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      // Soft ambient glow
                      BoxShadow(
                        color: _glowColor.withOpacity(isPulsing ? 0.45 : 0.25),
                        blurRadius: isPulsing ? 32 : 20,
                        spreadRadius: isPulsing ? 8 : 2,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Circular Progress Ring
                      if (widget.progress > 0)
                        SizedBox(
                          width: widget.size,
                          height: widget.size,
                          child: CircularProgressIndicator(
                            value: widget.progress.clamp(0.0, 1.0),
                            strokeWidth: 4.5,
                            backgroundColor: AppColors.border,
                            valueColor: AlwaysStoppedAnimation<Color>(_glowColor),
                          ),
                        ),

                      // Inner solid action circle
                      Container(
                        width: widget.size - 14,
                        height: widget.size - 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: widget.state == GlowingButtonState.recording
                                ? [AppColors.error, const Color(0xFFB91C1C)]
                                : [AppColors.brightGreen, AppColors.primaryGreen],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Icon(
                          widget.icon,
                          size: widget.size * 0.42,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 14),
          Text(
            widget.subtitle!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ],
    );
  }
}
