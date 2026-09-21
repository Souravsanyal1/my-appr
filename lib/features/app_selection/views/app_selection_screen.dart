import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:focus_deen/core/constants/app_colors.dart';
import 'package:focus_deen/features/app_selection/controllers/app_selection_controller.dart';
import 'package:focus_deen/features/app_selection/models/installed_app_model.dart';

class AppSelectionScreen extends GetView<AppSelectionController> {
  const AppSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Apps to Monitor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadApps,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filters Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? AppColors.darkCardBorder
                      : AppColors.lightCardBorder,
                ),
              ),
            ),
            child: Column(
              children: [
                // Search Field
                TextField(
                  onChanged: controller.setSearchQuery,
                  decoration: InputDecoration(
                    hintText: 'Search apps or packages...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkCard
                        : Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Filter Tabs
                Obx(
                  () => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          'all',
                          'All Apps (${controller.allApps.length})',
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'monitored',
                          'Monitored (${controller.monitoredPackages.length})',
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip('user_only', 'Downloaded'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Apps List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.filteredApps.isEmpty) {
                return const Center(
                  child: Text('No apps found matching your query.'),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: controller.filteredApps.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  indent: 72,
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
                itemBuilder: (context, index) {
                  final app = controller.filteredApps[index];
                  return _buildAppTile(context, app);
                },
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: Obx(() {
        final count = controller.monitoredPackages.length;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            border: Border(
              top: BorderSide(
                color: isDark
                    ? AppColors.darkCardBorder
                    : AppColors.lightCardBorder,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$count apps selected for monitoring',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = controller.selectedFilter.value == filterKey;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      selectedColor: AppColors.primaryGold.withValues(alpha: 0.2),
      onSelected: (_) => controller.setFilter(filterKey),
    );
  }

  Widget _buildAppTile(BuildContext context, InstalledAppModel app) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isDark ? AppColors.darkCard : Colors.grey.shade200,
        ),
        clipBehavior: Clip.antiAlias,
        child: app.iconBytes != null
            ? Image.memory(app.iconBytes!, fit: BoxFit.cover)
            : const Icon(Icons.android, color: AppColors.emerald),
      ),
      title: Text(
        app.appName,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      subtitle: Text(
        app.packageName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        ),
      ),
      trailing: Switch(
        value: controller.monitoredPackages.contains(app.packageName),
        activeThumbColor: AppColors.primaryGold,
        onChanged: (_) => controller.toggleAppMonitored(app.packageName),
      ),
    );
  }
}
