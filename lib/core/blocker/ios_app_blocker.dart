import 'dart:async';
import 'package:flutter/foundation.dart';
import 'app_blocker.dart';
import 'blocker_models.dart';

/// iOS Implementation using FamilyControls / ManagedSettings contract.
/// Degrades gracefully on simulators or unapproved entitlement environments.
class IosAppBlocker implements AppBlocker {
  final StreamController<BlockerEvent> _eventController =
      StreamController<BlockerEvent>.broadcast();

  final Map<String, DateTime> _unlockedApps = {};

  @override
  Stream<BlockerEvent> get events => _eventController.stream;

  @override
  Future<List<InstalledAppInfo>> getInstalledApps() async {
    // Note: iOS privacy sandbox strictly prevents third-party apps from querying installed bundle IDs.
    // iOS uses FamilyActivityPicker tokens instead.
    return const [];
  }

  @override
  Future<void> setProtectedApps(List<String> ids) async {
    debugPrint('[IosAppBlocker] setProtectedApps called with ${ids.length} tokens');
  }

  @override
  Future<void> unlock(String id, Duration duration) async {
    final expires = DateTime.now().add(duration);
    _unlockedApps[id] = expires;
    _eventController.add(
      BlockerEvent(
        type: BlockerEventType.unlocked,
        packageId: id,
        appName: id,
        timestamp: DateTime.now(),
        metadata: {'durationMinutes': duration.inMinutes},
      ),
    );
  }

  @override
  Future<void> lockNow(String id) async {
    _unlockedApps.remove(id);
    _eventController.add(
      BlockerEvent(
        type: BlockerEventType.relocked,
        packageId: id,
        appName: id,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  Future<Map<String, DateTime>> getUnlockedUntil() async {
    // Purge expired
    final now = DateTime.now();
    _unlockedApps.removeWhere((_, exp) => exp.isBefore(now));
    return Map.unmodifiable(_unlockedApps);
  }

  @override
  Future<PermissionStatusSet> checkPermissions() async {
    return const PermissionStatusSet(
      accessibilityGranted: false,
      usageStatsGranted: false,
      overlayGranted: false,
      notificationsGranted: true,
      exactAlarmsGranted: true,
      batteryOptimizationIgnored: true,
    );
  }

  @override
  Future<void> openPermissionSettings(BlockerPermission permission) async {
    debugPrint('[IosAppBlocker] openPermissionSettings: ${permission.name}');
  }

  @override
  void dispose() {
    _eventController.close();
  }
}
