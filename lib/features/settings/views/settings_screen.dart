import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/device_identity_service.dart';
import '../../../core/services/gamification_service.dart';
import '../../../core/services/language_service.dart';
import '../../../core/services/native_bridge_service.dart';
import '../controllers/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SettingsController());
    final languageService = LanguageService.to;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final isBn = languageService.isBangla;

      return Scaffold(
        appBar: AppBar(
          title: Text(
            isBn ? 'সেটিংস ও গোপনীয়তা' : 'Settings & Privacy',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          automaticallyImplyLeading: false,
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          children: [
            // ════════════════════════════════════════════════════════
            // 1. PROFILE & DEVICE IDENTITY CARD
            // ════════════════════════════════════════════════════════
            _buildProfileHeaderCard(context, isDark, isBn),
            const SizedBox(height: AppSpacing.md),

            // ════════════════════════════════════════════════════════
            // 2. LANGUAGE & PRONUNCIATION
            // ════════════════════════════════════════════════════════
            _buildSectionHeader(
              isBn ? 'ভাষা ও উচ্চারণ (Language)' : 'Language & Pronunciation',
            ),
            _buildSettingsCard(
              isDark: isDark,
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.brightGreen.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.language_rounded,
                      color: AppColors.brightGreen,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    isBn
                        ? 'অ্যাপের ভাষা ও উচ্চারণ'
                        : 'App Language & Pronunciation',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    isBn
                        ? 'বর্তমান: বাংলা 🇧🇩 (সকল আমলের বাংলা উচ্চারণ)'
                        : 'Current: English 🇬🇧 (Latin Transliteration)',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryEmerald.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryEmerald.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      isBn ? '🇧🇩 পরিবর্তন' : '🇬🇧 Change',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryEmerald,
                      ),
                    ),
                  ),
                  onTap: () => languageService.showLanguageSelector(context),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // ════════════════════════════════════════════════════════
            // 3. PERMISSION MONITOR & RESTORE PROTECTION
            // ════════════════════════════════════════════════════════
            Obx(() {
              final allGranted =
                  controller.hasUsagePermission.value &&
                  controller.hasAccessibility.value &&
                  controller.hasOverlay.value;

              if (allGranted) {
                return Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primaryEmerald.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primaryEmerald.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_user_rounded,
                        color: AppColors.primaryEmerald,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isBn ? 'সুরক্ষা সক্রিয়' : 'Protection Active',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryEmerald,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isBn
                                  ? 'এক্সেসিবিলিটি ও ব্যবহার ট্র্যাকিং স্বাভাবিকভাবে চলছে।'
                                  : 'Accessibility & Usage monitoring running normally.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.danger),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.danger,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isBn ? 'সুরক্ষা স্থগিত রয়েছে' : 'Protection Paused',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.danger,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isBn
                          ? 'ব্যবহার ট্র্যাকিং বা এক্সেসিবিলিটি সার্ভিস সক্রিয় নেই। বিঘ্নহীন সুরক্ষার জন্য অনুমতিগুলো পুনরায় দিন।'
                          : 'Usage monitoring or accessibility permission is not active. Please restore permissions to continue protection.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        final native = Get.find<NativeBridgeService>();
                        native.requestUsageAccess();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(isBn ? 'সুরক্ষা পুনরায় চালু করুন' : 'Restore Protection'),
                    ),
                  ],
                ),
              );
            }),

            // ════════════════════════════════════════════════════════
            // 4. SECURITY & STRICT MODE
            // ════════════════════════════════════════════════════════
            _buildSectionHeader(
              isBn ? 'নিরাপত্তা ও স্ট্রিক্ট মোড' : 'Security & Strict Mode',
            ),
            _buildSettingsCard(
              isDark: isDark,
              children: [
                Obx(
                  () => SwitchListTile(
                    title: Text(
                      isBn ? 'স্ট্রিক্ট মোড' : 'Strict Mode',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      isBn
                          ? 'অ্যাপ আনলক ও সীমা পরিবর্তনের জন্য ৪-সংখ্যার পিন আবশ্যক'
                          : 'Require 4-digit PIN for unlocks and modifying limits',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    value: controller.isStrictMode.value,
                    activeThumbColor: AppColors.primaryEmerald,
                    onChanged: controller.toggleStrictMode,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.pin,
                    color: AppColors.secondaryGold,
                  ),
                  title: Text(
                    isBn ? 'সিকিউরিটি পিন পরিবর্তন' : 'Change Security PIN',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    isBn
                        ? 'নিরাপদ SHA-256 অন-ডিভাইস স্টোরেজ'
                        : 'Secure SHA-256 hashed on-device storage',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: controller.changePin,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // ════════════════════════════════════════════════════════
            // 5. RECITATION & UNLOCK RULES
            // ════════════════════════════════════════════════════════
            _buildSectionHeader(
              isBn ? 'তেলাওয়াত ও আনলক নিয়ম' : 'Recitation & Unlock Rules',
            ),
            _buildSettingsCard(
              isDark: isDark,
              children: [
                ListTile(
                  title: Text(
                    isBn ? 'উত্তীর্ণ হওয়ার স্কোর' : 'Passing Threshold',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    isBn
                        ? 'আনলক পাস অর্জনের জন্য প্রয়োজনীয় ন্যূনতম স্কোর'
                        : 'Minimum score required to earn an unlock pass',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  trailing: Obx(
                    () => DropdownButton<int>(
                      value: controller.unlockThreshold.value,
                      underline: const SizedBox(),
                      items: [
                        const DropdownMenuItem(value: 70, child: Text('70%')),
                        const DropdownMenuItem(value: 75, child: Text('75%')),
                        DropdownMenuItem(
                          value: 80,
                          child: Text(isBn ? '৮০% (ডিফল্ট)' : '80% (Default)'),
                        ),
                        const DropdownMenuItem(value: 85, child: Text('85%')),
                        const DropdownMenuItem(value: 90, child: Text('90%')),
                      ],
                      onChanged: (val) {
                        if (val != null) controller.setUnlockThreshold(val);
                      },
                    ),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBn ? 'নির্ধারিত আনলক সময়সীমা:' : 'Configured Unlock Tiers:',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isBn
                            ? '• ৭০% – ৭৯% স্কোর → ৫ মিনিট অ্যাক্সেস'
                            : '• 70% – 79% score → 5 minutes access',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isBn
                            ? '• ৮০% – ৮৯% স্কোর → ১০ মিনিট অ্যাক্সেস'
                            : '• 80% – 89% score → 10 minutes access',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isBn
                            ? '• ৯০%+ স্কোর → ১৫ মিনিট অ্যাক্সেস'
                            : '• 90%+ score → 15 minutes access',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // ════════════════════════════════════════════════════════
            // 6. NOTIFICATIONS
            // ════════════════════════════════════════════════════════
            _buildSectionHeader(
              isBn ? 'বিজ্ঞপ্তি ও সতর্কতা' : 'Notifications',
            ),
            _buildSettingsCard(
              isDark: isDark,
              children: [
                Obx(
                  () => SwitchListTile(
                    title: Text(
                      isBn ? 'সীমা শেষ হওয়ার পূর্ব সতর্কতা' : 'Pre-Limit Warnings',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      isBn
                          ? 'সময় শেষ হওয়ার ৫ মিনিট ও ১ মিনিট পূর্বে সতর্কবার্তা'
                          : 'Alert at 5 minutes and 1 minute remaining',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    value: controller.notifyBeforeLimit.value,
                    activeThumbColor: AppColors.primaryEmerald,
                    onChanged: controller.toggleNotifyBeforeLimit,
                  ),
                ),
                const Divider(height: 1),
                Obx(
                  () => SwitchListTile(
                    title: Text(
                      isBn ? 'দৈনিক আমল রিমাইন্ডার' : 'Daily Streak Reminders',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      isBn
                          ? 'ধারাবাহিকতা বজায় রাখার জন্য নিয়মিত তাগিদ'
                          : 'Mindful notification when streak is waiting',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    value: controller.notifyStreakReminder.value,
                    activeThumbColor: AppColors.primaryEmerald,
                    onChanged: controller.toggleNotifyStreak,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // ════════════════════════════════════════════════════════
            // 7. PRIVACY & LOCAL DATA
            // ════════════════════════════════════════════════════════
            _buildSectionHeader(
              isBn ? 'গোপনীয়তা ও স্থানীয় তথ্য' : 'Privacy & Controls',
            ),
            _buildSettingsCard(
              isDark: isDark,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.lock_clock,
                    color: AppColors.primaryEmerald,
                  ),
                  title: Text(
                    isBn ? 'অফলাইন ও ডিভাইস-কেন্দ্রিক' : 'Offline & Local-First',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    isBn
                        ? 'অ্যাপ ব্যবহারের হিসাব ও পিন সম্পূর্ণ আপনার ডিভাইসেই থাকে।'
                        : 'App usage data & PIN remain securely on your device.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.mic_off_outlined,
                    color: Colors.blueAccent,
                  ),
                  title: Text(
                    isBn ? 'মাইক্রোফোন গোপনীয়তা' : 'Microphone Privacy',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    isBn
                        ? 'কেবলমাত্র তেলাওয়াত অনুশীলনের সময় অডিও রেকর্ড হয় ও সাথে সাথে যাচাই করা হয়।'
                        : 'Audio is only captured during recitation practice and analyzed immediately.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.cleaning_services_outlined,
                    color: Colors.orangeAccent,
                  ),
                  title: Text(
                    isBn ? 'অডিও ক্যাশ মুছুন' : 'Clear Audio Caches',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    isBn
                        ? 'সাময়িক তেলাওয়াত রেকর্ডিং ফাইলগুলো মুছে ফেলুন'
                        : 'Delete temporary recitation audio files',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  onTap: controller.clearAudioRecordings,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.delete_forever,
                    color: AppColors.danger,
                  ),
                  title: Text(
                    isBn ? 'সকল ডেটা রিসেট করুন' : 'Factory Reset Data',
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    isBn
                        ? 'সমস্ত সীমা, সময়সূচী মুছে নতুন করে শুরু করুন'
                        : 'Erase all limits, schedules, and start onboarding anew',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  onTap: controller.resetAllData,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // ════════════════════════════════════════════════════════
            // 8. ABOUT & DISCLAIMERS
            // ════════════════════════════════════════════════════════
            _buildSectionHeader(
              isBn ? 'ফোকাসদ্বীন পরিচিতি' : 'About FocusDeen',
            ),
            _buildSettingsCard(
              isDark: isDark,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBn
                            ? 'ফোকাসদ্বীন • স্ক্রল করার আগে শিখুন'
                            : 'FocusDeen • Learn Before You Scroll',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isBn ? 'সংস্করণ ১.০.০ (বিল্ড ১)' : 'Version 1.0.0 (Build 1)',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isBn
                            ? 'তাজবীদ সতর্কতা: তেলাওয়াতের স্কোর অ্যালগরিদমিক অনুমান এবং এটি কোনো সনদপ্রাপ্ত শিক্ষকের বিকল্প নয়।'
                            : 'Tajweed Disclaimer: Recitation scores are educational algorithmic estimates and do not replace certified Quranic instruction from a qualified teacher.',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isBn
                            ? 'গুগল প্লে নীতিমালা: ডিজিটাল সুস্থতা সহায়তায় শুধুমাত্র বিভ্রান্তিকর অ্যাপ শনাক্ত করতে এক্সেসিবিলিটি সার্ভিস ব্যবহৃত হয়।'
                            : 'Google Play Compliance: AccessibilityService is used exclusively for detecting foreground distracting applications to assist in digital wellbeing.',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      );
    });
  }

  Widget _buildProfileHeaderCard(BuildContext context, bool isDark, bool isBn) {
    String deviceId = '';
    try {
      deviceId = DeviceIdentityService.to.deviceId;
    } catch (_) {}

    final shortId = deviceId.length > 8 ? deviceId.substring(0, 8).toUpperCase() : deviceId;

    final gamification = Get.isRegistered<GamificationService>()
        ? GamificationService.to
        : null;

    final rank = gamification?.currentRank;
    final streak = gamification?.currentStreak.value ?? 0;
    final xp = gamification?.currentXp.value ?? 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      (rank?.color ?? AppColors.primaryEmerald).withValues(alpha: 0.8),
                      (rank?.color ?? AppColors.primaryEmerald),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (rank?.color ?? AppColors.primaryEmerald).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.shield_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rank != null
                          ? (isBn ? rank.nameBn : rank.nameEn)
                          : (isBn ? 'সাধারণ ব্যবহারকারী' : 'FocusDeen User'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isBn ? '$xp XP অর্জিত • $streak দিনের স্ট্রিক' : '$xp XP Earned • $streak-day Streak',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (deviceId.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.fingerprint,
                      size: 16,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${isBn ? 'ডিভাইস আইডি' : 'Device ID'}: #$shortId',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.copy, size: 12),
                  label: Text(
                    isBn ? 'কপি' : 'Copy',
                    style: const TextStyle(fontSize: 11),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: deviceId));
                    Get.snackbar(
                      isBn ? 'কপি হয়েছে' : 'Copied',
                      isBn ? 'ডিভাইস আইডি ক্লিপবোর্ডে কপি করা হয়েছে' : 'Device ID copied to clipboard',
                      snackPosition: SnackPosition.BOTTOM,
                      duration: const Duration(seconds: 2),
                    );
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.secondaryGold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required bool isDark,
    required List<Widget> children,
  }) {
    return Material(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
      ),
      child: Column(children: children),
    );
  }
}
