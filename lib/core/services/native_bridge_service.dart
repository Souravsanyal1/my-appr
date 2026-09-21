import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../constants/channel_constants.dart';
import '../../features/app_selection/models/installed_app_model.dart';
import '../../features/limits/models/app_limit_model.dart';

class NativeBridgeService extends GetxService {
  static const MethodChannel _methodChannel = MethodChannel(
    ChannelConstants.methodChannel,
  );
  static const EventChannel _eventChannel = EventChannel(
    ChannelConstants.eventChannel,
  );

  final _foregroundAppController = StreamController<String>.broadcast();
  Stream<String> get foregroundAppStream => _foregroundAppController.stream;

  final _appBlockedController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get appBlockedStream =>
      _appBlockedController.stream;

  final _limitWarningController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get limitWarningStream =>
      _limitWarningController.stream;

  final _ttsStateController = StreamController<bool>.broadcast();
  Stream<bool> get ttsStateStream => _ttsStateController.stream;
  final RxBool isSpeakingRx = false.obs;

  StreamSubscription? _eventSubscription;

  @override
  void onInit() {
    super.onInit();
    _setupMethodCallHandler();
    _listenToNativeEvents();
  }

  void _setupMethodCallHandler() {
    _methodChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onAudioStart':
        case 'onTtsStart':
          isSpeakingRx.value = true;
          _ttsStateController.add(true);
          break;
        case 'onAudioDone':
        case 'onAudioError':
        case 'onTtsDone':
        case 'onTtsError':
          isSpeakingRx.value = false;
          _ttsStateController.add(false);
          break;
      }
    });
  }

  @override
  void onClose() {
    stopSpeaking();
    _eventSubscription?.cancel();
    _foregroundAppController.close();
    _appBlockedController.close();
    _limitWarningController.close();
    _ttsStateController.close();
    super.onClose();
  }

  void _listenToNativeEvents() {
    if (!Platform.isAndroid) return;

    try {
      _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          if (event is Map) {
            final type = event['type'] as String?;
            switch (type) {
              case ChannelConstants.eventForegroundAppChanged:
                final pkg = event['packageName'] as String?;
                if (pkg != null && pkg.isNotEmpty) {
                  _foregroundAppController.add(pkg);
                }
                break;
              case ChannelConstants.eventAppBlocked:
                _appBlockedController.add(Map<String, dynamic>.from(event));
                break;
              case ChannelConstants.eventLimitWarning:
                _limitWarningController.add(Map<String, dynamic>.from(event));
                break;
            }
          }
        },
        onError: (dynamic error) {
          debugPrint('FocusDeen EventChannel Error: $error');
        },
      );
    } catch (e) {
      debugPrint('Could not initialize Native EventChannel: $e');
    }
  }

  /// Check system permissions: usageStats, accessibility, overlay, notifications
  Future<Map<String, bool>> checkPermissions() async {
    if (!Platform.isAndroid) {
      return {
        'usageStats': true,
        'accessibility': true,
        'overlay': true,
        'notifications': true,
      };
    }

    try {
      final res = await _methodChannel.invokeMethod<Map>(
        ChannelConstants.checkPermissions,
      );
      if (res != null) {
        return res.map((key, value) => MapEntry(key.toString(), value == true));
      }
    } catch (e) {
      debugPrint('Error checking permissions: $e');
    }

    return {
      'usageStats': false,
      'accessibility': false,
      'overlay': false,
      'notifications': false,
    };
  }

  /// Request system permission intent
  Future<bool> requestPermission(String permissionType) async {
    if (!Platform.isAndroid) return true;
    try {
      final res = await _methodChannel.invokeMethod<bool>(
        ChannelConstants.requestPermission,
        {'permissionType': permissionType},
      );
      return res ?? false;
    } catch (e) {
      debugPrint('Error requesting permission $permissionType: $e');
      return false;
    }
  }

  /// Open FocusDeen App Info settings (to bypass Android 13+ "Restricted settings")
  Future<void> openAppSettings() async {
    await requestPermission('appSettings');
  }

  Future<bool> checkUsageAccess() async =>
      (await checkPermissions())['usageStats'] ?? false;
  Future<bool> checkAccessibilityPermission() async =>
      (await checkPermissions())['accessibility'] ?? false;
  Future<bool> checkOverlayPermission() async =>
      (await checkPermissions())['overlay'] ?? false;
  Future<bool> requestUsageAccess() async => requestPermission('usageStats');

  /// Get installed launcher apps
  Future<List<InstalledAppModel>> getInstalledApps() async {
    if (!Platform.isAndroid) {
      // Return sample demo data when testing on desktop/emulator
      return _getDemoApps();
    }

    try {
      final List<dynamic>? res = await _methodChannel
          .invokeMethod<List<dynamic>>(ChannelConstants.getInstalledApps);
      if (res != null) {
        return res
            .map(
              (e) => InstalledAppModel.fromMap(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
      }
    } catch (e) {
      debugPrint('Error getting installed apps: $e');
    }

    return _getDemoApps();
  }

  /// Get app usage in milliseconds for packages
  Future<Map<String, int>> getAppUsage({
    List<String>? packages,
    int? startTime,
    int? endTime,
  }) async {
    if (!Platform.isAndroid) {
      return {
        'com.instagram.android': 24 * 60 * 1000,
        'com.zhiliaoapp.musically': 18 * 60 * 1000,
        'com.facebook.katana': 35 * 60 * 1000,
        'com.google.android.youtube': 45 * 60 * 1000,
      };
    }

    try {
      final res = await _methodChannel.invokeMethod<Map>(
        ChannelConstants.getAppUsage,
        {'packages': packages, 'startTime': startTime, 'endTime': endTime},
      );
      if (res != null) {
        return res.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
      }
    } catch (e) {
      debugPrint('Error getting app usage: $e');
    }

    return {};
  }

  /// Sync limits to native service
  Future<bool> syncLimits(List<AppLimitModel> limits) async {
    if (!Platform.isAndroid) return true;
    try {
      final res = await _methodChannel.invokeMethod<bool>(
        ChannelConstants.syncLimits,
        {'limits': limits.map((l) => l.toMap()).toList()},
      );
      return res ?? false;
    } catch (e) {
      debugPrint('Error syncing limits: $e');
      return false;
    }
  }

  /// Sync monitored/protected packages list to native Android service
  Future<bool> syncMonitoredPackages(List<String> packages) async {
    if (!Platform.isAndroid) return true;
    try {
      final res = await _methodChannel.invokeMethod<bool>(
        ChannelConstants.syncMonitoredPackages,
        {'packages': packages},
      );
      return res ?? false;
    } catch (e) {
      debugPrint('Error syncing monitored packages: $e');
      return false;
    }
  }

  /// Set temporary unlock duration for an app
  Future<bool> setTemporaryUnlock(
    String packageName,
    int durationMinutes,
  ) async {
    if (!Platform.isAndroid) return true;
    try {
      final res = await _methodChannel.invokeMethod<bool>(
        ChannelConstants.setTemporaryUnlock,
        {'packageName': packageName, 'durationMinutes': durationMinutes},
      );
      return res ?? false;
    } catch (e) {
      debugPrint('Error setting temporary unlock: $e');
      return false;
    }
  }

  /// Remove temporary unlock
  Future<bool> removeTemporaryUnlock(String packageName) async {
    if (!Platform.isAndroid) return true;
    try {
      final res = await _methodChannel.invokeMethod<bool>(
        ChannelConstants.removeTemporaryUnlock,
        {'packageName': packageName},
      );
      return res ?? false;
    } catch (e) {
      debugPrint('Error removing temporary unlock: $e');
      return false;
    }
  }

  /// Close the foreground app via accessibility service
  Future<bool> closeForegroundApp() async {
    if (!Platform.isAndroid) return true;
    try {
      final res = await _methodChannel.invokeMethod<bool>(
        ChannelConstants.closeForegroundApp,
      );
      return res ?? false;
    } catch (e) {
      debugPrint('Error closing foreground app: $e');
      return false;
    }
  }

  /// Check if battery optimization is disabled for this app
  Future<bool> isBatteryOptimizationIgnored() async {
    if (!Platform.isAndroid) return true;
    try {
      final res = await _methodChannel.invokeMethod<bool>(
        'isBatteryOptimizationIgnored',
      );
      return res ?? false;
    } catch (e) {
      debugPrint('Error checking battery optimization: $e');
      return false;
    }
  }

  /// Request exemption from battery optimization
  Future<bool> requestIgnoreBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;
    try {
      final res = await _methodChannel.invokeMethod<bool>(
        'requestIgnoreBatteryOptimizations',
      );
      return res ?? false;
    } catch (e) {
      debugPrint('Error requesting battery optimization exemption: $e');
      return false;
    }
  }

  List<InstalledAppModel> _getDemoApps() {
    return const [
      InstalledAppModel(
        packageName: 'com.instagram.android',
        appName: 'Instagram',
      ),
      InstalledAppModel(
        packageName: 'com.zhiliaoapp.musically',
        appName: 'TikTok',
      ),
      InstalledAppModel(
        packageName: 'com.facebook.katana',
        appName: 'Facebook',
      ),
      InstalledAppModel(
        packageName: 'com.google.android.youtube',
        appName: 'YouTube',
      ),
      InstalledAppModel(
        packageName: 'com.twitter.android',
        appName: 'X (Twitter)',
      ),
      InstalledAppModel(
        packageName: 'com.snapchat.android',
        appName: 'Snapchat',
      ),
    ];
  }

  /// Play authentic recitation audio from URL, falling back to speech if offline or error
  Future<bool> playAudio({
    required String url,
    required String fallbackText,
    String language = 'ar',
    String? fallbackPhonetic,
  }) async {
    if (kIsWeb || !Platform.isAndroid) {
      isSpeakingRx.value = true;
      _ttsStateController.add(true);
      Future.delayed(const Duration(seconds: 3), () {
        isSpeakingRx.value = false;
        _ttsStateController.add(false);
      });
      return true;
    }

    try {
      isSpeakingRx.value = true;
      final res = await _methodChannel
          .invokeMethod<bool>(ChannelConstants.playAudio, {
            'url': url,
            'fallbackText': fallbackText,
            'language': language,
            'fallbackPhonetic': fallbackPhonetic ?? '',
          });
      return res ?? false;
    } catch (e) {
      debugPrint('Error in playAudio: $e');
      return speak(
        text: fallbackText,
        language: language,
        fallbackPhonetic: fallbackPhonetic,
      );
    }
  }

  /// Recite text using on-device TextToSpeech with phonetic fallback
  Future<bool> speak({
    required String text,
    String language = 'ar',
    double rate = 0.85,
    String? fallbackPhonetic,
  }) async {
    if (kIsWeb || !Platform.isAndroid) {
      // Fallback simulation for tests/web
      isSpeakingRx.value = true;
      _ttsStateController.add(true);
      Future.delayed(const Duration(seconds: 2), () {
        isSpeakingRx.value = false;
        _ttsStateController.add(false);
      });
      return true;
    }

    try {
      isSpeakingRx.value = true;
      final res = await _methodChannel
          .invokeMethod<bool>(ChannelConstants.speak, {
            'text': text,
            'language': language,
            'rate': rate,
            'fallbackPhonetic': fallbackPhonetic ?? '',
          });
      return res ?? false;
    } catch (e) {
      isSpeakingRx.value = false;
      debugPrint('Error invoking speak: $e');
      return false;
    }
  }

  /// Stop current audio speech or recitation playback
  Future<void> stopSpeaking() async {
    isSpeakingRx.value = false;
    _ttsStateController.add(false);

    if (kIsWeb || !Platform.isAndroid) return;

    try {
      await _methodChannel.invokeMethod(ChannelConstants.stopAudio);
    } catch (e) {
      debugPrint('Error invoking stopSpeaking: $e');
    }
  }

  /// Check if the engine is actively speaking or playing audio
  Future<bool> isSpeaking() async {
    if (kIsWeb || !Platform.isAndroid) return isSpeakingRx.value;
    try {
      final res = await _methodChannel.invokeMethod<bool>(
        ChannelConstants.isSpeaking,
      );
      return res ?? false;
    } catch (e) {
      return false;
    }
  }
}
