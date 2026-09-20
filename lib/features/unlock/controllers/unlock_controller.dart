import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:focus_deen/core/services/native_bridge_service.dart';
import 'package:focus_deen/core/services/pin_security_service.dart';
import 'package:focus_deen/core/services/storage_service.dart';
import 'package:focus_deen/features/unlock/models/unlock_session_model.dart';
import 'package:focus_deen/features/unlock/services/recitation_scoring_service.dart';
import 'package:focus_deen/features/security/views/pin_dialog.dart';

class UnlockController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();
  final NativeBridgeService _nativeBridge = Get.find<NativeBridgeService>();
  final PinSecurityService _pinService = Get.find<PinSecurityService>();
  final RecitationScoringService _scoringService = RecitationScoringService();

  final RxString packageName = ''.obs;
  final RxString appName = ''.obs;
  final RxInt selectedScore = 85.obs; // Simulates score achieved (70-100)
  final RxBool isUnlocking = false.obs;

  // Active sessions in the system
  final RxList<UnlockSessionModel> activeSessions = <UnlockSessionModel>[].obs;
  Timer? _ticker;

  // Phase 5 Audio Recitation Verification
  final RxInt selectedVerseIndex = 0.obs;
  final RxBool isRecording = false.obs;
  final RxInt recordingSeconds = 0.obs;
  final Rx<RecitationScoreResult?> recitationResult = Rx<RecitationScoreResult?>(null);
  Timer? _recordingTimer;

  List<QuranVerseToRecite> get verses => RecitationScoringService.challengeVerses;
  QuranVerseToRecite get currentVerse => verses[selectedVerseIndex.value];

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      packageName.value = args['packageName']?.toString() ?? '';
      appName.value = args['appName']?.toString() ?? 'App';
    }
    loadActiveSessions();
    _startCountdownTicker();
  }

  @override
  void onClose() {
    _ticker?.cancel();
    _recordingTimer?.cancel();
    super.onClose();
  }

  void _startCountdownTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      activeSessions.removeWhere((s) => s.isExpired);
      activeSessions.refresh();
    });
  }

  void loadActiveSessions() {
    activeSessions.assignAll(_storageService.getUnlockSessions());
  }

  void selectVerse(int index) {
    if (index >= 0 && index < verses.length) {
      selectedVerseIndex.value = index;
      recitationResult.value = null;
      recordingSeconds.value = 0;
    }
  }

  void toggleRecording() {
    if (!isRecording.value) {
      startRecording();
    } else {
      stopRecordingAndScore();
    }
  }

  void startRecording() {
    isRecording.value = true;
    recordingSeconds.value = 0;
    recitationResult.value = null;
    HapticFeedback.mediumImpact();

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      recordingSeconds.value++;
    });
  }

  void stopRecordingAndScore() {
    isRecording.value = false;
    _recordingTimer?.cancel();
    HapticFeedback.mediumImpact();

    // Evaluate recitation via scoring engine
    final result = _scoringService.evaluateRecitation(
      durationSeconds: recordingSeconds.value,
      verse: currentVerse,
    );

    recitationResult.value = result;
    selectedScore.value = result.scorePercentage;
  }

  int getDurationForScore(int score) {
    if (score >= 90) return 15;
    if (score >= 80) return 10;
    if (score >= 70) return 5;
    return 0; // Below 70% does not qualify
  }

  /// Controlled unlock interface
  Future<bool> unlock({
    required String targetPackage,
    required String targetAppName,
    required int durationMinutes,
  }) async {
    // If strict mode is active, check PIN
    if (_pinService.isStrictModeActive()) {
      final verified = await PinDialog.show(
        title: 'Strict Mode Check',
        subtitle: 'Enter PIN to confirm temporary unlock',
      );
      if (!verified) return false;
    }

    isUnlocking.value = true;

    try {
      final expiresAt = DateTime.now().millisecondsSinceEpoch + (durationMinutes * 60 * 1000);
      final newSession = UnlockSessionModel(
        packageName: targetPackage,
        appName: targetAppName,
        durationMinutes: durationMinutes,
        expiresAtTimestamp: expiresAt,
      );

      // 1. Sync to Native Android Layer
      await _nativeBridge.setTemporaryUnlock(targetPackage, durationMinutes);

      // 2. Persist in StorageService
      final existing = _storageService.getUnlockSessions();
      existing.removeWhere((s) => s.packageName == targetPackage);
      existing.add(newSession);
      _storageService.saveUnlockSessions(existing);

      activeSessions.assignAll(existing);

      Get.snackbar(
        'Unlocked for $durationMinutes Minutes',
        '$targetAppName is temporarily unlocked until ${TimeOfDay.fromDateTime(DateTime.fromMillisecondsSinceEpoch(expiresAt)).format(Get.context!)}.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade800,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );

      Get.offAllNamed('/dashboard');
      return true;
    } catch (e) {
      debugPrint('Error in unlock: $e');
      return false;
    } finally {
      isUnlocking.value = false;
    }
  }

  Future<void> revokeUnlock(String targetPackage) async {
    await _nativeBridge.removeTemporaryUnlock(targetPackage);
    final existing = _storageService.getUnlockSessions();
    existing.removeWhere((s) => s.packageName == targetPackage);
    _storageService.saveUnlockSessions(existing);
    activeSessions.assignAll(existing);
  }
}
