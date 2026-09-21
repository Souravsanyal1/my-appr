import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/services/language_service.dart';
import '../../../core/services/native_bridge_service.dart';
import '../../../core/services/storage_service.dart';
import '../models/unlock_session_model.dart';

class ActiveUnlockView extends StatefulWidget {
  const ActiveUnlockView({super.key});

  @override
  State<ActiveUnlockView> createState() => _ActiveUnlockViewState();
}

class _ActiveUnlockViewState extends State<ActiveUnlockView>
    with WidgetsBindingObserver {
  late UnlockSessionModel _session;
  Timer? _countdownTimer;
  int _secondsRemaining = 30 * 60;
  late int _totalSeconds;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (Get.arguments is Map &&
        Get.arguments['session'] is UnlockSessionModel) {
      _session = Get.arguments['session'] as UnlockSessionModel;
    } else {
      final now = DateTime.now().millisecondsSinceEpoch;
      final expires = now + (30 * 60 * 1000);
      _session = UnlockSessionModel(
        packageName: 'com.zhiliaoapp.musically',
        appName: 'TikTok',
        durationMinutes: 30,
        expiresAtTimestamp: expires,
      );
    }

    _totalSeconds = _session.durationMinutes * 60;
    _updateRemainingTime();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemainingTime();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateRemainingTime();
    }
  }

  void _updateRemainingTime() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = ((_session.expiresAtTimestamp - now) / 1000).ceil();
    if (diff <= 0) {
      _countdownTimer?.cancel();
      if (mounted) {
        Get.offAllNamed('/home');
      }
    } else {
      if (mounted) {
        setState(() {
          _secondsRemaining = diff;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

    if (mounted) {
      Get.offAllNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageService = LanguageService.to;
    final mins = _secondsRemaining ~/ 60;
    final secs = _secondsRemaining % 60;
    final timeStr =
        '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    final progress = (_secondsRemaining / _totalSeconds).clamp(0.0, 1.0);

    return Obx(() {
      final isBn = languageService.isBangla;

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: AppColors.textPrimary,
            ),
            onPressed: () => Get.offAllNamed('/home'),
          ),
        ),
        body: ResponsiveScaffoldBody(
          child: Column(
            children: [
              // Target App Icon
              Container(
                width: context.responsiveSize(72, minSize: 56, maxSize: 84),
                height: context.responsiveSize(72, minSize: 56, maxSize: 84),
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
              const SizedBox(height: AppSpacing.md),

              Text(
                _session.appName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                isBn ? 'ব্যবহারের অবশিষ্ট সময়' : 'Access remaining',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),

              const Spacer(),

              // Giant Countdown Display
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: context.responsiveSize(
                    56,
                    minSize: 42,
                    maxSize: 68,
                  ),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                  color: AppColors.brightGreen,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Linear Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primaryGreen,
                  ),
                ),
              ),

              const Spacer(),

              // Primary CTA: Open App
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isBn
                              ? '${_session.appName} খোলা হচ্ছে...'
                              : 'Launching ${_session.appName}...',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                    await Get.find<NativeBridgeService>()
                        .launchApp(_session.packageName);
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
                    isBn
                        ? '${_session.appName} চালু করুন'
                        : 'Open ${_session.appName}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Secondary Action: Lock Now
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: _lockNow,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    isBn ? 'এখনই লক করুন' : 'Lock Now',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      );
    });
  }
}
