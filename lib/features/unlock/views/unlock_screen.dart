import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/gamification_service.dart';
import '../../../core/services/language_service.dart';
import '../controllers/unlock_controller.dart';

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen>
    with SingleTickerProviderStateMixin {
  late final UnlockController controller;

  // Step 0 = Suspense, Step 1 = Deed, Step 2 = Success
  int _step = 0;
  Timer? _suspenseTimer;

  late AnimationController _shimmerController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<UnlockController>()
        ? Get.find<UnlockController>()
        : Get.put(UnlockController());

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    );

    _startSuspenseCountdown();
  }

  void _startSuspenseCountdown() {
    _step = 0;
    _suspenseTimer?.cancel();
    _suspenseTimer = Timer(const Duration(milliseconds: 1900), () {
      if (mounted) {
        setState(() {
          _step = 1;
        });
      }
    });
  }

  @override
  void dispose() {
    _suspenseTimer?.cancel();
    _shimmerController.dispose();
    super.dispose();
  }

  void _onRepetitionTapped() {
    controller.incrementRepetition();
    final deed = controller.activeDeed.value;
    if (controller.repetitionCount.value >= deed.targetRepetitions) {
      // Completed deed -> Proceed to Step 2 (Success Modal)
      setState(() {
        _step = 2;
      });
      HapticFeedback.heavyImpact();
    }
  }

  void _onContinuePressed() {
    final deed = controller.activeDeed.value;
    final isBn = LanguageService.to.isBangla;
    final deedName = isBn ? deed.titleBn : deed.titleEn;

    // 1. Record deed, stack unlock time, update streak & XP in GamificationService
    GamificationService.to.recordCompletedDeed(
      deedName: deedName,
      durationMinutes: deed.rewardMinutes,
      difficulty: deed.difficulty,
    );

    // 2. Also register session in unlock controller if targeting an app
    controller.unlock(
      targetPackage: controller.packageName.value.isNotEmpty
          ? controller.packageName.value
          : 'com.all_protected.apps',
      targetAppName: controller.appName.value.isNotEmpty
          ? controller.appName.value
          : (isBn ? 'সুরক্ষিত অ্যাপসমূহ' : 'Protected Apps'),
      durationMinutes: deed.rewardMinutes,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _buildCurrentStep(),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return _buildSuspenseView();
      case 1:
        return _buildDeedView();
      case 2:
      default:
        return _buildSuccessView();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 1: SUSPENSE SCREEN (1.5–2s Shimmer / Slot-machine reveal)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSuspenseView() {
    final lang = LanguageService.to;
    final isBn = lang.isBangla;

    return Obx(() {
      final deed = controller.activeDeed.value;
      final diffColor = deed.difficulty == 'Hard'
          ? const Color(0xFFFF5252)
          : (deed.difficulty == 'Medium'
              ? const Color(0xFFFFB300)
              : AppColors.brightGreen);

      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Shimmer Slot Container
              AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 36,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: diffColor.withValues(
                          alpha: 0.3 + (_fadeAnimation.value * 0.4),
                        ),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: diffColor.withValues(
                            alpha: 0.15 + (_fadeAnimation.value * 0.2),
                          ),
                          blurRadius: 28,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Slot Icon
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: diffColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: diffColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Iconsax.magic_star,
                              size: 32,
                              color: diffColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Badges Row: Difficulty + Duration
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Difficulty Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: diffColor.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: diffColor.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Iconsax.award,
                                    size: 14,
                                    color: diffColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isBn
                                        ? (deed.difficulty == 'Easy'
                                            ? 'সহজ'
                                            : (deed.difficulty == 'Medium'
                                                ? 'মাঝারি'
                                                : 'কঠিন'))
                                        : deed.difficulty,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: diffColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Duration Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGold.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.primaryGold.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Iconsax.timer_1,
                                    size: 14,
                                    color: AppColors.primaryGold,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isBn
                                        ? '${deed.rewardMinutes} মিনিট'
                                        : '${deed.rewardMinutes} minutes',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryGold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Animated Deed Title Fade-In
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Text(
                            isBn ? deed.titleBn : deed.titleEn,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Text(
                          lang.t('finding_deed'),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),

              // Skip wait button
              TextButton.icon(
                onPressed: () {
                  _suspenseTimer?.cancel();
                  setState(() => _step = 1);
                },
                icon: const Icon(
                  Iconsax.arrow_right_3,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                label: Text(
                  isBn ? 'সরাসরি শুরু করুন' : 'Start now',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 2: DEED SCREEN (Arabic Tashkeel, Translate Toggle, Tap Repetition + Mic)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDeedView() {
    final lang = LanguageService.to;
    final isBn = lang.isBangla;

    return Obx(() {
      final deed = controller.activeDeed.value;
      final count = controller.repetitionCount.value;
      final target = deed.targetRepetitions;
      final isRec = controller.isRecording.value || controller.isWordTracking.value;

      final diffColor = deed.difficulty == 'Hard'
          ? const Color(0xFFFF5252)
          : (deed.difficulty == 'Medium'
              ? const Color(0xFFFFB300)
              : AppColors.brightGreen);

      return Column(
        children: [
          // Top Navigation Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Iconsax.close_circle,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => Get.back(),
                ),
                // Difficulty and duration chips
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: diffColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: diffColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        isBn
                            ? (deed.difficulty == 'Easy'
                                ? 'সহজ'
                                : (deed.difficulty == 'Medium'
                                    ? 'মাঝারি'
                                    : 'কঠিন'))
                            : deed.difficulty,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: diffColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primaryGold.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        isBn
                            ? '+${deed.rewardMinutes} মি.'
                            : '+${deed.rewardMinutes} min',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGold,
                        ),
                      ),
                    ),
                  ],
                ),
                // Shuffle / Change deed button
                IconButton(
                  icon: const Icon(
                    Iconsax.refresh,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => controller.randomizeDeed(),
                ),
              ],
            ),
          ),

          // Scrollable Deed Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  // Deed Title
                  Text(
                    isBn ? deed.titleBn : deed.titleEn,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Large Arabic Card with full tashkeel/harakat
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF132A20),
                          AppColors.cardBackground,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.brightGreen.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brightGreen.withValues(alpha: 0.08),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Voice tracking mode selection tabs: [ 🇸🇦 আরবি | 🇧🇩 উচ্চারণ | 📖 অর্থ | 🇬🇧 English ]
                        Obx(() {
                          final currentMode = controller.activeVoiceMode.value;
                          final isTracking = controller.isWordTracking.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isTracking
                                    ? AppColors.brightGreen.withValues(alpha: 0.4)
                                    : Colors.white12,
                              ),
                            ),
                            child: Row(
                              children: [
                                _buildVoiceModePill(
                                  title: 'আরবি',
                                  mode: VoiceTrackMode.arabic,
                                  flag: '🇸🇦',
                                  isSelected: currentMode == VoiceTrackMode.arabic,
                                  onTap: () => controller.setVoiceMode(VoiceTrackMode.arabic),
                                ),
                                _buildVoiceModePill(
                                  title: 'উচ্চারণ',
                                  mode: VoiceTrackMode.banglaPronun,
                                  flag: '🇧🇩',
                                  isSelected: currentMode == VoiceTrackMode.banglaPronun,
                                  onTap: () => controller.setVoiceMode(VoiceTrackMode.banglaPronun),
                                ),
                                _buildVoiceModePill(
                                  title: 'অর্থ',
                                  mode: VoiceTrackMode.banglaMeaning,
                                  flag: '📖',
                                  isSelected: currentMode == VoiceTrackMode.banglaMeaning,
                                  onTap: () => controller.setVoiceMode(VoiceTrackMode.banglaMeaning),
                                ),
                                _buildVoiceModePill(
                                  title: 'English',
                                  mode: VoiceTrackMode.englishMeaning,
                                  flag: '🇬🇧',
                                  isSelected: currentMode == VoiceTrackMode.englishMeaning,
                                  onTap: () => controller.setVoiceMode(VoiceTrackMode.englishMeaning),
                                ),
                              ],
                            ),
                          );
                        }),

                        // Word-by-word tracking display
                        Obx(() {
                          final mode = controller.activeVoiceMode.value;
                          final matches = controller.currentWordMatches;
                          final liveText = controller.liveRecognizedText.value;
                          final statusMsg = controller.trackingStatusMessage.value;
                          final isTracking = controller.isWordTracking.value;

                          List<String> words;
                          bool isRtl = false;
                          double fontSize = 18;
                          String? fontFam;

                          switch (mode) {
                            case VoiceTrackMode.arabic:
                              words = controller.arabicWords;
                              isRtl = true;
                              fontSize = 24;
                              fontFam = 'Amiri';
                              break;
                            case VoiceTrackMode.banglaPronun:
                              words = controller.banglaPronunWords.isNotEmpty
                                  ? controller.banglaPronunWords
                                  : controller.translitWords;
                              fontSize = 16;
                              break;
                            case VoiceTrackMode.banglaMeaning:
                              words = controller.banglaMeaningWords;
                              fontSize = 15;
                              break;
                            case VoiceTrackMode.englishMeaning:
                              words = controller.englishMeaningWords;
                              fontSize = 15;
                              break;
                          }

                          return Column(
                            children: [
                              // Status message banner (e.g. recitation celebration or error notice)
                              if (statusMsg.isNotEmpty || controller.hasTrackingFailed.value)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: controller.hasTrackingFailed.value
                                        ? const Color(0xFF3B1212)
                                        : AppColors.brightGreen.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: controller.hasTrackingFailed.value
                                          ? const Color(0xFFEF4444)
                                          : AppColors.brightGreen.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        controller.hasTrackingFailed.value
                                            ? Icons.error_outline_rounded
                                            : Icons.check_circle,
                                        color: controller.hasTrackingFailed.value
                                            ? const Color(0xFFEF4444)
                                            : AppColors.brightGreen,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          statusMsg,
                                          style: TextStyle(
                                            color: controller.hasTrackingFailed.value
                                                ? const Color(0xFFFCA5A5)
                                                : AppColors.brightGreen,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // The Interactive Word Chips
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                                children: List.generate(words.length, (i) {
                                  final matched = i < matches.length && matches[i];
                                  final isFailed = !matched && controller.hasTrackingFailed.value;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isRtl ? 12 : 10,
                                      vertical: isRtl ? 8 : 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: matched
                                          ? AppColors.brightGreen.withValues(alpha: 0.28)
                                          : (isFailed
                                              ? const Color(0xFF3B1212)
                                              : Colors.white.withValues(alpha: 0.08)),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: matched
                                            ? AppColors.brightGreen
                                            : (isFailed
                                                ? const Color(0xFFEF4444)
                                                : Colors.white24),
                                        width: (matched || isFailed) ? 1.8 : 1,
                                      ),
                                      boxShadow: [
                                        if (matched)
                                          BoxShadow(
                                            color: AppColors.brightGreen.withValues(alpha: 0.35),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          )
                                        else if (isFailed)
                                          BoxShadow(
                                            color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                                      children: [
                                        if (matched) ...[
                                          const Icon(
                                            Icons.check,
                                            size: 13,
                                            color: AppColors.brightGreen,
                                          ),
                                          const SizedBox(width: 4),
                                        ] else if (isFailed) ...[
                                          const Icon(
                                            Icons.close,
                                            size: 13,
                                            color: Color(0xFFEF4444),
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        Text(
                                          words[i],
                                          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                                          style: TextStyle(
                                            fontSize: fontSize,
                                            height: isRtl ? 1.7 : 1.3,
                                            fontWeight: (matched || isFailed) ? FontWeight.bold : FontWeight.w600,
                                            color: matched
                                                ? AppColors.brightGreen
                                                : (isFailed ? const Color(0xFFFCA5A5) : Colors.white),
                                            fontFamily: fontFam,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ),

                              // In Arabic mode, also show pronunciation underneath for easy reading
                              if (mode == VoiceTrackMode.arabic && deed.banglaPronunciation.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  deed.banglaPronunciation,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.65),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],

                              // Live STT voice wave / feedback bar
                              if (isTracking || liveText.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black45,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isTracking
                                          ? AppColors.brightGreen.withValues(alpha: 0.3)
                                          : Colors.white12,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isTracking ? Icons.mic : Icons.mic_none,
                                        size: 14,
                                        color: isTracking ? AppColors.brightGreen : Colors.white54,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          liveText.isNotEmpty ? '"$liveText"' : (isBn ? 'শুনছি... পাঠ করুন' : 'Listening... speak now'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isTracking ? AppColors.brightGreen : Colors.white60,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          );
                        }),
                        const SizedBox(height: 18),

                        // "Translate" Toggle Button
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => controller.toggleTranslate(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: controller.isTranslated.value
                                  ? AppColors.brightGreen.withValues(alpha: 0.2)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: controller.isTranslated.value
                                    ? AppColors.brightGreen
                                    : AppColors.border,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Iconsax.translate,
                                  size: 16,
                                  color: controller.isTranslated.value
                                      ? AppColors.brightGreen
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  lang.t('translate'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: controller.isTranslated.value
                                        ? AppColors.brightGreen
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  controller.isTranslated.value
                                      ? Iconsax.arrow_up_2
                                      : Iconsax.arrow_down_1,
                                  size: 14,
                                  color: controller.isTranslated.value
                                      ? AppColors.brightGreen
                                      : AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Expanded Transliteration & Translations
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 250),
                          crossFadeState: controller.isTranslated.value
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          firstChild: const SizedBox(width: double.infinity),
                          secondChild: Padding(
                            padding: const EdgeInsets.only(top: 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(color: AppColors.border),
                                const SizedBox(height: 10),

                                // Transliteration (phonetic English)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Iconsax.text,
                                      size: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        deed.transliteration,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontStyle: FontStyle.italic,
                                          color: AppColors.primaryGold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Bengali pronunciation
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Iconsax.volume_high,
                                      size: 16,
                                      color: AppColors.brightGreen,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        deed.banglaPronunciation,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Bengali Meaning (primary)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isBn ? 'বাংলা অর্থ:' : 'Bengali Meaning:',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.brightGreen,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        deed.translationBn,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          height: 1.4,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        isBn ? 'ইংরেজি অর্থ:' : 'English Meaning:',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        deed.translationEn,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          height: 1.4,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Repetition Count Progress Display
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isBn ? 'পুনরাবৃত্তি লক্ষ্য' : 'Repetition Target',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isBn
                                  ? '$count / $target বার সম্পন্ন'
                                  : '$count / $target completed',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        // Progress ring or count badge
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: count >= target
                                ? AppColors.brightGreen.withValues(alpha: 0.2)
                                : AppColors.cardBackground,
                            border: Border.all(
                              color: count >= target
                                  ? AppColors.brightGreen
                                  : AppColors.primaryGold,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: count >= target
                                    ? AppColors.brightGreen
                                    : AppColors.primaryGold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Section: Tap-to-count + Circular Mic
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // Tap to count button (MUST work without mic!)
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _onRepetitionTapped,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brightGreen,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          icon: const Icon(Iconsax.add_circle, size: 22),
                          label: Text(
                            lang.t('tap_to_count'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Circular MIC Button for word-by-word voice tracking
                    GestureDetector(
                      onTap: () => controller.toggleWordTracking(),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isRec
                              ? AppColors.brightGreen
                              : AppColors.cardBackground,
                          border: Border.all(
                            color: isRec
                                ? AppColors.brightGreen
                                : AppColors.border,
                            width: 2,
                          ),
                          boxShadow: [
                            if (isRec)
                              BoxShadow(
                                color: AppColors.brightGreen.withValues(
                                  alpha: 0.5,
                                ),
                                blurRadius: 18,
                                spreadRadius: 3,
                              ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            isRec ? Iconsax.stop : Iconsax.microphone_2,
                            color: isRec ? Colors.black : AppColors.primaryGold,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Helper text
                Text(
                  isRec
                      ? (isBn
                          ? 'ভয়েস ট্র্যাকিং চলছে... উচ্চারণ বা অর্থ পাঠ করুন'
                          : 'Voice tracking active... speak now')
                      : (isBn
                          ? 'মাইক চেপে কণ্ঠের সাথে শব্দ ট্র্যাকিং করুন'
                          : lang.t('recitation_optional')),
                  style: TextStyle(
                    fontSize: 11,
                    color: isRec
                        ? AppColors.brightGreen
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 3: SUCCESS MODAL / SCREEN (Green check, MashaAllah, XP & Time, Hadith)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSuccessView() {
    final lang = LanguageService.to;
    final isBn = lang.isBangla;

    return Obx(() {
      final deed = controller.activeDeed.value;

      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Big Green Check Circle (NOT emoji!)
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brightGreen.withValues(alpha: 0.16),
                  border: Border.all(
                    color: AppColors.brightGreen,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brightGreen.withValues(alpha: 0.35),
                      blurRadius: 32,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Iconsax.tick_circle,
                    size: 54,
                    color: AppColors.brightGreen,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // "MashaAllah!" Header
              Text(
                lang.t('mashaallah'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Deed Name Repeated
              Text(
                isBn ? deed.titleBn : deed.titleEn,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brightGreen,
                ),
              ),
              const SizedBox(height: 24),

              // Reward Cards: Unlock Time & Gold XP Chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    // Unlock Icon + Duration
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.brightGreen.withValues(
                                alpha: 0.15,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Iconsax.unlock,
                              color: AppColors.brightGreen,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isBn ? 'আনলক সময়' : 'Access Earned',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '+${deed.rewardMinutes}m',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 38,
                      width: 1,
                      color: AppColors.border,
                    ),
                    const SizedBox(width: 16),

                    // Gold XP Chip
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold.withValues(
                              alpha: 0.18,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Iconsax.star_1,
                            color: AppColors.primaryGold,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isBn ? 'অর্জিত এক্সপি' : 'XP Points',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '+${deed.xpEarned} XP',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Short Hadith / Quote about that deed
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Iconsax.book_1,
                          size: 15,
                          color: AppColors.primaryGold,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          deed.reference,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isBn ? deed.hadithQuoteBn : deed.hadithQuoteEn,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Primary "Continue" Button -> returns to dashboard with timer running
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _onContinuePressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brightGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    lang.t('continue_btn'),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildVoiceModePill({
    required String title,
    required VoiceTrackMode mode,
    required String flag,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.brightGreen.withValues(alpha: 0.22)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.brightGreen : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(flag, style: const TextStyle(fontSize: 10)),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.brightGreen : Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
