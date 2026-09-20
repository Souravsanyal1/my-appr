import 'package:get/get.dart';
import 'package:focus_deen/core/services/pin_security_service.dart';

class PinController extends GetxController {
  final PinSecurityService _pinService = Get.find<PinSecurityService>();

  final RxString enteredPin = ''.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isConfirming = false.obs;
  String _firstPinAttempt = '';

  void appendDigit(String digit) {
    if (enteredPin.value.length < 4) {
      enteredPin.value += digit;
      errorMessage.value = '';
    }
  }

  void backspace() {
    if (enteredPin.value.isNotEmpty) {
      enteredPin.value = enteredPin.value.substring(0, enteredPin.value.length - 1);
      errorMessage.value = '';
    }
  }

  void clear() {
    enteredPin.value = '';
    errorMessage.value = '';
  }

  /// Verify entered PIN against stored hash
  bool verify() {
    if (_pinService.isLockedOut) {
      errorMessage.value =
          'Too many attempts. Try again in ${_pinService.lockoutSecondsRemaining}s';
      return false;
    }

    final isValid = _pinService.verifyPin(enteredPin.value);
    if (!isValid) {
      errorMessage.value = 'Incorrect PIN';
      enteredPin.value = '';
      return false;
    }

    return true;
  }

  /// Setup a new PIN
  bool setupNewPin() {
    if (!isConfirming.value) {
      if (enteredPin.value.length == 4) {
        _firstPinAttempt = enteredPin.value;
        enteredPin.value = '';
        isConfirming.value = true;
        return false;
      }
    } else {
      if (enteredPin.value == _firstPinAttempt) {
        _pinService.setPin(enteredPin.value);
        isConfirming.value = false;
        _firstPinAttempt = '';
        return true;
      } else {
        errorMessage.value = 'PINs do not match. Try again.';
        enteredPin.value = '';
        isConfirming.value = false;
        _firstPinAttempt = '';
      }
    }
    return false;
  }
}
