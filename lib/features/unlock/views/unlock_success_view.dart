import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/native_bridge_service.dart';
import '../../../core/services/storage_service.dart';
import '../models/unlock_session_model.dart';

class UnlockSuccessView extends StatelessWidget {
  const UnlockSuccessView({super.key});

  @override
  Widget build(BuildContext context) {
    final duration = (Get.arguments is Map)
        ? (Get.arguments['durationMinutes'] as int? ?? 30)
        : 30;

    final targetPackage = 'com.zhiliaoapp.musically';
    final targetAppName = 'TikTok';

    final expiresAt = DateTime.now().add(Duration(minutes: duration));
    final expireTimeStr = DateFormat('hh:mm a').format(expiresAt);

    // Save temporary unlock pass into storage & native bridge
    final storage = Get.find<StorageService>();
    final nativeBridge = Get.find<NativeBridgeService>();
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Green Check Circle
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.18),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withOpacity(0.35),
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
              const SizedBox(height: 32),

              // Headline
              const Text(
                'Access Unlocked',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Duration Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '$duration minutes granted',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brightGreen,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                '$targetAppName is available until\n$expireTimeStr',
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
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Get.offNamed('/active-unlock', arguments: {
                    'session': session,
                  }),
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
                        'Open $targetAppName',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Subtext
              const Text(
                'Your access will automatically\nexpire when the timer ends.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
