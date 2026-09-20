import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:focus_deen/core/constants/app_colors.dart';
import 'package:focus_deen/core/services/native_bridge_service.dart';

class RestrictedSettingsDialog {
  static void show(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nativeBridge = Get.find<NativeBridgeService>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
          ),
        ),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: AppColors.primaryGold, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Fix "Restricted Setting" / "App Blocked"',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Android 13, 14, and 15 temporarily restrict Accessibility for apps installed outside Google Play. Follow these 3 quick steps to enable it:',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 16),
              _buildStep(
                number: '1',
                title: 'Open App Info',
                description: 'Tap the "Open App Info" button below.',
                icon: Icons.open_in_new,
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildStep(
                number: '2',
                title: 'Allow Restricted Settings',
                description: 'In the top-right corner, tap the 3 dots (⋮) and choose "Allow restricted settings" (সীমাবদ্ধ সেটিংস অনুমতি দিন).',
                icon: Icons.more_vert,
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildStep(
                number: '3',
                title: 'Turn ON Accessibility',
                description: 'Verify with your phone PIN/fingerprint, then return and switch FocusDeen ON.',
                icon: Icons.check_circle_outline,
                isDark: isDark,
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primaryGold, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Play Protect Warning: If Google Play Protect blocked installation, tap "More details" -> "Install anyway".',
                        style: TextStyle(fontSize: 11, color: AppColors.primaryGold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.settings_outlined, size: 18),
            label: const Text('Open App Info'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await nativeBridge.openAppSettings();
            },
          ),
        ],
      ),
    );
  }

  static Widget _buildStep({
    required String number,
    required String title,
    required String description,
    required IconData icon,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: AppColors.emerald.withValues(alpha: 0.2),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.emerald,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
