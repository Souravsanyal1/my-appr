import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../constants/channel_constants.dart';
import 'app_blocker.dart';
import 'blocker_models.dart';

class AndroidAppBlocker implements AppBlocker {
  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;
  final StreamController<BlockerEvent> _eventController =
      StreamController<BlockerEvent>.broadcast();

  StreamSubscription? _nativeSubscription;

  AndroidAppBlocker({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _methodChannel = methodChannel ??
            const MethodChannel(ChannelConstants.methodChannel),
        _eventChannel = eventChannel ??
            const EventChannel(ChannelConstants.eventChannel) {
    _initEventChannel();
  }

  void _initEventChannel() {
    try {
      _nativeSubscription = _eventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          if (event is Map) {
            final typeStr = event['type'] as String? ?? '';
            final pkg = event['packageName'] as String? ?? '';
            final appName = event['appName'] as String? ?? '';

            BlockerEventType? type;
            if (typeStr == ChannelConstants.eventAppBlocked) {
              type = BlockerEventType.blockedAppOpened;
            } else if (typeStr == 'unlocked') {
              type = BlockerEventType.unlocked;
            } else if (typeStr == 'relocked') {
              type = BlockerEventType.relocked;
            } else if (typeStr == ChannelConstants.eventLimitWarning) {
              type = BlockerEventType.warning;
            }

            if (type != null) {
              _eventController.add(
                BlockerEvent(
                  type: type,
                  packageId: pkg,
                  appName: appName,
                  timestamp: DateTime.now(),
                  metadata: Map<String, dynamic>.from(event),
                ),
              );
            }
          }
        },
        onError: (error) {
          // Keep stream alive
        },
      );
    } catch (_) {}
  }

  @override
  Stream<BlockerEvent> get events => _eventController.stream;

  @override
  Future<List<InstalledAppInfo>> getInstalledApps() async {
    try {
      final List<dynamic>? res = await _methodChannel
          .invokeMethod<List<dynamic>>(ChannelConstants.getInstalledApps);
      if (res != null) {
        return res.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          final base64Str = map['iconBase64'] as String?;
          Uint8List? bytes;
          if (base64Str != null && base64Str.isNotEmpty) {
            try {
              bytes = base64Decode(base64Str);
            } catch (_) {}
          }

          return InstalledAppInfo(
            id: map['packageName'] as String? ?? '',
            name: map['appName'] as String? ?? '',
            category: map['category'] as String? ?? 'App',
            isSystemApp: map['isSystemApp'] as bool? ?? false,
            iconBytes: bytes,
          );
        }).toList();
      }
    } on PlatformException catch (e) {
      throw BlockerException(e.message ?? 'Failed to get installed apps');
    }
    return [];
  }

  @override
  Future<void> setProtectedApps(List<String> ids) async {
    try {
      await _methodChannel.invokeMethod('syncMonitoredPackages', {
        'packages': ids,
      });
    } on PlatformException catch (e) {
      throw BlockerException(e.message ?? 'Failed to sync protected apps');
    }
  }

  @override
  Future<void> unlock(String id, Duration duration) async {
    try {
      await _methodChannel.invokeMethod('setTemporaryUnlock', {
        'packageName': id,
        'durationMinutes': duration.inMinutes,
      });

      _eventController.add(
        BlockerEvent(
          type: BlockerEventType.unlocked,
          packageId: id,
          appName: id,
          timestamp: DateTime.now(),
          metadata: {'durationMinutes': duration.inMinutes},
        ),
      );
    } on PlatformException catch (e) {
      throw BlockerException(e.message ?? 'Failed to unlock app');
    }
  }

  @override
  Future<void> lockNow(String id) async {
    try {
      await _methodChannel.invokeMethod('removeTemporaryUnlock', {
        'packageName': id,
      });

      _eventController.add(
        BlockerEvent(
          type: BlockerEventType.relocked,
          packageId: id,
          appName: id,
          timestamp: DateTime.now(),
        ),
      );
    } on PlatformException catch (e) {
      throw BlockerException(e.message ?? 'Failed to lock app');
    }
  }

  @override
  Future<Map<String, DateTime>> getUnlockedUntil() async {
    final Map<String, DateTime> result = {};
    try {
      final List<dynamic>? sessions = await _methodChannel
          .invokeMethod<List<dynamic>>('getUnlockSessions');
      if (sessions != null) {
        for (final item in sessions) {
          final map = Map<String, dynamic>.from(item as Map);
          final pkg = map['packageName'] as String?;
          final expiresMillis = map['expiresAtMillis'] as int?;
          if (pkg != null && expiresMillis != null) {
            result[pkg] = DateTime.fromMillisecondsSinceEpoch(expiresMillis);
          }
        }
      }
    } catch (_) {}
    return result;
  }

  @override
  Future<PermissionStatusSet> checkPermissions() async {
    try {
      final Map? status = await _methodChannel
          .invokeMethod<Map>(ChannelConstants.checkPermissions);
      final isBatteryIgnored = await _methodChannel
              .invokeMethod<bool>('isBatteryOptimizationIgnored') ??
          false;

      if (status != null) {
        return PermissionStatusSet(
          accessibilityGranted: status['accessibility'] as bool? ?? false,
          usageStatsGranted: status['usageStats'] as bool? ?? false,
          overlayGranted: status['overlay'] as bool? ?? false,
          notificationsGranted: status['notifications'] as bool? ?? false,
          exactAlarmsGranted: true, // handled natively on Android 12+
          batteryOptimizationIgnored: isBatteryIgnored,
        );
      }
    } catch (_) {}

    return const PermissionStatusSet();
  }

  @override
  Future<void> openPermissionSettings(BlockerPermission permission) async {
    String typeStr;
    switch (permission) {
      case BlockerPermission.accessibility:
        typeStr = 'accessibility';
        break;
      case BlockerPermission.usageStats:
        typeStr = 'usageStats';
        break;
      case BlockerPermission.overlay:
        typeStr = 'overlay';
        break;
      case BlockerPermission.notifications:
        typeStr = 'notifications';
        break;
      case BlockerPermission.exactAlarms:
        typeStr = 'exactAlarms';
        break;
      case BlockerPermission.batteryOptimization:
        await _methodChannel
            .invokeMethod('requestIgnoreBatteryOptimizations');
        return;
    }

    try {
      await _methodChannel.invokeMethod(ChannelConstants.requestPermission, {
        'permissionType': typeStr,
      });
    } on PlatformException catch (e) {
      throw BlockerException(e.message ?? 'Failed to open permission settings');
    }
  }

  @override
  void dispose() {
    _nativeSubscription?.cancel();
    _eventController.close();
  }
}
