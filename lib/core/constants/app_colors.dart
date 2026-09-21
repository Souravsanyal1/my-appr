import 'package:flutter/material.dart';

class AppColors {
  // DeenFlow Minimalist iOS-Style Charcoal-Green Palette
  static const Color background = Color(0xFF08100D);
  static const Color surface = Color(0xFF0E1713);
  static const Color surfaceLight = Color(0xFF15221C);
  static const Color cardBackground = surface;

  static const Color primaryGreen = Color(0xFF28C878);
  static const Color brightGreen = Color(0xFF39E28A);
  static const Color darkGreen = Color(0xFF176B45);

  static const Color textPrimary = Color(0xFFF5F7F5);
  static const Color textSecondary = Color(0xFF9BA7A1);
  static const Color textMuted = Color(0xFF66736D);

  static const Color border = Color(0xFF23342C);
  static const Color error = Color(0xFFFF6B6B);
  static const Color warning = Color(0xFFF6C85F);

  // Aliases for compatibility
  static const Color darkBackground = background;
  static const Color darkSurface = surface;
  static const Color darkCard = surface;
  static const Color darkCardBorder = border;

  static const Color lightBackground = Color(0xFFF4F7F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardBorder = Color(0xFFE2E8E5);

  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color secondaryGold = Color(0xFFD4AF37);
  static const Color primaryGoldLight = Color(0xFFF3E5AB);
  static const Color primaryEmerald = primaryGreen;
  static const Color emerald = primaryGreen;
  static const Color emeraldDark = darkGreen;
  static const Color emeraldLight = brightGreen;

  static const Color danger = error;
  static const Color dangerDark = Color(0xFFB91C1C);
  static const Color info = Color(0xFF3B82F6);
  static const Color warningLight = Color(0xFFFDE68A);

  static const Color textPrimaryDark = textPrimary;
  static const Color textSecondaryDark = textSecondary;
  static const Color textMutedDark = textMuted;

  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF4B5563);
  static const Color textMutedLight = Color(0xFF9CA3AF);

  // DeenFlow Signature Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF39E28A), Color(0xFF28C878), Color(0xFF176B45)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFF15221C), Color(0xFF0E1713)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFE5C07B), Color(0xFFD4AF37), Color(0xFFB8860B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF39E28A), Color(0xFF28C878)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = surfaceGradient;
  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFB91C1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
