import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:focus_deen/core/constants/app_colors.dart';
import 'package:focus_deen/core/services/pin_security_service.dart';
import 'package:focus_deen/features/limits/controllers/limit_controller.dart';
import 'package:focus_deen/features/limits/models/app_limit_model.dart';
import 'package:focus_deen/features/security/views/pin_dialog.dart';

class LimitScreen extends GetView<LimitController> {
  const LimitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pinService = Get.find<PinSecurityService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Limits & Rules'),
        actions: [
          IconButton(
            tooltip: 'Security Settings',
            icon: Icon(
              pinService.isStrictModeActive() ? Icons.lock : Icons.lock_open,
              color: pinService.isStrictModeActive() ? AppColors.primaryGold : Colors.grey,
            ),
            onPressed: () => _showSecurityDialog(context, pinService),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.limits.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer_off_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No app limits configured yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text('Set intentional limits to guard your time.'),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            // Strict Mode Banner
            _buildStrictModeBanner(context, pinService),
            const SizedBox(height: 16),

            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Boundaries (${controller.limits.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Rule'),
                  onPressed: () => _showEditLimitBottomSheet(context, null),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Limits List
            ...controller.limits.map((limit) => _buildLimitCard(context, limit)),
          ],
        );
      }),
    );
  }

  Widget _buildStrictModeBanner(BuildContext context, PinSecurityService pinService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = pinService.isStrictModeActive();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppColors.primaryGold.withValues(alpha: 0.5) : AppColors.darkCardBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isActive ? AppColors.primaryGold : Colors.grey).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isActive ? Icons.verified_user : Icons.security,
              color: isActive ? AppColors.primaryGold : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? 'Strict Mode Active' : 'Strict Mode Disabled',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  isActive
                      ? 'PIN required to modify limits or unlock apps.'
                      : 'Enable PIN protection to prevent impulsive edits.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isActive,
            activeThumbColor: AppColors.primaryGold,
            onChanged: (val) => _toggleStrictMode(context, pinService, val),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitCard(BuildContext context, AppLimitModel limit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBlock = limit.mode == 'block';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (isBlock ? AppColors.danger : AppColors.warning).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    isBlock ? Icons.block : Icons.notifications_active_outlined,
                    color: isBlock ? AppColors.danger : AppColors.warning,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        limit.appName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Limit: ${limit.dailyLimitMinutes} min / day  •  Warn at ${limit.warningThresholdMinutes}m',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: limit.isEnabled,
                  activeThumbColor: AppColors.primaryGold,
                  onChanged: (val) => controller.toggleLimit(limit.packageName, val),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isBlock ? AppColors.danger.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isBlock ? 'Block Screen' : 'Gentle Warning',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isBlock ? AppColors.danger : AppColors.warning,
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _showEditLimitBottomSheet(context, limit),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
                      onPressed: () => controller.removeLimit(limit.packageName),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSecurityDialog(BuildContext context, PinSecurityService pinService) async {
    if (!pinService.hasPin()) {
      final set = await PinDialog.show(
        title: 'Set Security PIN',
        subtitle: 'Choose a 4-digit PIN for Strict Mode',
        isSetupMode: true,
      );
      if (set) {
        Get.snackbar('PIN Set', 'Your FocusDeen PIN has been configured.');
      }
    } else {
      final verify = await PinDialog.show(
        title: 'Change PIN',
        subtitle: 'Enter your existing PIN',
      );
      if (verify) {
        await PinDialog.show(
          title: 'New Security PIN',
          subtitle: 'Choose a new 4-digit PIN',
          isSetupMode: true,
        );
      }
    }
  }

  void _toggleStrictMode(BuildContext context, PinSecurityService pinService, bool enable) async {
    if (enable) {
      if (!pinService.hasPin()) {
        final set = await PinDialog.show(
          title: 'Set Strict Mode PIN',
          subtitle: 'Create a 4-digit security PIN',
          isSetupMode: true,
        );
        if (!set) return;
      }
      pinService.toggleStrictMode(true);
      Get.forceAppUpdate();
    } else {
      final verified = await PinDialog.show(
        title: 'Disable Strict Mode',
        subtitle: 'Enter your PIN to turn off Strict Mode',
      );
      if (verified) {
        pinService.toggleStrictMode(false);
        Get.forceAppUpdate();
      }
    }
  }

  void _showEditLimitBottomSheet(BuildContext context, AppLimitModel? existing) {
    int dailyMinutes = existing?.dailyLimitMinutes ?? 30;
    int warningMinutes = existing?.warningThresholdMinutes ?? 5;
    String mode = existing?.mode ?? 'block';
    final nameCtrl = TextEditingController(text: existing?.appName ?? '');
    final pkgCtrl = TextEditingController(text: existing?.packageName ?? '');

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    existing == null ? 'Create App Rule' : 'Edit Rule: ${existing.appName}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (existing == null) ...[
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'App Name (e.g. YouTube)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pkgCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Package Name (e.g. com.google.android.youtube)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Daily Limit Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Daily Limit:'),
                      Text('$dailyMinutes minutes', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGold)),
                    ],
                  ),
                  Slider(
                    value: dailyMinutes.toDouble(),
                    min: 10,
                    max: 180,
                    divisions: 34,
                    activeColor: AppColors.primaryGold,
                    onChanged: (v) => setSheetState(() => dailyMinutes = v.round()),
                  ),
                  const SizedBox(height: 8),

                  // Warning Threshold Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Warning Alert:'),
                      Text('$warningMinutes min before limit', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: warningMinutes.toDouble(),
                    min: 2,
                    max: 20,
                    divisions: 18,
                    activeColor: AppColors.warning,
                    onChanged: (v) => setSheetState(() => warningMinutes = v.round()),
                  ),
                  const SizedBox(height: 12),

                  // Enforcement Mode
                  const Text('Enforcement Mode:'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Block Screen')),
                          selected: mode == 'block',
                          selectedColor: AppColors.danger.withValues(alpha: 0.2),
                          onSelected: (s) => setSheetState(() => mode = 'block'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Warning Only')),
                          selected: mode == 'warning',
                          selectedColor: AppColors.warning.withValues(alpha: 0.2),
                          onSelected: (s) => setSheetState(() => mode = 'warning'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final pkg = existing?.packageName ?? pkgCtrl.text.trim();
                        final name = existing?.appName ?? nameCtrl.text.trim();
                        if (pkg.isEmpty || name.isEmpty) {
                          Get.snackbar('Error', 'Please fill app name and package.');
                          return;
                        }

                        final newLimit = AppLimitModel(
                          packageName: pkg,
                          appName: name,
                          dailyLimitMinutes: dailyMinutes,
                          warningThresholdMinutes: warningMinutes,
                          mode: mode,
                          isEnabled: existing?.isEnabled ?? true,
                        );

                        Get.back();
                        controller.addOrUpdateLimit(newLimit);
                      },
                      child: const Text('Save Rule'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }
}
