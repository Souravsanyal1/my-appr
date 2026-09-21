import 'dart:typed_data';

/// Installed application summary info
class InstalledAppInfo {
  final String id; // Package name or bundle identifier
  final String name;
  final String category;
  final bool isSystemApp;
  final Uint8List? iconBytes;

  const InstalledAppInfo({
    required this.id,
    required this.name,
    this.category = 'App',
    this.isSystemApp = false,
    this.iconBytes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'isSystemApp': isSystemApp,
    };
  }
}

/// Permissions required for screen time blocking
enum BlockerPermission {
  accessibility,
  usageStats,
  overlay,
  notifications,
  exactAlarms,
  batteryOptimization,
}

/// Set of permission statuses
class PermissionStatusSet {
  final bool accessibilityGranted;
  final bool usageStatsGranted;
  final bool overlayGranted;
  final bool notificationsGranted;
  final bool exactAlarmsGranted;
  final bool batteryOptimizationIgnored;

  const PermissionStatusSet({
    this.accessibilityGranted = false,
    this.usageStatsGranted = false,
    this.overlayGranted = false,
    this.notificationsGranted = false,
    this.exactAlarmsGranted = false,
    this.batteryOptimizationIgnored = false,
  });

  bool get isFullyOperational =>
      accessibilityGranted &&
      usageStatsGranted &&
      overlayGranted &&
      notificationsGranted;

  Map<String, bool> toMap() {
    return {
      'accessibility': accessibilityGranted,
      'usageStats': usageStatsGranted,
      'overlay': overlayGranted,
      'notifications': notificationsGranted,
      'exactAlarms': exactAlarmsGranted,
      'batteryOptimization': batteryOptimizationIgnored,
    };
  }
}

/// Types of blocker events dispatched from the native layer
enum BlockerEventType {
  blockedAppOpened,
  unlocked,
  relocked,
  warning,
}

/// Live event emitted from native blocker service
class BlockerEvent {
  final BlockerEventType type;
  final String packageId;
  final String appName;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const BlockerEvent({
    required this.type,
    required this.packageId,
    required this.appName,
    required this.timestamp,
    this.metadata = const {},
  });

  @override
  String toString() =>
      'BlockerEvent(type: $type, packageId: $packageId, time: $timestamp)';
}

/// Typed exceptions for Blocker operations
class BlockerException implements Exception {
  final String message;
  const BlockerException(this.message);

  @override
  String toString() => message;
}

class PermissionMissingException extends BlockerException {
  final BlockerPermission permission;
  PermissionMissingException(this.permission, [String? message])
      : super(
          message ??
              'Permission ${permission.name} is required to block applications.',
        );
}

class ServiceNotRunningException extends BlockerException {
  const ServiceNotRunningException([super.message = 'The app blocking service is not active.']);
}

class UnsupportedPlatformException extends BlockerException {
  const UnsupportedPlatformException([
    super.message = 'App blocking is not supported on this platform.',
  ]);
}

