import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../features/limits/models/app_limit_model.dart';
import '../../features/unlock/models/unlock_session_model.dart';
import 'native_bridge_service.dart';

class StorageService extends GetxService {
  late final GetStorage _box;

  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyLimits = 'app_limits';
  static const String keyMonitoredPackages = 'monitored_packages';
  static const String keyUnlockSessions = 'unlock_sessions';
  static const String keyStrictMode = 'strict_mode';
  static const String keyPinHash = 'security_pin_hash';

  Future<StorageService> init() async {
    await GetStorage.init();
    _box = GetStorage();
    return this;
  }

  // Onboarding
  bool isOnboardingComplete() {
    return _box.read<bool>(keyOnboardingComplete) ?? false;
  }

  void setOnboardingComplete(bool complete) {
    _box.write(keyOnboardingComplete, complete);
  }

  // Limits
  List<AppLimitModel> getLimits() {
    final raw = _box.read<List<dynamic>>(keyLimits);
    if (raw == null) return [];
    return raw
        .map((e) => AppLimitModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  void saveLimits(List<AppLimitModel> limits) {
    final raw = limits.map((e) => e.toMap()).toList();
    _box.write(keyLimits, raw);
  }

  // Monitored Packages
  List<String> getMonitoredPackages() {
    final raw = _box.read<List<dynamic>>(keyMonitoredPackages);
    if (raw == null || raw.isEmpty) {
      return [
        'com.zhiliaoapp.musically',
        'com.ss.android.ugc.trill',
        'com.instagram.android',
        'com.facebook.katana',
        'com.google.android.youtube',
        'com.snapchat.android',
      ];
    }
    return raw.map((e) => e.toString()).toList();
  }

  void saveMonitoredPackages(List<String> packages) {
    _box.write(keyMonitoredPackages, packages);
    try {
      if (Get.isRegistered<NativeBridgeService>()) {
        Get.find<NativeBridgeService>().syncMonitoredPackages(packages);
      }
    } catch (e) {
      // Ignored if service not yet initialized
    }
  }

  // Temporary Unlock Sessions
  List<UnlockSessionModel> getUnlockSessions() {
    final raw = _box.read<List<dynamic>>(keyUnlockSessions);
    if (raw == null) return [];
    final now = DateTime.now().millisecondsSinceEpoch;
    final sessions = raw
        .map(
          (e) =>
              UnlockSessionModel.fromMap(Map<String, dynamic>.from(e as Map)),
        )
        .where((s) => s.expiresAtTimestamp > now) // filter out expired
        .toList();
    return sessions;
  }

  void saveUnlockSessions(List<UnlockSessionModel> sessions) {
    final raw = sessions.map((e) => e.toMap()).toList();
    _box.write(keyUnlockSessions, raw);
  }

  // Strict Mode & Security PIN
  bool isStrictModeEnabled() {
    return _box.read<bool>(keyStrictMode) ?? false;
  }

  void setStrictModeEnabled(bool enabled) {
    _box.write(keyStrictMode, enabled);
  }

  String? getPinHash() {
    return _box.read<String>(keyPinHash);
  }

  void savePinHash(String hash) {
    _box.write(keyPinHash, hash);
  }

  bool hasPinSet() {
    final hash = getPinHash();
    return hash != null && hash.isNotEmpty;
  }

  // Generic key-value helpers
  T? read<T>(String key) => _box.read<T>(key);
  void write(String key, dynamic value) => _box.write(key, value);
  void clear() => _box.erase();
}
