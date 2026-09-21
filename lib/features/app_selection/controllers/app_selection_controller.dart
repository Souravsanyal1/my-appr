import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:focus_deen/core/services/native_bridge_service.dart';
import 'package:focus_deen/core/services/storage_service.dart';
import 'package:focus_deen/features/app_selection/models/installed_app_model.dart';

class AppSelectionController extends GetxController {
  final NativeBridgeService _nativeBridge = Get.find<NativeBridgeService>();
  final StorageService _storageService = Get.find<StorageService>();

  final RxList<InstalledAppModel> allApps = <InstalledAppModel>[].obs;
  final RxList<InstalledAppModel> filteredApps = <InstalledAppModel>[].obs;
  final RxSet<String> monitoredPackages = <String>{}.obs;

  final RxString searchQuery = ''.obs;
  final RxString selectedFilter = 'all'.obs; // 'all', 'monitored', 'user_only'
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadApps();
  }

  Future<void> loadApps() async {
    isLoading.value = true;
    try {
      final savedMonitored = _storageService.getMonitoredPackages();
      monitoredPackages.assignAll(savedMonitored);

      final apps = await _nativeBridge.getInstalledApps();
      const priorityKeywords = [
        'tiktok',
        'musically',
        'instagram',
        'facebook',
        'youtube',
        'snapchat',
        'reddit',
        'twitter',
        'whatsapp',
        'telegram',
        'discord',
      ];

      final mapped = apps.map((app) {
        return app.copyWith(
          isMonitored: monitoredPackages.contains(app.packageName),
        );
      }).toList();

      mapped.sort((a, b) {
        final aMon = a.isMonitored ? 1 : 0;
        final bMon = b.isMonitored ? 1 : 0;
        if (aMon != bMon) return bMon.compareTo(aMon);

        final aPkg = a.packageName.toLowerCase();
        final aName = a.appName.toLowerCase();
        final bPkg = b.packageName.toLowerCase();
        final bName = b.appName.toLowerCase();

        final aIsPriority = priorityKeywords.any(
          (k) => aPkg.contains(k) || aName.contains(k),
        );
        final bIsPriority = priorityKeywords.any(
          (k) => bPkg.contains(k) || bName.contains(k),
        );

        if (aIsPriority && !bIsPriority) return -1;
        if (!aIsPriority && bIsPriority) return 1;

        return aName.compareTo(bName);
      });

      allApps.assignAll(mapped);
      applyFilter();
    } catch (e) {
      debugPrint('Error loading installed apps: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
    applyFilter();
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
    applyFilter();
  }

  void applyFilter() {
    var list = allApps.toList();

    if (selectedFilter.value == 'monitored') {
      list = list
          .where((a) => monitoredPackages.contains(a.packageName))
          .toList();
    } else if (selectedFilter.value == 'user_only') {
      list = list.where((a) => !a.isSystemApp).toList();
    }

    if (searchQuery.value.trim().isNotEmpty) {
      final q = searchQuery.value.toLowerCase().trim();
      list = list.where((a) {
        return a.appName.toLowerCase().contains(q) ||
            a.packageName.toLowerCase().contains(q);
      }).toList();
    }

    filteredApps.assignAll(list);
  }

  void toggleAppMonitored(String packageName) {
    if (monitoredPackages.contains(packageName)) {
      monitoredPackages.remove(packageName);
    } else {
      monitoredPackages.add(packageName);
    }

    final idx = allApps.indexWhere((a) => a.packageName == packageName);
    if (idx >= 0) {
      allApps[idx] = allApps[idx].copyWith(
        isMonitored: monitoredPackages.contains(packageName),
      );
    }

    _storageService.saveMonitoredPackages(monitoredPackages.toList());
    applyFilter();
  }

  // Convenience aliases for onboarding flows
  RxList<InstalledAppModel> get installedApps => allApps;
  RxSet<String> get selectedPackages => monitoredPackages;
  void toggleAppSelection(String pkg) => toggleAppMonitored(pkg);
  void saveSelection() {
    _storageService.saveMonitoredPackages(monitoredPackages.toList());
  }
}
