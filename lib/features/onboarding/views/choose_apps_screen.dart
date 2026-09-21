import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/language_service.dart';
import '../../../core/widgets/app_icon_widget.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../app_selection/controllers/app_selection_controller.dart';
import '../../app_selection/models/installed_app_model.dart';

class ChooseAppsScreen extends StatelessWidget {
  const ChooseAppsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AppSelectionController());
    final isBn = LanguageService.to.isBangla;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: AppColors.textPrimary,
          ),
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
              Text(
                isBn
                    ? 'কোন অ্যাপগুলো\nসুরক্ষা করবেন?'
                    : 'What should we\nprotect?',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.25,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                isBn
                    ? 'যে অ্যাপগুলো আপনি সচেতনভাবে ব্যবহার করতে চান সেগুলো বেছে নিন।'
                    : 'Choose the apps you want to use more intentionally.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  onChanged: (val) => controller.setSearchQuery(val),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: isBn ? 'অ্যাপ খুঁজুন...' : 'Search apps...',
                    hintStyle: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // List of Protected Apps
              Expanded(
                child: Obx(() {
                  final apps = controller.filteredApps;
                  if (apps.isEmpty && controller.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryGreen,
                      ),
                    );
                  }

                  // Default preset list if native list is loading or empty
                  final displayList = apps.isNotEmpty
                      ? apps
                      : [
                          const InstalledAppModel(
                            appName: 'TikTok',
                            packageName: 'com.zhiliaoapp.musically',
                            category: 'Social media',
                          ),
                          const InstalledAppModel(
                            appName: 'Instagram',
                            packageName: 'com.instagram.android',
                            category: 'Social media',
                          ),
                          const InstalledAppModel(
                            appName: 'Facebook',
                            packageName: 'com.facebook.katana',
                            category: 'Social media',
                          ),
                          const InstalledAppModel(
                            appName: 'YouTube',
                            packageName: 'com.google.android.youtube',
                            category: 'Video & entertainment',
                          ),
                          const InstalledAppModel(
                            appName: 'Snapchat',
                            packageName: 'com.snapchat.android',
                            category: 'Social media',
                          ),
                          const InstalledAppModel(
                            appName: 'Reddit',
                            packageName: 'com.reddit.frontpage',
                            category: 'Social media',
                          ),
                        ];

                  return ListView.separated(
                    itemCount: displayList.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final app = displayList[index];
                      final isSelected = controller.selectedPackages.contains(
                        app.packageName,
                      );

                      return AppCard(
                        isSelected: isSelected,
                        onTap: () =>
                            controller.toggleAppSelection(app.packageName),
                        child: Row(
                          children: [
                            // Authentic App Icon with fallback
                            AppIconWidget(
                              app: app,
                              size: 46,
                              borderRadius: 12,
                              isSelected: isSelected,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    app.appName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    app.category.isNotEmpty
                                        ? app.category
                                        : (isBn
                                              ? 'সোশ্যাল মিডিয়া'
                                              : 'Social media'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                                color: isSelected
                                    ? AppColors.primaryGreen
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryGreen
                                      : AppColors.border,
                                  width: 1.5,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.black,
                                    )
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isBn ? 'এগিয়ে যান' : 'Continue',
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
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
