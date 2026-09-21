import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/language_service.dart';
import '../../../core/widgets/app_icon_widget.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../app_selection/controllers/app_selection_controller.dart';

class ChooseAppsScreen extends StatelessWidget {
  const ChooseAppsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<AppSelectionController>()
        ? Get.find<AppSelectionController>()
        : Get.put(AppSelectionController());
    final languageService = LanguageService.to;

    return Obx(() {
      final isBn = languageService.isBangla;
      final selectedCat = controller.selectedCategory.value;
      final selectedCount = controller.selectedPackages.length;

      final categories = [
        {'id': 'all', 'label': isBn ? 'সকল' : 'All'},
        {'id': 'social', 'label': isBn ? 'সোশ্যাল মিডিয়া' : 'Social'},
        {'id': 'messaging', 'label': isBn ? 'মেসেজিং' : 'Messaging'},
        {'id': 'video', 'label': isBn ? 'ভিডিও ও বিনোদন' : 'Video'},
        {'id': 'gaming', 'label': isBn ? 'গেমিং' : 'Gaming'},
      ];

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
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: TextButton.icon(
                  onPressed: () {
                    if (selectedCount == controller.filteredApps.length &&
                        selectedCount > 0) {
                      controller.clearAllSelections();
                    } else {
                      controller.selectAllVisible();
                    }
                  },
                  icon: Icon(
                    selectedCount > 0
                        ? Icons.remove_circle_outline
                        : Icons.playlist_add_check,
                    size: 16,
                    color: AppColors.brightGreen,
                  ),
                  label: Text(
                    selectedCount == controller.filteredApps.length &&
                            selectedCount > 0
                        ? (isBn ? 'সব মুছুন' : 'Clear all')
                        : (isBn ? 'সব নির্বাচন' : 'Select all'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brightGreen,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 4.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Headline
                Text(
                  isBn
                      ? 'কোন অ্যাপগুলো\nসুরক্ষা করবেন?'
                      : 'What should we\nprotect?',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),

                // Subtitle
                Text(
                  isBn
                      ? 'যে অ্যাপগুলো আপনি সচেতনভাবে ব্যবহার করতে চান সেগুলো বেছে নিন।'
                      : 'Choose the apps you want to use more intentionally.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),

                // Search Bar
                Container(
                  height: 48,
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
                      hintText: isBn
                          ? 'অ্যাপের নাম বা প্যাকেজ দিয়ে খুঁজুন...'
                          : 'Search installed apps...',
                      hintStyle: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Category Filter Chips Row
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isCurrent = selectedCat == cat['id'];

                      return InkWell(
                        onTap: () => controller.setCategory(cat['id']!),
                        borderRadius: BorderRadius.circular(18),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? AppColors.primaryGreen
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isCurrent
                                  ? AppColors.primaryGreen
                                  : AppColors.border,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              cat['label']!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isCurrent
                                    ? Colors.black
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // App Count and Status Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.0,
                    vertical: 2.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isBn
                            ? '${controller.filteredApps.length}টি অ্যাপ পাওয়া গেছে'
                            : '${controller.filteredApps.length} apps available',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (selectedCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brightGreen.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isBn
                                ? '$selectedCountটি সুরক্ষিত'
                                : '$selectedCount protected',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.brightGreen,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // List of Protected Apps
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value &&
                        controller.allApps.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: AppColors.primaryGreen,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'ইনস্টল করা অ্যাপগুলো লোড হচ্ছে...',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final displayList = controller.filteredApps;

                    if (displayList.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isBn
                                  ? 'কোনো অ্যাপ পাওয়া যায়নি'
                                  : 'No apps found',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isBn
                                  ? 'অন্য কোনো নাম দিয়ে সন্ধান করুন।'
                                  : 'Try searching with a different name.',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: displayList.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
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
                                size: 44,
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
                                        fontSize: 15,
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
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
                          selectedCount > 0
                              ? (isBn
                                    ? 'এগিয়ে যান ($selectedCountটি নির্বাচিত)'
                                    : 'Continue ($selectedCount selected)')
                              : (isBn ? 'এগিয়ে যান' : 'Continue'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );
    });
  }
}
