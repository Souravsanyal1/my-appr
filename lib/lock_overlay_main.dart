import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

// ---------------------------------------------------------------------------
// Entrypoint — run by the dedicated FlutterEngine inside OverlayController.
// This is a separate isolate: GetX, Firebase, StorageService, etc. are NOT
// available here.  All state is local; communication happens via MethodChannel.
// ---------------------------------------------------------------------------

@pragma('vm:entry-point')
void runLockOverlay() {
  debugPrint('[LockOverlay] runLockOverlay executing');
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LockOverlayApp());
}

@pragma('vm:entry-point')
void lockOverlayMain() {
  runLockOverlay();
}

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

class _LockRequest {
  final String package_;
  final String label;
  final int minScore;
  final int durationMinutes;

  const _LockRequest({
    required this.package_,
    required this.label,
    required this.minScore,
    required this.durationMinutes,
  });

  factory _LockRequest.fromMap(Map m) => _LockRequest(
        package_: m['package'] as String? ?? '',
        label: m['label'] as String? ?? 'App',
        minScore: m['minScore'] as int? ?? 80,
        durationMinutes: m['durationMinutes'] as int? ?? 30,
      );
}

// ---------------------------------------------------------------------------
// App root (single-engine, no GetX/GetMaterialApp)
// ---------------------------------------------------------------------------

class LockOverlayApp extends StatefulWidget {
  const LockOverlayApp({super.key});

  @override
  State<LockOverlayApp> createState() => _LockOverlayAppState();
}

class _LockOverlayAppState extends State<LockOverlayApp> {
  static const _channel = MethodChannel('deenflow/lock_overlay');

  _LockRequest? _request;
  int _session = 0;

