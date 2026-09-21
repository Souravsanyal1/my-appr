import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Alada FlutterEngine er entrypoint. Kotlin theke "lockOverlayMain" naame chalano hoy.
/// Main.dart er sathe ei file ta import thakte hobe, ar @pragma tree-shaking theke bachay.
@pragma('vm:entry-point')
void lockOverlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  // Ei engine ekta ALADA isolate. Main app er in-memory provider/state ekhane nei.
  // Settings, score threshold, history: persistent storage (repository) theke porhun.
  runApp(const LockOverlayApp());
}

class LockRequest {
  const LockRequest({
    required this.package,
    required this.label,
    required this.minScore,
    required this.durationMinutes,
  });

  final String package;
  final String label;
  final int minScore;
  final int durationMinutes;

  factory LockRequest.fromMap(Map<dynamic, dynamic> m) => LockRequest(
        package: m['package'] as String,
        label: m['label'] as String,
        minScore: m['minScore'] as int,
        durationMinutes: m['durationMinutes'] as int,
      );
}

class LockOverlayApp extends StatefulWidget {
  const LockOverlayApp({super.key});

  @override
  State<LockOverlayApp> createState() => _LockOverlayAppState();
}

class _LockOverlayAppState extends State<LockOverlayApp> {
  static const _channel = MethodChannel('deenflow/lock_overlay');

  LockRequest? _request;
  int _session = 0; // prottek show e notun key, tai deed flow abar prothom step theke shuru hoy

  @override
  void initState() {
    super.initState();
    _channel.setMethodCallHandler(_onNativeCall);
    _channel.invokeMethod<void>('engineReady');
  }

  Future<dynamic> _onNativeCall(MethodCall call) async {
    if (call.method == 'onShow') {
      final req = LockRequest.fromMap(call.arguments as Map);
      setState(() {
        _request = req;
        _session++;
      });
      // Prothom real frame draw hole native cover soriye dao
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _channel.invokeMethod<void>('shown');
      });
    }
    return null;
  }

  Future<void> _onDeedFinished({required int score}) async {
    final req = _request;
    if (req == null) return;
    if (score >= req.minScore) {
      await _channel.invokeMethod<void>('unlockAndDismiss', {'score': score});
    } else {
      // Fail: deed screen e "Try Again" thakle setao ekhane. Shesh e cancel korle HOME.
    }
  }

  Future<void> _onCancel() => _channel.invokeMethod<void>('cancelAndGoHome');

  @override
  Widget build(BuildContext context) {
    final req = _request;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // TODO: apnar existing dark theme (forest green + #1FE08F) ekhane din, e.g. AppTheme.dark
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        backgroundColor: const Color(0xFF06120E),
        body: SafeArea(
          child: req == null
              ? const SizedBox.shrink()
              : KeyedSubtree(
                  key: ValueKey(_session),
                  // TODO: apnar EXISTING deed flow reuse korun (Deed -> Learn -> Record -> Analysis -> Result).
                  // Logic duplicate korben na. Shudhu navigation ar result callback jorun:
                  //
                  // DeedFlow(
                  //   targetAppLabel: req.label,
                  //   minScore: req.minScore,
                  //   unlockMinutes: req.durationMinutes,
                  //   onPassed: (score) => _onDeedFinished(score: score),
                  //   onExit: _onCancel,          // "Lock Now", back, ba retry na kore ber hole
                  // ),
                  child: _PlaceholderDeed(
                    request: req,
                    onPass: () => _onDeedFinished(score: 100),
                    onCancel: _onCancel,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Shudhu test korar jonno. Apnar asol deed flow diye replace korun.
class _PlaceholderDeed extends StatelessWidget {
  const _PlaceholderDeed({
    required this.request,
    required this.onPass,
    required this.onCancel,
  });

  final LockRequest request;
  final VoidCallback onPass;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${request.label} is locked',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            FilledButton(onPressed: onPass, child: const Text('Fake pass (test)')),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onCancel, child: const Text('Cancel')),
          ],
        ),
      ),
    );
  }
}
