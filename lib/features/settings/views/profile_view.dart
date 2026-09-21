import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/progress_ring.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
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
                child: Icon(Icons.person_rounded, size: 44, color: AppColors.brightGreen),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Sourav Sanyal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Your Mindful Journey',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // Summary Journey Card
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildJourneyItem('Daily Goal', '30m'),
                  Container(width: 1, height: 36, color: AppColors.border),
                  _buildJourneyItem('Protected', '3 Apps'),
                  Container(width: 1, height: 36, color: AppColors.border),
                  _buildJourneyItem('Streak', '7 Days'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Settings Options List
            _buildSettingTile(
              icon: Icons.shield_outlined,
              title: 'Protection & Strict Mode',
              subtitle: 'PIN protection and bypass prevention',
              onTap: () => Get.toNamed('/settings'),
            ),
            const SizedBox(height: 10),
            _buildSettingTile(
              icon: Icons.tune_rounded,
              title: 'Unlock Rules & Passing Score',
              subtitle: 'Current threshold: 80%',
              onTap: () => Get.toNamed('/settings'),
            ),
            const SizedBox(height: 10),
            _buildSettingTile(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications & Reminders',
              subtitle: 'Pre-limit alerts & daily streak prompts',
              onTap: () => Get.toNamed('/settings'),
            ),
            const SizedBox(height: 10),
            _buildSettingTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy & Offline Storage',
              subtitle: 'Microphone permissions & local data controls',
              onTap: () => Get.toNamed('/settings'),
            ),
            const SizedBox(height: 10),
            _buildSettingTile(
              icon: Icons.info_outline_rounded,
              title: 'About DeenFlow',
              subtitle: 'Version 1.0.0 • Learn Before You Scroll',
              onTap: () => Get.toNamed('/settings'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
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
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
