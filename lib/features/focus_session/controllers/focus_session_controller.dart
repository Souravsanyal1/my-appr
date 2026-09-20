import 'dart:async';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class FocusSessionController extends GetxController {
  final RxInt selectedDurationMinutes = 25.obs;
  final RxInt remainingSeconds = (25 * 60).obs;
  final RxBool isRunning = false.obs;
  final RxBool isBreak = false.obs;
  final RxInt completedSessionsCount = 0.obs;

  Timer? _timer;

  final List<String> mindfulReminders = [
    "“And whoever relies upon Allah – then He is sufficient for him.” (Surah At-Talaq 65:3)",
    "“Indeed, with hardship comes ease.” (Surah Ash-Sharh 94:6)",
    "Guard your intention (Niyyah). Dedicate this focused work for the sake of Allah.",
    "Breathe deeply and say: Astaghfirullah. Clear your mind of digital noise.",
    "“The most beloved deed to Allah is the most regular and constant, even if it were little.” (Bukhari)",
  ];
  final RxInt currentReminderIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    completedSessionsCount.value = 0;
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  void setDuration(int minutes) {
    if (!isRunning.value) {
      selectedDurationMinutes.value = minutes;
      remainingSeconds.value = minutes * 60;
    }
  }

  void startSession() {
    isRunning.value = true;
    HapticFeedback.mediumImpact();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
        // Rotate reminder every 3 minutes
        if (remainingSeconds.value % 180 == 0) {
          currentReminderIndex.value =
              (currentReminderIndex.value + 1) % mindfulReminders.length;
        }
      } else {
        _onSessionComplete();
      }
    });
  }

  void pauseSession() {
    isRunning.value = false;
    _timer?.cancel();
    HapticFeedback.lightImpact();
  }

  void resetSession() {
    pauseSession();
    isBreak.value = false;
    remainingSeconds.value = selectedDurationMinutes.value * 60;
  }

  void _onSessionComplete() {
    _timer?.cancel();
    isRunning.value = false;
    HapticFeedback.heavyImpact();

    if (!isBreak.value) {
      completedSessionsCount.value++;
      isBreak.value = true;
      remainingSeconds.value = 5 * 60; // 5 minute sunnah break
      Get.snackbar(
        'Barakah Focus Complete! 🎉',
        'MashAllah! 25 minutes of mindful focus completed. Enjoy a 5-minute reflection break.',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 5),
      );
    } else {
      isBreak.value = false;
      remainingSeconds.value = selectedDurationMinutes.value * 60;
      Get.snackbar(
        'Break Ended',
        'Ready to begin another mindful focus block with renewed intention.',
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  String get formattedTime {
    final mins = remainingSeconds.value ~/ 60;
    final secs = remainingSeconds.value % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  double get progress {
    final total = (isBreak.value ? 5 : selectedDurationMinutes.value) * 60;
    if (total == 0) return 1.0;
    return (1.0 - (remainingSeconds.value / total)).clamp(0.0, 1.0);
  }
}
