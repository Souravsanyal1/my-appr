import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/services/firebase_realtime_service.dart';
import '../../../core/services/native_bridge_service.dart';
import '../../../core/services/pin_security_service.dart';
import '../../../core/services/storage_service.dart';
import '../../security/views/pin_dialog.dart';
import '../models/unlock_session_model.dart';
import '../services/pronunciation_analyzer.dart';
import '../services/recitation_scoring_service.dart';

class UnlockController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();
  final NativeBridgeService _nativeBridge = Get.find<NativeBridgeService>();
  final PinSecurityService _pinService = Get.find<PinSecurityService>();
  final PronunciationAnalyzer _analyzer = LocalPronunciationAnalyzer();

  final RxString packageName = ''.obs;
  final RxString appName = ''.obs;
  final RxInt selectedScore = 85.obs;
  final RxBool isUnlocking = false.obs;
  final RxBool isAnalyzing = false.obs;

  // Active sessions in the system
  final RxList<UnlockSessionModel> activeSessions = <UnlockSessionModel>[].obs;
  Timer? _ticker;

  // Recitation Verification
  final RxInt selectedVerseIndex = 0.obs;
  final RxBool isRecording = false.obs;
  final RxInt recordingSeconds = 0.obs;
  final Rx<PronunciationResult?> recitationResult = Rx<PronunciationResult?>(null);
  Timer? _recordingTimer;

  List<QuranVerseToRecite> get verses => RecitationScoringService.challengeVerses;
  QuranVerseToRecite get currentVerse => verses[selectedVerseIndex.value];

  int get configuredThreshold =>
      _storageService.read<int>('unlock_threshold_percentage') ?? 80;

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

  Future<void> stopRecordingAndScore() async {
    isRecording.value = false;
    _recordingTimer?.cancel();
    HapticFeedback.mediumImpact();

    isAnalyzing.value = true;
    try {
      final result = await _analyzer.analyze(
        expectedArabic: currentVerse.arabic,
        expectedTransliteration: currentVerse.transliteration,
        durationSeconds: recordingSeconds.value,
        minDurationSeconds: currentVerse.minRecitationSeconds,
        unlockThreshold: configuredThreshold,
      );

      recitationResult.value = result;
      selectedScore.value = result.overallScore;

      // Update recitation stats
      final totalRecitations = (_storageService.read<int>('total_recitations') ?? 0) + 1;
      _storageService.write('total_recitations', totalRecitations);
    } finally {
      isAnalyzing.value = false;
    }
  }

  int getDurationForScore(int score) {
    if (score >= 90) return 15;
    if (score >= 80) return 10;
    if (score >= 70) return 5;
    return 0;
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

      // 3. Broadcast to Firebase Realtime Database
      try {
        if (Get.isRegistered<FirebaseRealtimeService>()) {
          Get.find<FirebaseRealtimeService>().syncUnlockSession(newSession);
        }
      } catch (e) {
        debugPrint('Realtime sync error: $e');
      }

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
    try {
      if (Get.isRegistered<FirebaseRealtimeService>()) {
        Get.find<FirebaseRealtimeService>().removeUnlockSession(targetPackage);
      }
    } catch (e) {
      debugPrint('Realtime remove unlock error: $e');
    }
    final existing = _storageService.getUnlockSessions();
    existing.removeWhere((s) => s.packageName == targetPackage);
    _storageService.saveUnlockSessions(existing);
    activeSessions.assignAll(existing);
  }
}
