import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/services/language_service.dart';
import '../../../core/services/native_bridge_service.dart';
import '../../../core/services/storage_service.dart';
import '../models/unlock_session_model.dart';

class UnlockSuccessView extends StatelessWidget {
  const UnlockSuccessView({super.key});

  @override
  Widget build(BuildContext context) {
    final languageService = LanguageService.to;
    final storage = Get.find<StorageService>();
    final nativeBridge = Get.find<NativeBridgeService>();

    final duration = (Get.arguments is Map)
        ? (Get.arguments['durationMinutes'] as int? ?? 30)
        : 30;

    final targetPackage =
        (Get.arguments is Map && Get.arguments['packageName'] != null)
        ? Get.arguments['packageName'] as String
        : (storage.getMonitoredPackages().isNotEmpty
              ? storage.getMonitoredPackages().first
              : 'com.zhiliaoapp.musically');

    final targetAppName =
        (Get.arguments is Map && Get.arguments['appName'] != null)
        ? Get.arguments['appName'] as String
        : (targetPackage.contains('tiktok') ||
                  targetPackage.contains('musically')
              ? 'TikTok'
              : (targetPackage.contains('instagram')
                    ? 'Instagram'
                    : (targetPackage.contains('facebook')
                          ? 'Facebook'
                          : (targetPackage.contains('youtube')
                                ? 'YouTube'
                                : 'App'))));

    final expiresAt = DateTime.now().add(Duration(minutes: duration));
    final expireTimeStr = DateFormat('hh:mm a').format(expiresAt);

    // Save temporary unlock pass into storage & native bridge
    final session = UnlockSessionModel(
      packageName: targetPackage,
      appName: targetAppName,
      durationMinutes: duration,
      expiresAtTimestamp: expiresAt.millisecondsSinceEpoch,
    );

    final existing = storage.getUnlockSessions();
    existing.removeWhere((s) => s.packageName == targetPackage);
    existing.add(session);
    storage.saveUnlockSessions(existing);
    nativeBridge.setTemporaryUnlock(targetPackage, duration);

    return Obx(() {
      final isBn = languageService.isBangla;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: ResponsiveScaffoldBody(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Green Check Circle
              Container(
                width: context.responsiveSize(90, minSize: 72, maxSize: 110),
                height: context.responsiveSize(90, minSize: 72, maxSize: 110),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withValues(alpha: 0.35),
                      blurRadius: 36,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_rounded,
                    color: AppColors.brightGreen,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Headline
              Text(
                isBn ? 'ব্যবহারের অনুমতি আনলক হয়েছে' : 'Access Unlocked',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Duration Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  isBn
                      ? '$duration মিনিট সময় বরাদ্দ'
                      : '$duration minutes granted',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brightGreen,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(
                isBn
                    ? '$targetAppName ব্যবহারের মেয়াদ শেষ হবে:\n$expireTimeStr'
                    : '$targetAppName is available until\n$expireTimeStr',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),

              const Spacer(),

              // Primary CTA: Open App
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Get.offNamed(
                    '/active-unlock',
                    arguments: {'session': session},
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isBn ? '$targetAppName খুলুন' : 'Open $targetAppName',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Subtext
              Text(
                isBn
                    ? 'সময়সীমা শেষ হলে স্বয়ংক্রিয়ভাবে সুরক্ষা পুনরায় কার্যকর হবে।'
                    : 'Your access will automatically\nexpire when the timer ends.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      );
    });
  }
}
