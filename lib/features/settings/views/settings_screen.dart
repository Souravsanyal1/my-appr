import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
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
            isBn ? 'সেটিংস ও ভাষা' : 'Settings & Privacy',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          automaticallyImplyLeading: false,
        ),
        body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ════════════════════════════════════════════════════════
          // LANGUAGE & PRONUNCIATION
          // ════════════════════════════════════════════════════════
          _buildSectionHeader(
            isBn ? 'ভাষা ও উচ্চারণ (Language)' : 'Language & Pronunciation',
          ),
          _buildSettingsCard(
            isDark: isDark,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.language_rounded,
                  color: AppColors.brightGreen,
                ),
                title: Text(
                  isBn
                      ? 'অ্যাপের ভাষা ও উচ্চারণ'
                      : 'App Language & Pronunciation',
                ),
                subtitle: Text(
                  isBn
                      ? 'বর্তমান: বাংলা 🇧🇩 (সকল আমলের বাংলা উচ্চারণ)'
                      : 'Current: English 🇬🇧',
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryEmerald.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
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

          const SizedBox(height: 16),
          // ════════════════════════════════════════════════════════
          // PERMISSION MONITOR & RESTORE PROTECTION
          // ════════════════════════════════════════════════════════
          Obx(() {
            final allGranted =
                controller.hasUsagePermission.value &&
                controller.hasAccessibility.value &&
                controller.hasOverlay.value;

            if (allGranted) {
              return Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.primaryEmerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primaryEmerald.withValues(alpha: 0.4),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      color: AppColors.primaryEmerald,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Protection Active',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryEmerald,
                            ),
                          ),
                          Text(
                            'Accessibility & Usage monitoring running normally.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
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
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.danger),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.danger,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Protection Paused',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.danger,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Usage monitoring or accessibility permission is not active. Please restore permissions to continue protection.',
                    style: TextStyle(fontSize: 12),
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
                    child: const Text('Restore Protection'),
                  ),
                ],
              ),
            );
          }),

          // ════════════════════════════════════════════════════════
          // SECURITY & STRICT MODE
          // ════════════════════════════════════════════════════════
          _buildSectionHeader('Security & Strict Mode'),
          _buildSettingsCard(
            isDark: isDark,
            children: [
              Obx(
                () => SwitchListTile(
                  title: const Text(
                    'Strict Mode',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Require 4-digit PIN for unlocks and modifying limits',
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
                title: const Text('Change Security PIN'),
                subtitle: const Text(
                  'Secure SHA-256 hashed on-device storage',
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: controller.changePin,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ════════════════════════════════════════════════════════
          // RECITATION & UNLOCK RULES
          // ════════════════════════════════════════════════════════
          _buildSectionHeader('Recitation & Unlock Rules'),
          _buildSettingsCard(
            isDark: isDark,
            children: [
              ListTile(
                title: const Text(
                  'Passing Threshold',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Minimum score required to earn an unlock pass',
                ),
                trailing: Obx(
                  () => DropdownButton<int>(
                    value: controller.unlockThreshold.value,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 70, child: Text('70%')),
                      DropdownMenuItem(value: 75, child: Text('75%')),
                      DropdownMenuItem(
                        value: 80,
                        child: Text('80% (Default)'),
                      ),
                      DropdownMenuItem(value: 85, child: Text('85%')),
                      DropdownMenuItem(value: 90, child: Text('90%')),
                    ],
                    onChanged: (val) {
                      if (val != null) controller.setUnlockThreshold(val);
                    },
                  ),
                ),
              ),
              const Divider(height: 1),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configured Unlock Tiers:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '• 70% – 79% score → 5 minutes access',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '• 80% – 89% score → 10 minutes access',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '• 90%+ score → 15 minutes access',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ════════════════════════════════════════════════════════
          // NOTIFICATIONS
          // ════════════════════════════════════════════════════════
          _buildSectionHeader('Notifications'),
          _buildSettingsCard(
            isDark: isDark,
            children: [
              Obx(
                () => SwitchListTile(
                  title: const Text('Pre-Limit Warnings'),
                  subtitle: const Text(
                    'Alert at 5 minutes and 1 minute remaining',
                  ),
                  value: controller.notifyBeforeLimit.value,
                  activeThumbColor: AppColors.primaryEmerald,
                  onChanged: controller.toggleNotifyBeforeLimit,
                ),
              ),
              const Divider(height: 1),
              Obx(
                () => SwitchListTile(
                  title: const Text('Daily Streak Reminders'),
                  subtitle: const Text(
                    'Mindful notification when streak is waiting',
                  ),
                  value: controller.notifyStreakReminder.value,
                  activeThumbColor: AppColors.primaryEmerald,
                  onChanged: controller.toggleNotifyStreak,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ════════════════════════════════════════════════════════
          // PRIVACY & LOCAL DATA
          // ════════════════════════════════════════════════════════
          _buildSectionHeader('Privacy & Controls'),
          _buildSettingsCard(
            isDark: isDark,
            children: [
              const ListTile(
                leading: Icon(
                  Icons.lock_clock,
                  color: AppColors.primaryEmerald,
                ),
                title: Text('Offline & Local-First'),
                subtitle: Text(
                  'App usage data & PIN remain securely on your device.',
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.mic_off_outlined,
                  color: Colors.blueAccent,
                ),
                title: const Text('Microphone Privacy'),
                subtitle: const Text(
                  'Audio is only captured during recitation practice and analyzed immediately.',
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.cleaning_services_outlined,
                  color: Colors.orangeAccent,
                ),
                title: const Text('Clear Audio Caches'),
                subtitle: const Text(
                  'Delete temporary recitation audio files',
                ),
                onTap: controller.clearAudioRecordings,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.delete_forever,
                  color: AppColors.danger,
                ),
                title: const Text(
                  'Factory Reset Data',
                  style: TextStyle(color: AppColors.danger),
                ),
                subtitle: const Text(
                  'Erase all limits, schedules, and start onboarding anew',
                ),
                onTap: controller.resetAllData,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ════════════════════════════════════════════════════════
          // ABOUT & DISCLAIMERS
          // ════════════════════════════════════════════════════════
          _buildSectionHeader('About FocusDeen'),
          _buildSettingsCard(
            isDark: isDark,
            children: const [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FocusDeen • Learn Before You Scroll',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Version 1.0.0 (Build 1)',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Tajweed Disclaimer: Recitation scores are educational algorithmic estimates and do not replace certified Quranic instruction from a qualified teacher.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Google Play Compliance: AccessibilityService is used exclusively for detecting foreground distracting applications to assist in digital wellbeing.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  });
}

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
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
      color: isDark ? const Color(0xFF14201C) : Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Column(children: children),
    );
  }
}