  @override
  void initState() {
    super.initState();
    debugPrint('[LockOverlay] LockOverlayApp.initState() called');
    _channel.setMethodCallHandler(_onNativeCall);
    // Signal engine ready to native immediately
    _channel.invokeMethod<void>('engineReady');
    // Remove the native cover as soon as Flutter draws the very first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('[LockOverlay] Initial postFrameCallback -> shown');
      _channel.invokeMethod<void>('shown');
    });
  }

  Future<dynamic> _onNativeCall(MethodCall call) async {
    debugPrint('[LockOverlay] Native call: ${call.method}');
    if (call.method == 'onShow') {
      final req = _LockRequest.fromMap(call.arguments as Map);
      debugPrint('[LockOverlay] onShow for package: ${req.package_}, minScore: ${req.minScore}');
      setState(() {
        _request = req;
        _session++;
      });
      // Ensure native cover stays removed after re-shows
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('[LockOverlay] onShow postFrameCallback -> shown');
        _channel.invokeMethod<void>('shown');
      });
    }
    return null;
  }

  Future<void> _onPass(int score) async {
    await _channel.invokeMethod<void>('unlockAndDismiss', {'score': score});
  }

  Future<void> _onCancel() async {
    await _channel.invokeMethod<void>('cancelAndGoHome');
  }

  @override
  Widget build(BuildContext context) {
    final req = _request;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            debugPrint('[LockOverlay] Back gesture/key intercepted in LockOverlayApp -> _onCancel()');
            _onCancel();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: req == null
                ? const SizedBox.shrink()
                : KeyedSubtree(
                    key: ValueKey(_session),
                    child: _DeedFlow(
                      request: req,
                      onPassed: _onPass,
                      onCancel: _onCancel,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: Colors.black,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF1FE08F),
        secondary: Color(0xFFD4A853),
        surface: Color(0xFF111111),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1FE08F),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white70,
          side: const BorderSide(color: Colors.white24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Multi-step deed flow
// Steps: intro -> learn -> record -> analyze -> result
// ---------------------------------------------------------------------------

enum _Step { intro, learn, record, analyze, result }

class _DeedFlow extends StatefulWidget {
  final _LockRequest request;
  final Future<void> Function(int score) onPassed;
  final Future<void> Function() onCancel;

  const _DeedFlow({
    required this.request,
    required this.onPassed,
    required this.onCancel,
  });

  @override
  State<_DeedFlow> createState() => _DeedFlowState();
}

class _DeedFlowState extends State<_DeedFlow> {
  _Step _step = _Step.intro;

  // Selected dhikr
  int _selectedVerseIndex = 0;
  static const _verses = [
    _Verse(
      name: 'Astaghfirullah',
      arabic: 'أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ',
      transliteration: 'Astaghfirullaha wa atubu ilayh',
      banglaPronunciation: 'আস্তাগফিরুল্লাহা ওয়া আতূবু ইলাইহ',
      translation: 'I seek forgiveness from Allah and repent to Him',
      banglaMeaning: 'আমি আল্লাহর কাছে ক্ষমা চাই এবং তাঁর কাছে তওবা করি',
      minSeconds: 3,
    ),
    _Verse(
      name: 'SubhanAllah',
      arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
      transliteration: 'SubhanAllahi wa bihamdihi',
      banglaPronunciation: 'সুবহানাল্লাহি ওয়া বিহামদিহী',
      translation: 'Glory and praise be to Allah',
      banglaMeaning: 'আল্লাহর পবিত্রতা ঘোষণা করছি তাঁর প্রশংসার সাথে',
      minSeconds: 3,
    ),
    _Verse(
      name: 'Alhamdulillah',
      arabic: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
      transliteration: 'Alhamdulillahi Rabbil Alamin',
      banglaPronunciation: 'আলহামদুলিল্লাহি রাব্বিল আলামীন',
      translation: 'All praise is for Allah, Lord of the worlds',
      banglaMeaning: 'সমস্ত প্রশংসা জগৎসমূহের প্রতিপালক আল্লাহর জন্য',
      minSeconds: 3,
    ),
    _Verse(
      name: 'Allahu Akbar',
      arabic: 'اللَّهُ أَكْبَرُ',
      transliteration: 'Allahu Akbar',
      banglaPronunciation: 'আল্লাহু আকবার',
      translation: 'Allah is the Greatest',
      banglaMeaning: 'আল্লাহ সর্বশ্রেষ্ঠ',
      minSeconds: 2,
    ),
    _Verse(
      name: 'La ilaha illallah',
      arabic: 'لَا إِلَهَ إِلَّا اللَّهُ',
      transliteration: 'La ilaha illallah',
      banglaPronunciation: 'লা ইলাহা ইল্লাল্লাহ',
      translation: 'There is no deity worthy of worship except Allah',
      banglaMeaning: 'আল্লাহ ছাড়া কোনো সত্য উপাস্য নেই',
      minSeconds: 2,
    ),
  ];

  _Verse get _currentVerse => _verses[_selectedVerseIndex];

  // Recording state
  bool _isRecording = false;
  double _recordingSeconds = 0;
  Timer? _recordingTimer;

  // Result state
  _ScoreResult? _result;

  double _lastMatchRatio = 0.0;

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
      _lastMatchRatio = 0.0;
    });
    HapticFeedback.mediumImpact();
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _recordingSeconds += 0.1);
    });
  }

  void _pauseRecording() {
    _recordingTimer?.cancel();
    setState(() {
      _isRecording = false;
    });
  }

  void _stopAndAnalyze([double matchRatio = 0.0]) {
    if (_step == _Step.analyze || _step == _Step.result) return;
    _recordingTimer?.cancel();
    HapticFeedback.mediumImpact();
    setState(() {
      _isRecording = false;
      _lastMatchRatio = matchRatio;
      _step = _Step.analyze;
    });
    _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    await Future.delayed(const Duration(milliseconds: 1800)); // simulate analysis
    if (!mounted) return;
    final score = _computeScore(_recordingSeconds, _currentVerse.minSeconds, _lastMatchRatio);
    setState(() {
      _result = score;
      _step = _Step.result;
    });
  }

  _ScoreResult _computeScore(double durationSec, int minSec, [double matchRatio = 0.0]) {
    // ── Word-tracking is the primary gate ─────────────────────────────────
    // ≥ 70% match → pass (generous to account for STT variance)
    if (matchRatio >= 0.7) {
      final overall = (88 + (matchRatio * 12)).round().clamp(88, 100);
      return _ScoreResult(
        overall: overall,
        wordScore: (matchRatio * 100).round(),
        timingScore: 92,
        isPassing: true,
      );
    }

    // Hard fail: very short + almost nothing matched
    if (matchRatio < 0.4 || durationSec < minSec * 0.5) {
      final score = (matchRatio * 60).round().clamp(10, 55);
      return _ScoreResult(overall: score, wordScore: score, timingScore: 40, isPassing: false);
    }

    // Borderline (0.4–0.69): always fails — score capped just below minScore so
    // the result screen shows "retry" without unlocking the app.
    final wordScore = (matchRatio * 80).round().clamp(30, widget.request.minScore - 1);
    final timingScore = durationSec >= minSec ? 70 : 45;
    final overall = ((wordScore + timingScore) ~/ 2).clamp(30, widget.request.minScore - 1);
    return _ScoreResult(
      overall: overall,
      wordScore: wordScore,
      timingScore: timingScore,
      isPassing: false,
    );
  }

  void _retryRecording() {
    setState(() {
      _result = null;
      _step = _Step.record;
    });
  }

  void _goToLearn() => setState(() => _step = _Step.learn);
  void _goToRecord() => setState(() => _step = _Step.record);

  Future<void> _handlePass() async {
    await widget.onPassed(_result!.overall);
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_step == _Step.learn || _step == _Step.record) {
          setState(() {
            _isRecording = false;
            _recordingTimer?.cancel();
            _step = _Step.intro;
          });
        } else {
          widget.onCancel();
        }
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildStep(context),
      ),
    );
  }

  Widget _buildStep(BuildContext context) {
    switch (_step) {
      case _Step.intro:
        return _IntroStep(
          key: const ValueKey('intro'),
          request: widget.request,
          verses: _verses,
          selectedIndex: _selectedVerseIndex,
          onSelectVerse: (i) => setState(() => _selectedVerseIndex = i),
          onLearn: _goToLearn,
          onProceed: _goToRecord,
          onCancel: widget.onCancel,
        );
      case _Step.learn:
        return _LearnStep(
          key: const ValueKey('learn'),
          verse: _currentVerse,
          onBack: () => setState(() => _step = _Step.intro),
          onReady: _goToRecord,
        );
      case _Step.record:
        return _RecordStep(
          key: const ValueKey('record'),
          verse: _currentVerse,
          isRecording: _isRecording,
          recordingSeconds: _recordingSeconds,
          onStart: _startRecording,
          onPause: _pauseRecording,
          onStop: (ratio) => _stopAndAnalyze(ratio),
          onCancel: widget.onCancel,
        );
      case _Step.analyze:
        return _AnalyzeStep(key: const ValueKey('analyze'));
      case _Step.result:
        return _ResultStep(
          key: const ValueKey('result'),
          result: _result!,
          minScore: widget.request.minScore,
          durationMinutes: widget.request.durationMinutes,
          appLabel: widget.request.label,
          onRetry: _retryRecording,
          onLearn: _goToLearn,
          onUnlock: _handlePass,
          onCancel: widget.onCancel,
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Step 1: Intro — choose dhikr, see instructions
// ---------------------------------------------------------------------------

class _IntroStep extends StatelessWidget {
  final _LockRequest request;
  final List<_Verse> verses;
  final int selectedIndex;
  final ValueChanged<int> onSelectVerse;
  final VoidCallback onLearn;
  final VoidCallback onProceed;
  final Future<void> Function() onCancel;

  const _IntroStep({
    super.key,
    required this.request,
    required this.verses,
    required this.selectedIndex,
    required this.onSelectVerse,
    required this.onLearn,
    required this.onProceed,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final verse = verses[selectedIndex];
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — app name intentionally hidden
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1FE08F).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline, color: Color(0xFF1FE08F), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FocusDeen',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Recite to earn ${request.durationMinutes} min access',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF1FE08F)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Arabic text display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF101612),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1FE08F).withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Text(
                  verse.arabic,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    color: Colors.white,
                    height: 1.8,
                    fontFamily: 'Scheherazade',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  verse.transliteration,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1FE08F), fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 4),
                Text(
                  verse.translation,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Dhikr chips
          const Text('Select Dhikr:', style: TextStyle(fontSize: 14, color: Colors.white70)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: List.generate(verses.length, (i) {
              final selected = i == selectedIndex;
              return GestureDetector(
                onTap: () => onSelectVerse(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF1FE08F).withValues(alpha: 0.2) : const Color(0xFF161616),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? const Color(0xFF1FE08F) : Colors.white24,
                    ),
                  ),
                  child: Text(
                    verses[i].name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      color: selected ? const Color(0xFF1FE08F) : Colors.white70,
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 28),

          // Buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onProceed,
              child: const Text('Start Recitation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onLearn,
              icon: const Icon(Icons.headphones_outlined, size: 18),
              label: const Text('Learn First'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.arrow_back, size: 16, color: Colors.white54),
              label: const Text('Back to Home', style: TextStyle(color: Colors.white54, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2: Learn — show Arabic + transliteration, listen tip
// ---------------------------------------------------------------------------

class _LearnStep extends StatelessWidget {
  final _Verse verse;
  final VoidCallback onBack;
  final VoidCallback onReady;

  const _LearnStep({super.key, required this.verse, required this.onBack, required this.onReady});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
              ),
              const Text('Learning Mode', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0E2418),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF1FE08F).withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.menu_book_rounded, color: Color(0xFF1FE08F), size: 36),
                  const SizedBox(height: 16),
                  Text(
                    verse.arabic,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 30, color: Colors.white, height: 1.8),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    verse.transliteration,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Color(0xFF1FE08F), fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    verse.translation,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Colors.white60, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const _TipCard(
            icon: Icons.tips_and_updates_outlined,
            tip: 'Recite slowly and clearly. Pronounce each letter distinctly. You need at least 80% to unlock the app.',
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onReady,
              child: const Text("I'm Ready — Start Recording", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 3: Record
// ---------------------------------------------------------------------------

class _RecordStep extends StatefulWidget {
  final _Verse verse;
  final bool isRecording;
  final double recordingSeconds;
  final VoidCallback onStart;
  final VoidCallback? onPause;
  final ValueChanged<double> onStop;
  final Future<void> Function() onCancel;

  const _RecordStep({
    super.key,
    required this.verse,
    required this.isRecording,
    required this.recordingSeconds,
    required this.onStart,
    this.onPause,
    required this.onStop,
    required this.onCancel,
  });

  @override
  State<_RecordStep> createState() => _RecordStepState();
}

class _RecordStepState extends State<_RecordStep> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _fallbackToDefaultLocale = false;
  Timer? _restartListenTimer;
  int _consecutiveErrors = 0;
  static const int _maxConsecutiveErrors = 2;

  // 0: Arabic, 1: Bangla Pronunciation, 2: Bangla Meaning, 3: English
  int _activeMode = 0;
  String _liveSpokenText = '';
  List<bool> _matchedWords = [];
  bool _sessionFailed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initMatchedWords();
    _initSpeech();
  }

  void _initMatchedWords() {
    final words = _currentWords;
    _matchedWords = List.filled(words.length, false);
    _sessionFailed = false;
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          debugPrint('[LockOverlay STT] status: $status');
          if (widget.isRecording && (status == 'done' || status == 'notListening')) {
            _scheduleListenRestart(fromError: false);
          }
        },
        onError: (error) {
          debugPrint('[LockOverlay STT] error: ${error.errorMsg}');
          if (widget.isRecording) {
            _consecutiveErrors++;
            if (_consecutiveErrors >= _maxConsecutiveErrors) {
              _fallbackToDefaultLocale = true;
            }
            _scheduleListenRestart(fromError: true);
          }
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('[LockOverlay STT] init failed: $e');
    }
  }

  void _scheduleListenRestart({bool fromError = false}) {
    _restartListenTimer?.cancel();
    // Exponential backoff: normal pause 600ms, 1st error 1500ms, 2nd+ error 3000ms
    final int delayMs = fromError
        ? (_consecutiveErrors >= _maxConsecutiveErrors ? 3000 : 1500)
        : 600;
    _restartListenTimer = Timer(Duration(milliseconds: delayMs), () {
      if (mounted && widget.isRecording && !_speech.isListening) {
        _listenContinuous();
      }
    });
  }

  Future<void> _listenContinuous() async {
    if (!widget.isRecording || _speech.isListening) return;

    try {
      final locales = await _speech.locales();
      final localeId = _resolveLocale(locales);
      debugPrint('[LockOverlay STT] Starting listen locale: ${localeId ?? "system-default"}');

      await _speech.listen(
        onResult: (result) {
          if (!mounted || result.recognizedWords.isEmpty) return;
          _consecutiveErrors = 0; // reset on any recognized speech
          final spoken = result.recognizedWords;
          debugPrint('[LockOverlay STT] Recognized: $spoken (final=${result.finalResult})');
          setState(() {
            _liveSpokenText = spoken;
          });
          _updateWordMatches(spoken);
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          localeId: localeId,
        ),
      );
    } catch (e) {
      debugPrint('[LockOverlay STT] listenContinuous error: $e');
      _consecutiveErrors++;
      _fallbackToDefaultLocale = true;
      _scheduleListenRestart(fromError: true);
    }
  }

  String? _resolveLocale(List<stt.LocaleName> locales) {
    if (_fallbackToDefaultLocale) return null;
    String prefix;
    switch (_activeMode) {
      case 0:
        prefix = 'ar';
        break;
      case 1:
      case 2:
        prefix = 'bn';
        break;
      case 3:
      default:
        prefix = 'en';
        break;
    }
    for (final l in locales) {
      if (l.localeId.toLowerCase().startsWith(prefix)) {
        return l.localeId;
      }
    }
    return null;
  }

  @override
  void didUpdateWidget(covariant _RecordStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isRecording && widget.isRecording) {
      _sessionFailed = false;
      _startSTT();
    } else if (oldWidget.isRecording && !widget.isRecording) {
      _stopSTT();
    }
  }

  Future<void> _startSTT() async {
    setState(() {
      _liveSpokenText = '';
      _initMatchedWords();
      _sessionFailed = false;
    });
    if (!_speechAvailable) {
      await _initSpeech();
    }
    _fallbackToDefaultLocale = false;
    _consecutiveErrors = 0;
    await _listenContinuous();
  }

  Future<void> _stopSTT() async {
    _restartListenTimer?.cancel();
    try {
      await _speech.stop();
    } catch (e) {
      debugPrint('[LockOverlay STT] stop error: $e');
    }
  }

  @override
  void dispose() {
    _restartListenTimer?.cancel();
    _speech.stop();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Word splitting & Matching helpers ──────────────────────────────────────

  List<String> _splitWords(String text) {
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
  }

  String _normalizeArabic(String w) {
    return w
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '')
        .replaceAll(RegExp(r'[ٱأإآ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'[^\u0600-\u06FF]'), '')
        .trim();
  }

  String _normalizeBangla(String w) {
    return w
        .replaceAll(RegExp(r'[\s\u200c\u200d\u09CD\.\,\?\!\-\—]'), '')
        .replaceAll("'", '')
        .replaceAll('"', '')
        .replaceAll(RegExp(r'[^\u0980-\u09FF]'), '')
        .trim();
  }

  String _normalizeLatin(String w) {
    return w
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
  }

  int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.generate(t.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        final cost = (s.codeUnitAt(i) == t.codeUnitAt(j)) ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost].reduce((a, b) => a < b ? a : b);
      }
      for (int j = 0; j <= t.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v0[t.length];
  }

  bool _wordMatches(String expected, String spoken) {
    if (expected.isEmpty || spoken.isEmpty) return false;

    // Check Arabic
    final eAr = _normalizeArabic(expected);
    final sAr = _normalizeArabic(spoken);
    if (eAr.isNotEmpty && sAr.isNotEmpty) {
      if (sAr == eAr) return true;
      if (sAr == 'و$eAr' || eAr == 'و$sAr' || sAr == 'ف$eAr' || eAr == 'ف$sAr') return true;
      if (eAr.length >= 4 && sAr.length >= 4) {
        if (_levenshtein(eAr, sAr) <= 1) return true;
      }
    }

    // Check Bangla
    final eBn = _normalizeBangla(expected);
    final sBn = _normalizeBangla(spoken);
    if (eBn.isNotEmpty && sBn.isNotEmpty) {
      if (sBn == eBn) return true;
      if (eBn.length >= 4 && sBn.length >= 4) {
        if (_levenshtein(eBn, sBn) <= 1) return true;
        if (sBn.startsWith(eBn) || eBn.startsWith(sBn)) {
          final minLen = eBn.length < sBn.length ? eBn.length : sBn.length;
          final maxLen = eBn.length > sBn.length ? eBn.length : sBn.length;
          if (minLen >= 5 && (maxLen - minLen) <= 2) return true;
        }
      }
    }

    // Check Latin / English
    final eLa = _normalizeLatin(expected);
    final sLa = _normalizeLatin(spoken);
    if (eLa.isNotEmpty && sLa.isNotEmpty) {
      if (sLa == eLa) return true;
      if (eLa.length >= 4 && sLa.length >= 4) {
        if (_levenshtein(eLa, sLa) <= 1) return true;
        if (sLa.startsWith(eLa) || eLa.startsWith(sLa)) {
          final minLen = eLa.length < sLa.length ? eLa.length : sLa.length;
          final maxLen = eLa.length > sLa.length ? eLa.length : sLa.length;
          if (minLen >= 5 && (maxLen - minLen) <= 2) return true;
        }
      }
    }

    return false;
  }

  bool _matchesTargetSlot(int slotIndex, List<String> targetWords, String spokenWord) {
    if (slotIndex < 0 || slotIndex >= targetWords.length) return false;
    final expected = targetWords[slotIndex];

    // 1. Direct match with target word
    if (_wordMatches(expected, spokenWord)) return true;

    // 2. Cross-mode candidates for this exact slot
    final arWords = _splitWords(widget.verse.arabic);
    final bnWords = _splitWords(widget.verse.banglaPronunciation);
    final trWords = _splitWords(widget.verse.transliteration);

    final crossCandidates = <String>[];
    if (slotIndex < arWords.length) crossCandidates.add(arWords[slotIndex]);
    if (slotIndex < bnWords.length) crossCandidates.add(bnWords[slotIndex]);
    if (slotIndex < trWords.length) crossCandidates.add(trWords[slotIndex]);

    for (final cand in crossCandidates) {
      if (cand != expected && _wordMatches(cand, spokenWord)) {
        return true;
      }
    }

    // 3. Known phonetic mappings for compound religious phrases
    final sBn = _normalizeBangla(spokenWord);
    final sLa = _normalizeLatin(spokenWord);
    final eAr = _normalizeArabic(expected);

    if (eAr == 'الحمد' && (sBn.startsWith('আলহামদু') || sLa.startsWith('alhamdu'))) return true;
    if (eAr == 'لله' && (sBn.contains('লিল্লাহ') || sBn.contains('আল্লাহ') || sLa.contains('lillah') || sLa.contains('allah'))) return true;
    if (eAr == 'سبحان' && (sBn.startsWith('সুবহান') || sLa.startsWith('subhan'))) return true;
    if (eAr == 'الله' && (sBn.contains('আল্লাহ') || sLa.contains('allah'))) return true;
    if (eAr == 'وبحمده' && (sBn.contains('হামদিহ') || sLa.contains('hamdih'))) return true;
    if (eAr == 'استغفر' && (sBn.startsWith('আস্তাগফির') || sLa.startsWith('astaghfir'))) return true;
    if (eAr == 'واتوب' && (sBn.contains('তূবু') || sBn.contains('তওবা') || sLa.contains('atubu'))) return true;
    if (eAr == 'اليه' && (sBn.contains('ইলাইহ') || sLa.contains('ilayh'))) return true;
    if (eAr == 'رب' && (sBn.contains('রব') || sLa.contains('rabb'))) return true;
    if (eAr == 'العالمين' && (sBn.contains('আলামীন') || sBn.contains('আলামিন') || sLa.contains('alamin') || sLa.contains('alameen'))) return true;
    if (eAr == 'اكبر' && (sBn.contains('আকবার') || sLa.contains('akbar'))) return true;

    return false;
  }

  List<String> get _currentWords {
    switch (_activeMode) {
      case 0:
        return _splitWords(widget.verse.arabic);
      case 1:
        final bn = widget.verse.banglaPronunciation;
        return _splitWords(bn.isNotEmpty ? bn : widget.verse.transliteration);
      case 2:
        return _splitWords(widget.verse.banglaMeaning);
      case 3:
      default:
        return _splitWords(widget.verse.translation);
    }
  }

  void _updateWordMatches(String spokenText) {
    if (spokenText.trim().isEmpty) return;
    final spokenWords = spokenText.split(RegExp(r'\s+'));
    final targetWords = _currentWords;
    if (targetWords.isEmpty) return;

    final updated = List<bool>.from(_matchedWords);
    if (updated.length != targetWords.length) {
      updated.length = targetWords.length;
      for (int i = 0; i < updated.length; i++) {
        updated[i] = false;
      }
    }

    bool newlyMatched = false;

    // Strict sequential matching:
    // Find first unmatched target word index
    int targetIdx = 0;
    while (targetIdx < targetWords.length && updated[targetIdx]) {
      targetIdx++;
    }

    for (final spoken in spokenWords) {
      if (targetIdx >= targetWords.length) break;

      // Check current expected word
      if (_matchesTargetSlot(targetIdx, targetWords, spoken)) {
        updated[targetIdx] = true;
        newlyMatched = true;
        targetIdx++;

        // Check if this spoken word also covers compound next word (e.g. "আলহামদুলিল্লাহি" -> "الحمد" + "لله")
        if (targetIdx < targetWords.length && _matchesTargetSlot(targetIdx, targetWords, spoken)) {
          updated[targetIdx] = true;
          targetIdx++;
        }
      } else if (targetIdx + 1 < targetWords.length && _matchesTargetSlot(targetIdx + 1, targetWords, spoken)) {
        // Allowed skip of at most 1 word if a tiny conjunction was skipped
        updated[targetIdx + 1] = true;
        newlyMatched = true;
        targetIdx += 2;
      }
    }

    if (newlyMatched) {
      HapticFeedback.selectionClick();
      setState(() {
        _matchedWords = updated;
        _sessionFailed = false;
      });

      final matchedCount = updated.where((m) => m).length;
      final ratio = targetWords.isNotEmpty ? matchedCount / targetWords.length : 0.0;
      if (ratio >= 0.75 && widget.isRecording) {
        HapticFeedback.mediumImpact();
        Future.delayed(const Duration(milliseconds: 650), () {
          if (mounted && widget.isRecording) {
            widget.onStop(ratio);
          }
        });
      }
    }
  }

  void _switchMode(int mode) {
    if (_activeMode == mode) return;
    setState(() {
      _activeMode = mode;
      _fallbackToDefaultLocale = false;
      _liveSpokenText = '';
      _initMatchedWords();
      _sessionFailed = false;
    });
    if (widget.isRecording) {
      _speech.stop().then((_) => _scheduleListenRestart());
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = _currentWords;
    final matchedCount = _matchedWords.where((m) => m).length;
    final ratio = words.isNotEmpty ? (matchedCount / words.length) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1FE08F).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic, color: Color(0xFF1FE08F), size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                widget.isRecording ? 'ভয়েস ট্র্যাকিং চলছে' : 'ভয়েস ট্র্যাকিং প্রস্তুত',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Spacer(),
              TextButton(
                onPressed: widget.onCancel,
                child: const Text('বাতিল', style: TextStyle(color: Colors.white38, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Mode Selector Bar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF111A15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                _buildModeTab(0, '🇸🇦 আরবি'),
                _buildModeTab(1, '🇧🇩 উচ্চারণ'),
                _buildModeTab(2, '📖 অর্থ'),
                _buildModeTab(3, '🇬🇧 English'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Status / Error Banner when failed
          if (_sessionFailed)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B1212),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEF4444)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'সঠিকভাবে পড়া হয়নি (${(ratio * 100).toInt()}%) — লাল চিহ্নিত শব্দগুলো পুনরায় পড়ুন',
                      style: const TextStyle(fontSize: 12, color: Color(0xFFFCA5A5), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          // Word Chips Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0E2418),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _sessionFailed
                    ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                    : const Color(0xFF1FE08F).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                // Word chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  textDirection: _activeMode == 0 ? TextDirection.rtl : TextDirection.ltr,
                  children: List.generate(words.length, (idx) {
                    final word = words[idx];
                    final isMatched = idx < _matchedWords.length && _matchedWords[idx];
                    final isFailed = _sessionFailed && !isMatched;

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (idx < _matchedWords.length) {
                            _matchedWords[idx] = !_matchedWords[idx];
                            _sessionFailed = false;
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: EdgeInsets.symmetric(
                          horizontal: _activeMode == 0 ? 14 : 10,
                          vertical: _activeMode == 0 ? 8 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: isMatched
                              ? const Color(0xFF1FE08F)
                              : (isFailed ? const Color(0xFF3B1212) : const Color(0xFF163825)),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isMatched
                                ? const Color(0xFF1FE08F)
                                : (isFailed ? const Color(0xFFEF4444) : const Color(0xFF1FE08F).withValues(alpha: 0.3)),
                            width: (isMatched || isFailed) ? 2 : 1,
                          ),
                          boxShadow: isMatched
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF1FE08F).withValues(alpha: 0.45),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : (isFailed
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFEF4444).withValues(alpha: 0.45),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isMatched) ...[
                              const Icon(Icons.check_circle_rounded, size: 16, color: Colors.black),
                              const SizedBox(width: 4),
                            ] else if (isFailed) ...[
                              const Icon(Icons.close_rounded, size: 16, color: Color(0xFFEF4444)),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              word,
                              style: TextStyle(
                                fontSize: _activeMode == 0 ? 22 : 14,
                                fontWeight: (isMatched || isFailed) ? FontWeight.bold : FontWeight.w500,
                                color: isMatched
                                    ? Colors.black
                                    : (isFailed ? const Color(0xFFFCA5A5) : Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 14),

                // Transliteration / Meaning Sub-hint
                Text(
                  _activeMode == 0
                      ? (widget.verse.banglaPronunciation.isNotEmpty
                          ? widget.verse.banglaPronunciation
                          : widget.verse.transliteration)
                      : (_activeMode == 1
                          ? widget.verse.banglaMeaning
                          : widget.verse.transliteration),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: _sessionFailed ? const Color(0xFFFCA5A5) : const Color(0xFF1FE08F),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Live Recognized Subtitle
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.hearing_rounded,
                  size: 16,
                  color: widget.isRecording ? const Color(0xFF1FE08F) : Colors.white38,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _liveSpokenText.isNotEmpty
                        ? 'শুনছি: "$_liveSpokenText"'
                        : (widget.isRecording
                            ? 'কথার শব্দ বলুন (উচ্চারণ বা অর্থ যা বলবেন মিলবে)...'
                            : (_sessionFailed
                                ? 'আবার চেষ্টা করতে নিচের মাইকে চাপ দিন'
                                : 'মাইকে চাপ দিয়ে পাঠ শুরু করুন')),
                    style: TextStyle(
                      fontSize: 12,
                      color: _liveSpokenText.isNotEmpty
                          ? const Color(0xFF1FE08F)
                          : (_sessionFailed ? const Color(0xFFFCA5A5) : Colors.white54),
                    ),
                    overflow: TextDirection.ltr == TextDirection.ltr ? TextOverflow.ellipsis : null,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Progress indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'শনাক্ত: $matchedCount / ${words.length} শব্দ',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
              Text(
                '${(ratio * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _sessionFailed ? const Color(0xFFEF4444) : const Color(0xFF1FE08F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 5,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(
                _sessionFailed ? const Color(0xFFEF4444) : const Color(0xFF1FE08F),
              ),
            ),
          ),

          const Spacer(),

          // Timer
          Text(
            widget.isRecording
                ? '${widget.recordingSeconds.toStringAsFixed(1)}s'
                : (_sessionFailed ? 'অসম্পূর্ণ' : 'পাঠের সময়'),
            style: TextStyle(
              fontSize: widget.isRecording ? 36 : 16,
              fontWeight: FontWeight.bold,
              color: widget.isRecording
                  ? const Color(0xFF1FE08F)
                  : (_sessionFailed ? const Color(0xFFEF4444) : Colors.white38),
            ),
          ),

          const SizedBox(height: 16),

          // Mic button
          GestureDetector(
            onTap: () {
              if (widget.isRecording) {
                final curRatio = words.isNotEmpty ? (_matchedWords.where((m) => m).length / words.length) : 0.0;
                if (curRatio >= 0.75) {
                  _sessionFailed = false;
                  widget.onStop(curRatio);
                } else {
                  HapticFeedback.heavyImpact();
                  _stopSTT();
                  setState(() {
                    _sessionFailed = true;
                  });
                  widget.onPause?.call();
                }
              } else {
                setState(() {
                  _sessionFailed = false;
                });
                widget.onStart();
              }
            },
            child: ScaleTransition(
              scale: widget.isRecording ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isRecording ? const Color(0xFFD62828) : const Color(0xFF1FE08F),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.isRecording ? const Color(0xFFD62828) : const Color(0xFF1FE08F))
                          .withValues(alpha: 0.45),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  widget.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.black,
                  size: 38,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),
          Text(
            widget.isRecording
                ? 'থামাতে আলতো চাপুন'
                : (_sessionFailed ? 'পুনরায় পড়তে মাইকে ট্যাপ করুন' : 'শুরু করতে মাইকে ট্যাপ করুন'),
            style: TextStyle(
              fontSize: 12,
              color: _sessionFailed ? const Color(0xFFFCA5A5) : Colors.white54,
            ),
          ),
          if (_sessionFailed) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                final curRatio = words.isNotEmpty ? (_matchedWords.where((m) => m).length / words.length) : 0.0;
                widget.onStop(curRatio);
              },
              child: const Text(
                'এভাবেই জমা দিন (ব্যর্থ হিসেবে গণ্য হবে)',
                style: TextStyle(color: Colors.white38, fontSize: 11, decoration: TextDecoration.underline),
              ),
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildModeTab(int mode, String title) {
    final isSelected = _activeMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1FE08F) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.black : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 4: Analyze
// ---------------------------------------------------------------------------

class _AnalyzeStep extends StatefulWidget {
  const _AnalyzeStep({super.key});

  @override
  State<_AnalyzeStep> createState() => _AnalyzeStepState();
}

class _AnalyzeStepState extends State<_AnalyzeStep> with SingleTickerProviderStateMixin {
  late AnimationController _rotCtrl;
  int _progress = 0;
  int _stepIdx = 0;
  Timer? _timer;

  static const _steps = [
    'Processing audio input...',
    'Comparing pronunciation...',
    'Analyzing phonemes & tajweed...',
    'Calculating accuracy score...',
    'Analysis complete ✓',
  ];

  @override
  void initState() {
    super.initState();
    _rotCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _timer = Timer.periodic(const Duration(milliseconds: 28), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _progress++;
        if (_progress < 25) { _stepIdx = 0; }
        else if (_progress < 50) { _stepIdx = 1; }
        else if (_progress < 75) { _stepIdx = 2; }
        else if (_progress < 95) { _stepIdx = 3; }
        else { _stepIdx = 4; }
        if (_progress >= 100) { t.cancel(); }
      });
    });
  }

  @override
  void dispose() {
    _rotCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotationTransition(
              turns: _rotCtrl,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(colors: [
                    const Color(0xFF1FE08F).withValues(alpha: 0.1),
                    const Color(0xFF1FE08F),
                  ]),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFF1FE08F),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              _steps[_stepIdx],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.white70, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _progress / 100.0,
                backgroundColor: Colors.white12,
                color: const Color(0xFF1FE08F),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 5: Result
// ---------------------------------------------------------------------------

class _ResultStep extends StatelessWidget {
  final _ScoreResult result;
  final int minScore;
  final int durationMinutes;
  final String appLabel;
  final VoidCallback onRetry;
  final VoidCallback onLearn;
  final Future<void> Function() onUnlock;
  final Future<void> Function() onCancel;

  const _ResultStep({
    super.key,
    required this.result,
    required this.minScore,
    required this.durationMinutes,
    required this.appLabel,
    required this.onRetry,
    required this.onLearn,
    required this.onUnlock,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isPassing = result.isPassing;
    final color = isPassing ? const Color(0xFF1FE08F) : const Color(0xFFD4A853);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          // Top bar
          Row(
            children: [
              Icon(isPassing ? Icons.check_circle : Icons.refresh_rounded, color: color),
              const SizedBox(width: 8),
              Text(
                isPassing ? 'Great effort!' : 'Almost there!',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Spacer(),
              TextButton(
                onPressed: onCancel,
                child: const Text('Cancel', style: TextStyle(color: Colors.white38, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Score ring
          _ScoreRing(score: result.overall, color: color),
          const SizedBox(height: 8),
          Text(
            isPassing
                ? 'You met the $minScore% threshold'
                : 'Need $minScore% to unlock',
            style: const TextStyle(fontSize: 13, color: Colors.white54),
          ),

          const SizedBox(height: 20),

          // Breakdown card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0E2418),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                _Row('Word Recognition', '${result.wordScore}%'),
                const Divider(color: Colors.white12, height: 20),
                _Row('Timing & Rhythm', '${result.timingScore}%'),
                const Divider(color: Colors.white12, height: 20),
                _Row('Overall Score', '${result.overall}%', bold: true),
              ],
            ),
          ),

          const Spacer(),

          // Action buttons
          if (isPassing) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onUnlock,
                child: Text(
                  'Unlock $appLabel for $durationMinutes min',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onLearn,
                    child: const Text('Practice First'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onRetry,
                    child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _Row(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.white60)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: const Color(0xFF1FE08F),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Score ring widget
// ---------------------------------------------------------------------------

class _ScoreRing extends StatelessWidget {
  final int score;
  final Color color;

  const _ScoreRing({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: score / 100.0,
              strokeWidth: 9,
              backgroundColor: Colors.white12,
              color: color,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score%',
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const Text(
                'Pronunciation',
                style: TextStyle(fontSize: 11, color: Colors.white54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tip card widget
// ---------------------------------------------------------------------------

class _TipCard extends StatelessWidget {
  final IconData icon;
  final String tip;

  const _TipCard({required this.icon, required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E2418),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1FE08F).withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF1FE08F), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(fontSize: 13, color: Colors.white60, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data models (local to this isolate)
// ---------------------------------------------------------------------------

class _Verse {
  final String name;
  final String arabic;
  final String transliteration;
  final String translation;
  final String banglaPronunciation;
  final String banglaMeaning;
  final int minSeconds;

  const _Verse({
    required this.name,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    this.banglaPronunciation = '',
    this.banglaMeaning = '',
    required this.minSeconds,
  });
}

class _ScoreResult {
  final int overall;
  final int wordScore;
  final int timingScore;
  final bool isPassing;

  const _ScoreResult({
    required this.overall,
    required this.wordScore,
    required this.timingScore,
    required this.isPassing,
  });
}
