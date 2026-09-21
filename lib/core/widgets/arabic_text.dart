import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ArabicText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color? color;
  final TextAlign textAlign;
  final int? maxLines;

  const ArabicText(
    this.text, {
    super.key,
    this.fontSize = 24.0,
    this.color,
    this.textAlign = TextAlign.center,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      textDirection: TextDirection.rtl,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      style: TextStyle(
        fontFamily: 'Amiri', // Falls back gracefully to system Arabic fonts
        fontSize: fontSize,
        height: 1.9,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textPrimary,
        letterSpacing: 0.0,
      ),
    );
  }
}
