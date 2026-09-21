import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/language_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/rank_shield_card.dart';
import '../controllers/blocking_controller.dart';

class BlockedScreen extends StatelessWidget {
  const BlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BlockingController());
    final lang = LanguageService.to;
    final storage = Get.find<StorageService>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          controller.onCloseApp();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Obx(() {
            final isBn = lang.isBangla;
            final monitoredPackages = storage.getMonitoredPackages();

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 22.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Current Rank Shield + XP Bar at the top
                  const RankShieldCard(compact: true),
                  const SizedBox(height: 24),

                  // 2. Lock Visual Badge
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF5252).withValues(alpha: 0.14),
                      border: Border.all(
                        color: const Color(0xFFFF5252).withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF5252).withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Iconsax.lock,
                        size: 34,
                        color: Color(0xFFFF5252),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 3. "Your apps are locked" Message
                  Text(
                    lang.t('your_apps_locked'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lang.t('complete_deed_to_unlock'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4. Locked Apps small grid / list
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Iconsax.shield_security,
                              size: 16,
                              color: AppColors.primaryGold,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isBn ? 'লক করা অ্যাপসমূহ' : 'Protected Apps Locked',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: monitoredPackages.take(6).map((pkg) {
                            final simpleName = pkg
                                .split('.')
                                .last
                                .capitalizeFirst ??
                                'App';
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.border,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Iconsax.lock_1,
                                    size: 13,
                                    color: Color(0xFFFF5252),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    simpleName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 5. Big CTA Button: "Complete a Good Deed" -> launches reveal flow
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brightGreen,
                        foregroundColor: Colors.black,
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Get.toNamed(
                          '/unlock',
                          arguments: {
                            'packageName': controller.packageName.value,
                            'appName': controller.appName.value,
                          },
                        );
                      },
                      icon: const Icon(Iconsax.magic_star, size: 22),
                      label: Text(
                        lang.t('complete_a_good_deed'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Close App / Leave Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton.icon(
                      onPressed: controller.onCloseApp,
                      icon: const Icon(
                        Iconsax.close_circle,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      label: Text(
                        isBn ? 'অ্যাপ বন্ধ করুন' : 'Close Application',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
