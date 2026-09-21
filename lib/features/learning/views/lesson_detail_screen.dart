import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/language_service.dart';
import '../../../core/services/native_bridge_service.dart';
import '../../unlock/views/unlock_screen.dart';
import '../controllers/learning_controller.dart';
import '../models/learning_lesson_model.dart';

class LessonDetailScreen extends StatefulWidget {
  final LearningLessonModel lesson;

  const LessonDetailScreen({super.key, required this.lesson});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  bool _isPlayingAudio = false;
  int _repetitionCount = 0;
  StreamSubscription<bool>? _audioSub;

  @override
  void initState() {
    super.initState();
    final nativeBridge = Get.find<NativeBridgeService>();
    _audioSub = nativeBridge.ttsStateStream.listen((playing) {
      if (mounted) {
        setState(() => _isPlayingAudio = playing);
      }
    });
  }

  @override
  void dispose() {
    _audioSub?.cancel();
    Get.find<NativeBridgeService>().stopSpeaking();
    super.dispose();
  }

  void _simulateAudioPlayback() async {
    final nativeBridge = Get.find<NativeBridgeService>();
    if (_isPlayingAudio) {
      await nativeBridge.stopSpeaking();
      if (mounted) setState(() => _isPlayingAudio = false);
      return;
    }

    setState(() => _isPlayingAudio = true);
    HapticFeedback.lightImpact();

    final isBn = LanguageService.to.isBangla;
    final audioUrl = widget.lesson.audioUrl ?? '';
    final arabic = widget.lesson.arabicText.trim();
    final fallbackPhonetic = isBn
        ? (widget.lesson.banglaPronunciation ??
              widget.lesson.banglaTitle ??
              widget.lesson.transliteration)
        : widget.lesson.transliteration;

    if (audioUrl.isNotEmpty) {
      await nativeBridge.playAudio(
        url: audioUrl,
        fallbackText: arabic.isNotEmpty ? arabic : fallbackPhonetic,
        language: 'ar',
        fallbackPhonetic: fallbackPhonetic,
      );
    } else if (arabic.isNotEmpty) {
      await nativeBridge.speak(
        text: arabic,
        language: 'ar',
        rate: 0.75,
        fallbackPhonetic: fallbackPhonetic,
      );
    } else {
      await nativeBridge.speak(
        text: fallbackPhonetic,
        language: isBn ? 'bn' : 'en',
        rate: 0.85,
      );
    }
  }

  void _incrementRepetition() {
    setState(() {
      _repetitionCount++;
      if (_repetitionCount >= widget.lesson.targetRepetitions) {
        final controller = Get.find<LearningController>();
        controller.markLessonCompleted(widget.lesson.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.lesson.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Audio Playback',
            icon: Icon(
              _isPlayingAudio
                  ? Icons.volume_up_rounded
                  : Icons.volume_mute_rounded,
              color: _isPlayingAudio ? AppColors.secondaryGold : null,
            ),
            onPressed: _simulateAudioPlayback,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category & Source Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryEmerald.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.lesson.category.displayName.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryEmerald,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.lesson.sourceReference,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondaryGold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Arabic Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF131D19)
                    : const Color(0xFFF7FAF8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.secondaryGold.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    widget.lesson.arabicText,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 2.0,
                      color: AppColors.secondaryGold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Listen Button
                  OutlinedButton.icon(
                    onPressed: _simulateAudioPlayback,
                    icon: Icon(
                      _isPlayingAudio
                          ? Icons.graphic_eq_rounded
                          : Icons.volume_up_rounded,
                      size: 18,
                      color: AppColors.secondaryGold,
                    ),
                    label: Text(
                      _isPlayingAudio ? 'Listening...' : 'Listen Recitation',
                      style: const TextStyle(
                        color: AppColors.secondaryGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: AppColors.secondaryGold.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Transliteration Section
            const Text(
              'Transliteration',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondaryLight,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF16201C) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              child: Text(
                widget.lesson.transliteration,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Translation Section
            const Text(
              'Meaning & Translation',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondaryLight,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF16201C) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              child: Text(
                widget.lesson.translation,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),

            // Practice Counter (if applicable)
            if (widget.lesson.targetRepetitions > 1) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A2621)
                      : const Color(0xFFEDF4F0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Daily Practice Repetitions',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Target: ${widget.lesson.targetRepetitions} times • Completed: $_repetitionCount',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _incrementRepetition,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryEmerald,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      child: const Text('+ 1 Count'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Action Buttons: Practice & Record
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final controller = Get.find<LearningController>();
                      controller.markLessonCompleted(widget.lesson.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lesson marked as completed!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Mark Done'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to unlock/recitation scoring screen
                      Get.to(() => const UnlockScreen());
                    },
                    icon: const Icon(Icons.mic, size: 18),
                    label: const Text('Record Recitation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryEmerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
