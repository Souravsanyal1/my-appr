import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../app_selection/controllers/app_selection_controller.dart';
import '../../app_selection/models/installed_app_model.dart';

class ChooseAppsScreen extends StatelessWidget {
  const ChooseAppsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AppSelectionController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Headline
              const Text(
                'What should we\nprotect?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.25,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              const Text(
                'Choose the apps you want to use more intentionally.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // List of Protected Apps
              Expanded(
                child: Obx(() {
                  final apps = controller.installedApps;
                  if (apps.isEmpty && controller.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryGreen),
                    );
                  }

                  // Default preset list if native list is loading
                  final displayList = apps.isNotEmpty
                      ? apps
                      : [
                          InstalledAppModel(appName: 'TikTok', packageName: 'com.zhiliaoapp.musically', category: 'Social media'),
                          InstalledAppModel(appName: 'Instagram', packageName: 'com.instagram.android', category: 'Social media'),
                          InstalledAppModel(appName: 'Facebook', packageName: 'com.facebook.katana', category: 'Social media'),
                          InstalledAppModel(appName: 'YouTube', packageName: 'com.google.android.youtube', category: 'Video & entertainment'),
                          InstalledAppModel(appName: 'Reddit', packageName: 'com.reddit.frontpage', category: 'Social media'),
                        ];

                  return ListView.separated(
                    itemCount: displayList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final app = displayList[index];
                      final isSelected = controller.selectedPackages.contains(app.packageName);

                      return AppCard(
                        isSelected: isSelected,
                        onTap: () => controller.toggleAppSelection(app.packageName),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryGreen.withOpacity(0.18)
                                    : AppColors.surfaceLight,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  app.appName.isNotEmpty ? app.appName[0].toUpperCase() : 'A',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: isSelected ? AppColors.brightGreen : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    app.appName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    app.category.isNotEmpty ? app.category : 'Social media',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? AppColors.primaryGreen : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? AppColors.primaryGreen : AppColors.border,
                                  width: 1.5,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, size: 16, color: Colors.black)
                                  : null,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
              ),

              // Bottom Continue Pill CTA
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    controller.saveSelection();
                    Get.toNamed('/daily-goal');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
