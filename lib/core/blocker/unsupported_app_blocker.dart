import 'dart:async';
import 'package:flutter/foundation.dart';
import 'app_blocker.dart';
import 'blocker_models.dart';

/// Fallback no-op implementation for web, desktop, and test environments.
class UnsupportedAppBlocker implements AppBlocker {
  final StreamController<BlockerEvent> _eventController =
      StreamController<BlockerEvent>.broadcast();

  final Map<String, DateTime> _simulatedUnlocked = {};

  @override
  Stream<BlockerEvent> get events => _eventController.stream;

  @override
  Future<List<InstalledAppInfo>> getInstalledApps() async {
    // Return sample demo apps for design and testing
    return const [
      InstalledAppInfo(
        id: 'com.facebook.katana',
        name: 'Facebook',
        category: 'Social media',
      ),
      InstalledAppInfo(
        id: 'com.instagram.android',
        name: 'Instagram',
        category: 'Social media',
      ),
      InstalledAppInfo(
        id: 'com.zhiliaoapp.musically',
        name: 'TikTok',
        category: 'Social media',
      ),
      InstalledAppInfo(
        id: 'com.google.android.youtube',
        name: 'YouTube',
        category: 'Video & Entertainment',
      ),
      InstalledAppInfo(
        id: 'com.snapchat.android',
        name: 'Snapchat',
        category: 'Social media',
      ),
      InstalledAppInfo(
        id: 'com.whatsapp',
        name: 'WhatsApp',
        category: 'Messaging',
      ),
    ];
  }

  @override
  Future<void> setProtectedApps(List<String> ids) async {
    debugPrint('[UnsupportedAppBlocker] setProtectedApps: ${ids.length} apps');
  }

  @override
  Future<void> unlock(String id, Duration duration) async {
    _simulatedUnlocked[id] = DateTime.now().add(duration);
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
    _simulatedUnlocked.remove(id);
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
    final now = DateTime.now();
    _simulatedUnlocked.removeWhere((_, exp) => exp.isBefore(now));
    return Map.unmodifiable(_simulatedUnlocked);
  }

  @override
  Future<PermissionStatusSet> checkPermissions() async {
    return const PermissionStatusSet(
      accessibilityGranted: true,
      usageStatsGranted: true,
      overlayGranted: true,
      notificationsGranted: true,
      exactAlarmsGranted: true,
      batteryOptimizationIgnored: true,
    );
  }

  @override
  Future<void> openPermissionSettings(BlockerPermission permission) async {
    debugPrint('[UnsupportedAppBlocker] openPermissionSettings: ${permission.name}');
  }

  @override
  void dispose() {
    _eventController.close();
  }
}
