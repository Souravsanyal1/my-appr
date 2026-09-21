import 'blocker_models.dart';

/// Abstract contract for the App Blocker system across all platforms.
abstract class AppBlocker {
  /// Retrieve launchable apps on the device
  Future<List<InstalledAppInfo>> getInstalledApps();

  /// Configure the set of protected app package/bundle IDs
  Future<void> setProtectedApps(List<String> ids);

  /// Temporarily unlock an app for a given duration
  Future<void> unlock(String id, Duration duration);

  /// Immediately lock a previously unlocked app
  Future<void> lockNow(String id);

  /// Query the map of currently unlocked apps and their expiration DateTimes
  Future<Map<String, DateTime>> getUnlockedUntil();

  /// Check permissions required for background app blocking
  Future<PermissionStatusSet> checkPermissions();

  /// Open system settings screen for a specific blocker permission
  Future<void> openPermissionSettings(BlockerPermission permission);

  /// Stream of real-time events from native service (blocked, unlocked, relocked)
  Stream<BlockerEvent> get events;

  /// Dispose any active subscriptions or channels
  void dispose();
}
