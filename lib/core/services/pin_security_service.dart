import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:get/get.dart';
import 'storage_service.dart';

class PinSecurityService extends GetxService {
  final StorageService _storageService = Get.find<StorageService>();

  static const String _salt = "FocusDeen_Secure_Salt_2026";
  int _failedAttempts = 0;
  DateTime? _lockedUntil;

  bool get isLockedOut {
    if (_lockedUntil == null) return false;
    if (DateTime.now().isBefore(_lockedUntil!)) return true;
    _lockedUntil = null;
    _failedAttempts = 0;
    return false;
  }

  int get lockoutSecondsRemaining {
    if (_lockedUntil == null) return 0;
    final diff = _lockedUntil!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  bool isStrictModeActive() {
    return _storageService.isStrictModeEnabled() && _storageService.hasPinSet();
  }

  bool hasPin() {
    return _storageService.hasPinSet();
  }

  bool isPinConfigured() => hasPin();

  void setStrictMode(bool enabled) {
    _storageService.setStrictModeEnabled(enabled);
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin + _salt);
    return sha256.convert(bytes).toString();
  }

  bool setPin(String pin) {
    if (pin.length < 4) return false;
    final hash = _hashPin(pin);
    _storageService.savePinHash(hash);
    return true;
  }

  bool verifyPin(String pin) {
    if (isLockedOut) return false;

    final storedHash = _storageService.getPinHash();
    if (storedHash == null) return true; // No PIN set

    final hash = _hashPin(pin);
    if (hash == storedHash) {
      _failedAttempts = 0;
      _lockedUntil = null;
      return true;
    } else {
      _failedAttempts++;
      if (_failedAttempts >= 5) {
        // Lock out for 60 seconds
        _lockedUntil = DateTime.now().add(const Duration(seconds: 60));
      }
      return false;
    }
  }

  void toggleStrictMode(bool enabled) {
    _storageService.setStrictModeEnabled(enabled);
  }
}
