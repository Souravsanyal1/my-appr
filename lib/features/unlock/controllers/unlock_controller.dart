import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../../core/services/firebase_realtime_service.dart';
import '../../../core/services/native_bridge_service.dart';
import '../../../core/services/pin_security_service.dart';
import '../../../core/services/storage_service.dart';
import '../../security/views/pin_dialog.dart';
import '../models/unlock_session_model.dart';
import '../services/pronunciation_analyzer.dart';
import '../services/recitation_scoring_service.dart';

import '../models/good_deed_model.dart';

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

  // Good Deed Flow
  final Rx<GoodDeedModel> activeDeed = GoodDeedModel.pool.first.obs;
  final RxInt repetitionCount = 0.obs;
  final RxBool isTranslated = false.obs;

  // Active sessions in the system
  final RxList<UnlockSessionModel> activeSessions = <UnlockSessionModel>[].obs;
  Timer? _ticker;

  // Recitation Verification
  final RxInt selectedVerseIndex = 0.obs;
  final RxBool isRecording = false.obs;
  final RxInt recordingSeconds = 0.obs;
  final Rx<PronunciationResult?> recitationResult = Rx<PronunciationResult?>(
    null,
  );
  Timer? _recordingTimer;

  // Real AudioRecorder state
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _recordingPath;
  double _peakAmplitudeDb = -160.0;
  double _avgAmplitudeSum = 0.0;
  int _ampSamples = 0;
  Timer? _amplitudeTimer;

  List<QuranVerseToRecite> get verses =>
      RecitationScoringService.challengeVerses;
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
    randomizeDeed();
    loadActiveSessions();
    _startCountdownTicker();
  }

  void randomizeDeed() {
    final pool = GoodDeedModel.pool;
    final nextIdx = (DateTime.now().millisecond) % pool.length;
    activeDeed.value = pool[nextIdx];
    repetitionCount.value = 0;
    isTranslated.value = false;
  }

  void setDeed(GoodDeedModel deed) {
    activeDeed.value = deed;
    repetitionCount.value = 0;
    isTranslated.value = false;
  }

  void incrementRepetition() {
    if (repetitionCount.value < activeDeed.value.targetRepetitions) {
      repetitionCount.value++;
      HapticFeedback.lightImpact();
    }
  }

  void toggleTranslate() {
    isTranslated.value = !isTranslated.value;
  }

  @override
  void onClose() {
    _ticker?.cancel();
    _recordingTimer?.cancel();
    _amplitudeTimer?.cancel();
    _audioRecorder.dispose();
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

  Future<void> startRecording() async {
    try {
      // Check permission
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        debugPrint('[UnlockController] Mic permission denied');
        return;
      }

      // Reset amplitude trackers
      _peakAmplitudeDb = -160.0;
      _avgAmplitudeSum = 0.0;
      _ampSamples = 0;
      recordingSeconds.value = 0;
      recitationResult.value = null;

      // Build temp file path
      final dir = await getTemporaryDirectory();
      _recordingPath = '${dir.path}/recitation_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: _recordingPath!,
      );

      isRecording.value = true;
      HapticFeedback.mediumImpact();

      // Elapsed time ticker
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        recordingSeconds.value++;
      });

      // Amplitude sampler — every 250ms to track peak + average
      _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 250), (_) async {
        try {
          final amp = await _audioRecorder.getAmplitude();
          final db = amp.current; // dBFS value
          if (db > _peakAmplitudeDb) _peakAmplitudeDb = db;
          _avgAmplitudeSum += db;
          _ampSamples++;
        } catch (_) {}
      });
    } catch (e) {
      debugPrint('[UnlockController] startRecording error: $e');
    }
  }

  Future<void> stopRecordingAndScore() async {
    _recordingTimer?.cancel();
    _amplitudeTimer?.cancel();
    HapticFeedback.mediumImpact();

    String? savedPath;
    try {
      savedPath = await _audioRecorder.stop();
    } catch (e) {
      debugPrint('[UnlockController] recorder.stop() error: $e');
      savedPath = _recordingPath;
    }

    isRecording.value = false;

    final double avgDb = _ampSamples > 0
        ? _avgAmplitudeSum / _ampSamples
        : -160.0;

    // Get recorded file size for silence check
    int? fileSizeBytes;
    try {
      if (savedPath != null) {
        fileSizeBytes = await File(savedPath).length();
      }
    } catch (_) {}

    debugPrint('[UnlockController] Recording done: path=$savedPath '
        'size=${fileSizeBytes}B peak=${_peakAmplitudeDb.toStringAsFixed(1)}dBFS '
        'avg=${avgDb.toStringAsFixed(1)}dBFS duration=${recordingSeconds.value}s');

    isAnalyzing.value = true;
    try {
      final result = await _analyzer.analyze(
        expectedArabic: currentVerse.arabic,
        expectedTransliteration: currentVerse.transliteration,
        durationSeconds: recordingSeconds.value,
        minDurationSeconds: currentVerse.minRecitationSeconds,
        unlockThreshold: configuredThreshold,
        audioPath: savedPath,
        peakAmplitudeDb: _peakAmplitudeDb,
        averageAmplitudeDb: avgDb,
        audioFileSizeBytes: fileSizeBytes,
      );

      recitationResult.value = result;
      selectedScore.value = result.overallScore;

      // Update recitation stats
      final totalRecitations =
          (_storageService.read<int>('total_recitations') ?? 0) + 1;
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
      final expiresAt =
          DateTime.now().millisecondsSinceEpoch + (durationMinutes * 60 * 1000);
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
