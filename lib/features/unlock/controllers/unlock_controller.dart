import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/services/firebase_realtime_service.dart';
import '../../../core/services/native_bridge_service.dart';
import '../../../core/services/pin_security_service.dart';
import '../../../core/services/storage_service.dart';
import '../../security/views/pin_dialog.dart';
import '../models/unlock_session_model.dart';
import '../services/pronunciation_analyzer.dart';
import '../services/recitation_scoring_service.dart';

import '../models/good_deed_model.dart';

enum VoiceTrackMode {
  arabic, // 🇸🇦 আরবি
  banglaPronun, // 🇧🇩 উচ্চারণ
  banglaMeaning, // 📖 বাংলা অর্থ
  englishMeaning, // 🇬🇧 English Meaning
}

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

  // ── Word-by-word voice tracking ──────────────────────────────────────────
  final stt.SpeechToText _speech = stt.SpeechToText();
  final RxBool speechAvailable = false.obs;
  final RxBool isWordTracking = false.obs;
  final RxString liveRecognizedText = ''.obs;
  final RxString trackingStatusMessage = ''.obs;
  final RxDouble soundLevel = 0.0.obs;
  final Rx<VoiceTrackMode> activeVoiceMode = VoiceTrackMode.arabic.obs;
  final RxList<bool> currentWordMatches = <bool>[].obs;

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
    _initSpeech();
  }

  bool _fallbackToDefaultLocale = false;
  Timer? _restartListenTimer;

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onError: (e) {
          debugPrint('[STT] error: ${e.errorMsg}');
          // If error is no_match or language not supported, fallback to system default locale
          if (e.errorMsg.contains('no_match') || e.errorMsg.contains('language')) {
            _fallbackToDefaultLocale = true;
          }
          if (isWordTracking.value) {
            _scheduleListenRestart();
          }
        },
        onStatus: (s) {
          debugPrint('[STT] status: $s');
          if ((s == 'done' || s == 'notListening') && isWordTracking.value) {
            _scheduleListenRestart();
          }
        },
        debugLogging: false,
      );
      speechAvailable.value = available;
      debugPrint('[STT] initialized: $available');
    } catch (e) {
      debugPrint('[STT] init failed: $e');
    }
  }

  void _scheduleListenRestart() {
    _restartListenTimer?.cancel();
    if (!isWordTracking.value) return;
    _restartListenTimer = Timer(const Duration(milliseconds: 250), () {
      if (isWordTracking.value && !_speech.isListening) {
        _listenContinuous();
      }
    });
  }

  void randomizeDeed() {
    final pool = GoodDeedModel.pool;
    final nextIdx = (DateTime.now().millisecond) % pool.length;
    activeDeed.value = pool[nextIdx];
    repetitionCount.value = 0;
    isTranslated.value = false;
    resetWordTracking();
  }

  void setDeed(GoodDeedModel deed) {
    activeDeed.value = deed;
    repetitionCount.value = 0;
    isTranslated.value = false;
    resetWordTracking();
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
    _restartListenTimer?.cancel();
    _audioRecorder.dispose();
    _speech.stop();
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

  // ── Word-by-word tracking helpers ────────────────────────────────────────

  /// Split text into individual words, stripping punctuation & symbols.
  List<String> _splitWords(String text) {
    if (text.isEmpty) return [];
    return text
        .split(RegExp(r'\s+'))
        .map((w) => w.replaceAll(RegExp(r'''[^\u0600-\u06FF\u0980-\u09FFa-zA-Z0-9]'''), '').trim())
        .where((w) => w.isNotEmpty)
        .toList();
  }

  /// Normalize Arabic text (remove tashkeel, harmonize alef, yaa, taa marbuta).
  String _normalizeArabic(String w) {
    return w
        .replaceAll(RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]'), '')
        .replaceAll(RegExp(r'[ٱأإآ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'[^\u0600-\u06FF]'), '')
        .trim();
  }

  /// Normalize Bangla text.
  String _normalizeBangla(String w) {
    return w
        .replaceAll(RegExp(r'[\s\u200c\u200d\u09CD\.\,\?\!\-\—]'), '')
        .replaceAll(RegExp(r'[^\u0980-\u09FF]'), '')
        .trim();
  }

  /// Normalize Latin / English text.
  String _normalizeLatin(String w) {
    return w
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
  }

  /// Check if [spoken] matches [expected] word across Arabic, Bangla, or Latin.
  bool _wordMatches(String expected, String spoken) {
    if (expected.isEmpty || spoken.isEmpty) return false;

    // Check Arabic
    final eAr = _normalizeArabic(expected);
    final sAr = _normalizeArabic(spoken);
    if (eAr.isNotEmpty && sAr.isNotEmpty) {
      if (sAr == eAr || sAr.contains(eAr) || eAr.contains(sAr)) return true;
      if (eAr.length >= 2 && sAr.length >= 2 && eAr.substring(0, 2) == sAr.substring(0, 2)) return true;
    }

    // Check Bangla
    final eBn = _normalizeBangla(expected);
    final sBn = _normalizeBangla(spoken);
    if (eBn.isNotEmpty && sBn.isNotEmpty) {
      if (sBn == eBn || sBn.contains(eBn) || eBn.contains(sBn)) return true;
      if (eBn.length >= 3 && sBn.length >= 3 && eBn.substring(0, 3) == sBn.substring(0, 3)) return true;
    }

    // Check Latin / English
    final eLa = _normalizeLatin(expected);
    final sLa = _normalizeLatin(spoken);
    if (eLa.isNotEmpty && sLa.isNotEmpty) {
      if (sLa == eLa || sLa.contains(eLa) || eLa.contains(sLa)) return true;
      if (eLa.length >= 3 && sLa.length >= 3 && eLa.substring(0, 3) == sLa.substring(0, 3)) return true;
    }

    return false;
  }

  bool _phraseContainsWord(String fullPhrase, String word) {
    final wLa = _normalizeLatin(word);
    final wBn = _normalizeBangla(word);
    final wAr = _normalizeArabic(word);
    if (wLa.length >= 3 && fullPhrase.contains(wLa)) return true;
    if (wBn.length >= 3 && fullPhrase.contains(wBn)) return true;
    if (wAr.length >= 2 && fullPhrase.contains(wAr)) return true;
    return false;
  }

  /// Current word list for selected voice mode.
  List<String> get currentWords {
    switch (activeVoiceMode.value) {
      case VoiceTrackMode.arabic:
        return arabicWords;
      case VoiceTrackMode.banglaPronun:
        return banglaPronunWords.isNotEmpty ? banglaPronunWords : translitWords;
      case VoiceTrackMode.banglaMeaning:
        return banglaMeaningWords;
      case VoiceTrackMode.englishMeaning:
        return englishMeaningWords;
    }
  }

  /// Arabic word list for current deed.
  List<String> get arabicWords => _splitWords(activeDeed.value.arabic);
  /// Transliteration word list.
  List<String> get translitWords => _splitWords(activeDeed.value.transliteration);
  /// Bangla pronunciation word list.
  List<String> get banglaPronunWords => _splitWords(activeDeed.value.banglaPronunciation);
  /// Bangla meaning / ortho word list.
  List<String> get banglaMeaningWords => _splitWords(activeDeed.value.translationBn);
  /// English meaning word list.
  List<String> get englishMeaningWords => _splitWords(activeDeed.value.translationEn);

  void resetWordTracking() {
    liveRecognizedText.value = '';
    currentWordMatches.assignAll(List.filled(currentWords.length, false));
  }

  void setVoiceMode(VoiceTrackMode mode) {
    if (activeVoiceMode.value == mode) return;
    activeVoiceMode.value = mode;
    _fallbackToDefaultLocale = false;
    resetWordTracking();
    if (isWordTracking.value) {
      _speech.stop().then((_) => _scheduleListenRestart());
    }
  }

  Future<void> toggleWordTracking() async {
    if (isWordTracking.value) {
      await stopWordTracking();
    } else {
      await startWordTracking();
    }
  }

  String? _resolveLocale(List<stt.LocaleName> locales) {
    if (_fallbackToDefaultLocale) return null; // Use device default recognizer

    String prefix;
    switch (activeVoiceMode.value) {
      case VoiceTrackMode.arabic:
        prefix = 'ar';
        break;
      case VoiceTrackMode.banglaPronun:
      case VoiceTrackMode.banglaMeaning:
        prefix = 'bn';
        break;
      case VoiceTrackMode.englishMeaning:
        prefix = 'en';
        break;
    }
    for (final l in locales) {
      if (l.localeId.toLowerCase().startsWith(prefix)) {
        return l.localeId;
      }
    }
    return null; // Fallback to system default
  }

  Future<void> startWordTracking() async {
    if (!speechAvailable.value) {
      await _initSpeech();
      if (!speechAvailable.value) {
        trackingStatusMessage.value = 'স্পিচ সার্ভিস সক্রিয় নয়';
        return;
      }
    }

    resetWordTracking();
    isWordTracking.value = true;
    _fallbackToDefaultLocale = false;
    trackingStatusMessage.value = 'শুনছি... পাঠ শুরু করুন';
    HapticFeedback.mediumImpact();

    await _listenContinuous();
  }

  Future<void> _listenContinuous() async {
    if (!isWordTracking.value || _speech.isListening) return;

    try {
      final locales = await _speech.locales();
      final localeId = _resolveLocale(locales);

      await _speech.listen(
        onResult: (result) {
          final spoken = result.recognizedWords;
          liveRecognizedText.value = spoken;
          _updateWordMatches(spoken);
        },
        onSoundLevelChange: (level) {
          soundLevel.value = level;
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
          listenFor: const Duration(seconds: 40),
          pauseFor: const Duration(seconds: 5),
          localeId: localeId,
        ),
      );
    } catch (e) {
      debugPrint('[STT] listen error: $e');
      _fallbackToDefaultLocale = true;
      _scheduleListenRestart();
    }
  }

  Future<void> stopWordTracking() async {
    isWordTracking.value = false;
    _restartListenTimer?.cancel();
    await _speech.stop();
    trackingStatusMessage.value = '';
    HapticFeedback.mediumImpact();
  }

  void _updateWordMatches(String spokenText) {
    if (spokenText.trim().isEmpty) return;
    final spokenWords = spokenText.split(RegExp(r'\s+'));
    final fullPhrase = '${_normalizeLatin(spokenText)} ${_normalizeBangla(spokenText)} ${_normalizeArabic(spokenText)}';
    final targetWords = currentWords;
    if (targetWords.isEmpty) return;

    final updated = List<bool>.from(currentWordMatches);
    if (updated.length != targetWords.length) {
      updated.length = targetWords.length;
      for (int i = 0; i < updated.length; i++) {
        updated[i] = false;
      }
    }

    // Secondary candidates for cross-matching
    List<String> secondary = [];
    if (activeVoiceMode.value == VoiceTrackMode.arabic) {
      secondary = translitWords.isNotEmpty ? translitWords : banglaPronunWords;
    } else if (activeVoiceMode.value == VoiceTrackMode.banglaPronun) {
      secondary = translitWords;
    }

    for (int i = 0; i < targetWords.length; i++) {
      if (updated[i]) continue;
      final expected = targetWords[i];
      final sec = i < secondary.length ? secondary[i] : '';

      final bool matched = spokenWords.any((sw) => _wordMatches(expected, sw)) ||
          (sec.isNotEmpty && spokenWords.any((sw) => _wordMatches(sec, sw))) ||
          _phraseContainsWord(fullPhrase, expected) ||
          (sec.isNotEmpty && _phraseContainsWord(fullPhrase, sec));

      if (matched) {
        updated[i] = true;
        HapticFeedback.selectionClick();
      }
    }

    currentWordMatches.assignAll(updated);

    final matchedCount = updated.where((m) => m).length;
    final totalCount = updated.length;

    final isCompleted = totalCount > 0 && (
      (totalCount <= 3 && matchedCount == totalCount) ||
      (totalCount > 3 && matchedCount >= (totalCount * 0.75).ceil())
    );

    if (isCompleted) {
      HapticFeedback.heavyImpact();
      incrementRepetition();
      trackingStatusMessage.value = '✓ মাশাআল্লাহ! পাঠ সফল হয়েছে';
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (repetitionCount.value < activeDeed.value.targetRepetitions) {
          resetWordTracking();
          trackingStatusMessage.value = 'পরবর্তী পুনরাবৃত্তি পাঠ করুন...';
        } else {
          stopWordTracking();
          trackingStatusMessage.value = 'লক্ষ্য সম্পন্ন হয়েছে!';
        }
      });
    }
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
