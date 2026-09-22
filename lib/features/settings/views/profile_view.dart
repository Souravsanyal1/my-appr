import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/language_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/progress_ring.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final languageService = LanguageService.to;
    final storage = Get.find<StorageService>();

    return Obx(() {
      final isBn = languageService.isBangla;
      final userName = storage.getUserName();
      final goalMins = storage.getDailyGoalMinutes();
      final protectedCount = storage.getMonitoredPackages().length;
      final streak = storage.getStreakDays();
      final minScore = storage.getMinimumPassingScore();

      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isBn ? 'প্রোফাইল' : 'Profile',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => Get.toNamed('/settings'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Avatar & User Title
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryGreen, width: 2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.person_rounded,
                    size: 44,
                    color: AppColors.brightGreen,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isBn ? 'আপনার আত্মশুদ্ধির যাত্রা' : 'Your Mindful Journey',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Summary Journey Card
              AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildJourneyItem(
                      isBn ? 'দৈনিক লক্ষ্য' : 'Daily Goal',
                      '${goalMins}m',
                    ),
                    Container(width: 1, height: 36, color: AppColors.border),
                    _buildJourneyItem(
                      isBn ? 'সুরক্ষিত' : 'Protected',
                      isBn ? '$protectedCount টি অ্যাপ' : '$protectedCount Apps',
                    ),
                    Container(width: 1, height: 36, color: AppColors.border),
                    _buildJourneyItem(
                      isBn ? 'ধারাবাহিকতা' : 'Streak',
                      isBn ? '$streak দিন' : '$streak Days',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Settings Options List
              _buildSettingTile(
                icon: Icons.language_rounded,
                title: isBn ? 'ভাষা নির্বাচন (Language)' : 'App Language',
                subtitle: isBn
                    ? 'বর্তমান ভাষা: বাংলা 🇧🇩 (ট্যাপ করে পরিবর্তন করুন)'
                    : 'Current: English 🇬🇧 (Tap to switch)',
                onTap: () => languageService.showLanguageSelector(context),
              ),
              const SizedBox(height: 10),
              _buildSettingTile(
                icon: Icons.shield_outlined,
                title: isBn
                    ? 'সুরক্ষা ও স্ট্রিক্ট মোড'
                    : 'Protection & Strict Mode',
                subtitle: isBn
                    ? 'পিন কোড সুরক্ষা ও আনইনস্টল প্রতিরোধ'
                    : 'PIN protection and bypass prevention',
                onTap: () => Get.toNamed('/settings'),
              ),
              const SizedBox(height: 10),
              _buildSettingTile(
                icon: Icons.tune_rounded,
                title: isBn
                    ? 'আনলক নিয়ম ও নূন্যতম স্কোর'
                    : 'Unlock Rules & Passing Score',
                subtitle: isBn
                    ? 'বর্তমান সীমা: $minScore%'
                    : 'Current threshold: $minScore%',
                onTap: () => Get.toNamed('/settings'),
              ),
              const SizedBox(height: 10),
              _buildSettingTile(
                icon: Icons.notifications_none_rounded,
                title: isBn
                    ? 'বিজ্ঞপ্তি ও রিমাইন্ডার'
                    : 'Notifications & Reminders',
                subtitle: isBn
                    ? 'সময়সীমার পূর্ব সংকেত ও আমল রিমাইন্ডার'
                    : 'Pre-limit alerts & daily streak prompts',
                onTap: () => Get.toNamed('/settings'),
              ),
              const SizedBox(height: 10),
              _buildSettingTile(
                icon: Icons.privacy_tip_outlined,
                title: isBn
                    ? 'প্রাইভেসি ও অফলাইন স্টোরেজ'
                    : 'Privacy & Offline Storage',
                subtitle: isBn
                    ? 'মাইক্রোফোন পারমিশন ও লোকাল ডাটা নিয়ন্ত্রণ'
                    : 'Microphone permissions & local data controls',
                onTap: () => Get.toNamed('/settings'),
              ),
              const SizedBox(height: 10),
              _buildSettingTile(
                icon: Icons.info_outline_rounded,
                title: isBn ? 'ফোকাসদ্বীন সম্পর্কে' : 'About FocusDeen',
                subtitle: isBn
                    ? 'ভার্সন ১.০.০ • স্ক্রল করার আগে শিখুন'
                    : 'Version 1.0.0 • Learn Before You Scroll',
                onTap: () => Get.toNamed('/settings'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildJourneyItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.brightGreen,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppColors.brightGreen),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
