import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/native_bridge_service.dart';
import '../../../core/services/storage_service.dart';
import '../models/unlock_session_model.dart';

class ActiveUnlockView extends StatefulWidget {
  const ActiveUnlockView({super.key});

  @override
  State<ActiveUnlockView> createState() => _ActiveUnlockViewState();
}

class _ActiveUnlockViewState extends State<ActiveUnlockView> {
  late UnlockSessionModel _session;
  Timer? _countdownTimer;
  int _secondsRemaining = 30 * 60;
  final int _totalSeconds = 30 * 60;

  @override
  void initState() {
    super.initState();
    if (Get.arguments is Map && Get.arguments['session'] is UnlockSessionModel) {
      _session = Get.arguments['session'] as UnlockSessionModel;
      _secondsRemaining = _session.remainingSeconds > 0
          ? _session.remainingSeconds
          : _session.durationMinutes * 60;
    } else {
      _session = UnlockSessionModel(
        packageName: 'com.zhiliaoapp.musically',
        appName: 'TikTok',
        durationMinutes: 30,
        expiresAtTimestamp: DateTime.now().add(const Duration(minutes: 30)).millisecondsSinceEpoch,
      );
      _secondsRemaining = 30 * 60;
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _countdownTimer?.cancel();
        Get.offAllNamed('/home');
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _lockNow() async {
    final native = Get.find<NativeBridgeService>();
    final storage = Get.find<StorageService>();

    await native.removeTemporaryUnlock(_session.packageName);
    final existing = storage.getUnlockSessions();
    existing.removeWhere((s) => s.packageName == _session.packageName);
    storage.saveUnlockSessions(existing);

    Get.offAllNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    final mins = _secondsRemaining ~/ 60;
    final secs = _secondsRemaining % 60;
    final timeStr = '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    final progress = (_secondsRemaining / _totalSeconds).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
          onPressed: () => Get.offAllNamed('/home'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              // Target App Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Icon(
                    Icons.music_note_rounded,
                    color: AppColors.brightGreen,
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                _session.appName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Access remaining',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),

              const Spacer(),

              // Giant Countdown Display
              Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                  color: AppColors.brightGreen,
                ),
              ),
              const SizedBox(height: 24),

              // Linear Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                ),
              ),

              const Spacer(),

              // Primary CTA: Open App
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Launching ${_session.appName}...')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Open ${_session.appName}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Secondary Action: Lock Now
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: _lockNow,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Lock Now',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
