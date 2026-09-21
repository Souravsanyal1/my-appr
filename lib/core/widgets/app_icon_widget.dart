import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../features/app_selection/models/installed_app_model.dart';
import '../constants/app_colors.dart';

class AppIconWidget extends StatelessWidget {
  final InstalledAppModel? app;
  final String? packageName;
  final String? appName;
  final Uint8List? iconBytes;
  final double size;
  final double borderRadius;
  final bool isSelected;

  const AppIconWidget({
    super.key,
    this.app,
    this.packageName,
    this.appName,
    this.iconBytes,
    this.size = 44.0,
    this.borderRadius = 12.0,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePkg = (packageName ?? app?.packageName ?? '')
        .trim()
        .toLowerCase();
    final effectiveName = (appName ?? app?.appName ?? '').trim();
    final effectiveBytes = iconBytes ?? app?.iconBytes;

    if (effectiveBytes != null && effectiveBytes.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.35),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Image.memory(
            effectiveBytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) =>
                _buildFallback(effectivePkg, effectiveName),
          ),
        ),
      );
    }

    return _buildFallback(effectivePkg, effectiveName);
  }

  Widget _buildFallback(String pkg, String name) {
    final brand = _detectBrand(pkg, name);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: brand.gradient,
        color: brand.backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primaryGreen.withValues(alpha: 0.35),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Center(
        child:
            brand.iconWidget ??
            Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'A',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: size * 0.45,
                color: Colors.white,
              ),
            ),
      ),
    );
  }

  _BrandStyle _detectBrand(String pkg, String name) {
    final lowerName = name.toLowerCase();

    // TikTok
    if (pkg.contains('musically') ||
        pkg.contains('tiktok') ||
        lowerName.contains('tiktok')) {
      return _BrandStyle(
        backgroundColor: Colors.black,
        iconWidget: Icon(
          Icons.music_note_rounded,
          color: const Color(0xFF25F4EE),
          size: size * 0.55,
        ),
      );
    }

    // Instagram
    if (pkg.contains('instagram') || lowerName.contains('instagram')) {
      return _BrandStyle(
        gradient: const LinearGradient(
          colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCAF45)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        iconWidget: Icon(
          Icons.camera_alt_rounded,
          color: Colors.white,
          size: size * 0.55,
        ),
      );
    }

    // Facebook
    if (pkg.contains('facebook') ||
        pkg.contains('katana') ||
        lowerName.contains('facebook')) {
      return _BrandStyle(
        backgroundColor: const Color(0xFF1877F2),
        iconWidget: Text(
          'f',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.65,
            fontFamily: 'sans-serif',
          ),
        ),
      );
    }

    // YouTube
    if (pkg.contains('youtube') || lowerName.contains('youtube')) {
      return _BrandStyle(
        backgroundColor: const Color(0xFFFF0000),
        iconWidget: Icon(
          Icons.play_arrow_rounded,
          color: Colors.white,
          size: size * 0.65,
        ),
      );
    }

    // Reddit
    if (pkg.contains('reddit') || lowerName.contains('reddit')) {
      return _BrandStyle(
        backgroundColor: const Color(0xFFFF4500),
        iconWidget: Icon(
          Icons.forum_rounded,
          color: Colors.white,
          size: size * 0.55,
        ),
      );
    }

    // Snapchat
    if (pkg.contains('snapchat') || lowerName.contains('snapchat')) {
      return _BrandStyle(
        backgroundColor: const Color(0xFFFFFC00),
        iconWidget: Icon(
          Icons.sentiment_very_satisfied_rounded,
          color: Colors.black,
          size: size * 0.55,
        ),
      );
    }

    // WhatsApp
    if (pkg.contains('whatsapp') || lowerName.contains('whatsapp')) {
      return _BrandStyle(
        backgroundColor: const Color(0xFF25D366),
        iconWidget: Icon(
          Icons.chat_bubble_rounded,
          color: Colors.white,
          size: size * 0.55,
        ),
      );
    }

    // Twitter / X
    if (pkg.contains('twitter') ||
        lowerName == 'x' ||
        lowerName.contains('twitter')) {
      return _BrandStyle(
        backgroundColor: Colors.black,
        iconWidget: Text(
          '𝕏',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.55,
          ),
        ),
      );
    }

    // Telegram
    if (pkg.contains('telegram') || lowerName.contains('telegram')) {
      return _BrandStyle(
        backgroundColor: const Color(0xFF24A1DE),
        iconWidget: Icon(
          Icons.send_rounded,
          color: Colors.white,
          size: size * 0.55,
        ),
      );
    }

    // Discord
    if (pkg.contains('discord') || lowerName.contains('discord')) {
      return _BrandStyle(
        backgroundColor: const Color(0xFF5865F2),
        iconWidget: Icon(
          Icons.sports_esports_rounded,
          color: Colors.white,
          size: size * 0.55,
        ),
      );
    }

    // Default general styling
    return _BrandStyle(
      gradient: LinearGradient(
        colors: [
          isSelected
              ? AppColors.primaryGreen.withValues(alpha: 0.4)
              : AppColors.surfaceLight,
          isSelected ? AppColors.primaryGreen : AppColors.surface,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      iconWidget: null,
    );
  }
}

class _BrandStyle {
  final Color? backgroundColor;
  final Gradient? gradient;
  final Widget? iconWidget;

  _BrandStyle({this.backgroundColor, this.gradient, this.iconWidget});
}
