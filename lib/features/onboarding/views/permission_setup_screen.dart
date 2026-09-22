import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/blocker/blocker_models.dart';
import '../../../core/blocker/blocker_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/language_service.dart';
import '../../../core/widgets/progress_ring.dart';

class PermissionSetupScreen extends StatefulWidget {
  const PermissionSetupScreen({super.key});

  @override
  State<PermissionSetupScreen> createState() => _PermissionSetupScreenState();
}

class _PermissionSetupScreenState extends State<PermissionSetupScreen>
    with WidgetsBindingObserver {
  PermissionStatusSet _status = const PermissionStatusSet();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    try {
      final status = await BlockerService.to.blocker.checkPermissions();
      if (mounted) {
        setState(() {
          _status = status;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showProminentDisclosure(BuildContext context, bool isBn) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.accessibility_new_rounded,
                color: AppColors.brightGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isBn ? 'অ্যাক্সেসিবিলিটি স্পষ্ট প্রজ্ঞাপন' : 'Accessibility Disclosure',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isBn
                  ? 'FocusDeen আপনার নির্ধারিত সুরক্ষিত অ্যাপসমূহ (যেমনঃ TikTok, YouTube) খোলার সময় সনাক্ত করতে এবং স্ক্রিন লক করে আমল প্রদর্শন করতে অ্যাক্সেসিবিলিটি সার্ভিস ব্যবহার করে।'
                  : 'FocusDeen uses the Accessibility Service API strictly to detect when you launch protected applications (e.g. TikTok, YouTube) and present your Islamic deed screen.',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            _buildDisclosurePoint(
              isBn
                  ? '🔒 কোনো ব্যক্তিগত তথ্য, মেসেজ বা পাসওয়ার্ড পর্যবেক্ষণ বা সংগ্রহ করা হয় না।'
                  : '🔒 Never reads messages, typed text, passwords, or personal content.',
            ),
            const SizedBox(height: 8),
            _buildDisclosurePoint(
              isBn
                  ? '📱 সমস্ত যাচাইকরণ সম্পূর্ণরূপে আপনার ফোনের মধ্যে অফলাইনে ঘটে।'
                  : '📱 All detection operates 100% locally and offline on your device.',
            ),
            const SizedBox(height: 8),
            _buildDisclosurePoint(
              isBn
                  ? '⚡ আপনি যেকোনো সময় সেটিংস থেকে এটি বন্ধ করতে পারেন।'
                  : '⚡ You can toggle this permission off anytime from system settings.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              isBn ? 'পরে করব' : 'No thanks',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await BlockerService.to.blocker.openPermissionSettings(
                BlockerPermission.accessibility,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              isBn ? 'সম্মত ও চালু করুন' : 'Agree & Enable',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclosurePoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageService = LanguageService.to;

    return Obx(() {
      final isBn = languageService.isBangla;

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
            onPressed: () => Get.back(),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.toNamed(AppRoutes.dailyGoal),
              child: Text(
                isBn ? 'এড়িয়ে যান' : 'Skip',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ),
        body: ResponsiveScaffoldBody(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryGreen),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBn ? 'প্রয়োজনীয় অনুমতি সেটআপ' : 'Permission Setup',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isBn
                            ? 'অ্যাপ লক এবং সঠিক সময়ে আমল আসার জন্য নিচের অনুমতিগুলো চালু করুন।'
                            : 'Enable the permissions below to allow FocusDeen to protect apps and run timers accurately.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 1. Accessibility Service (Primary)
                      _buildPermissionCard(
                        icon: Icons.accessibility_new_rounded,
                        title: isBn ? 'অ্যাপ মনিটরিং (অ্যাক্সেসিবিলিটি)' : 'App Blocker (Accessibility)',
                        description: isBn
                            ? 'সুরক্ষিত অ্যাপ ওপেন হলে FocusDeen স্ক্রিন আনতে প্রয়োজন। কোনো ব্যক্তিগত ডাটা দেখা হয় না।'
                            : 'Detects when locked apps open to display your deed. No personal data is read.',
                        isGranted: _status.accessibilityGranted,
                        isRequired: true,
                        onTap: () => _showProminentDisclosure(context, isBn),
                      ),
                      const SizedBox(height: 12),

                      // 2. Display Over Other Apps (Overlay)
                      _buildPermissionCard(
                        icon: Icons.layers_rounded,
                        title: isBn ? 'অন্য অ্যাপের উপরে প্রদর্শন' : 'Display Over Other Apps',
                        description: isBn
                            ? 'লক করা অ্যাপের উপর তাৎক্ষণিক আমল স্ক্রিন আনার জন্য প্রয়োজন।'
                            : 'Allows the Islamic deed screen to appear seamlessly over protected apps.',
                        isGranted: _status.overlayGranted,
                        isRequired: true,
                        onTap: () => BlockerService.to.blocker.openPermissionSettings(
                          BlockerPermission.overlay,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 3. Notifications
                      _buildPermissionCard(
                        icon: Icons.notifications_active_rounded,
                        title: isBn ? 'বিজ্ঞপ্তি ও সময়সীমা রিমাইন্ডার' : 'Notifications',
                        description: isBn
                            ? 'আনলক সময় শেষ হওয়ার পূর্ব সংকেত এবং আমল নোটিফিকেশনের জন্য।'
                            : 'Receive alerts when your unlock timer is about to end and daily reminders.',
                        isGranted: _status.notificationsGranted,
                        isRequired: false,
                        onTap: () => BlockerService.to.blocker.openPermissionSettings(
                          BlockerPermission.notifications,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 4. Battery Optimization
                      _buildPermissionCard(
                        icon: Icons.battery_charging_full_rounded,
                        title: isBn ? 'ব্যাকগ্রাউন্ড সুরক্ষা (ব্যাটারি অপ্টিমাইজেশন)' : 'Battery Optimization Exclusion',
                        description: isBn
                            ? 'ফোন স্লিপে গেলে লক বন্ধ হওয়া রোধ করতে "No restrictions" নির্বাচন করুন।'
                            : 'Prevents the OS from killing FocusDeen timer service in the background.',
                        isGranted: _status.batteryOptimizationIgnored,
                        isRequired: false,
                        onTap: () => BlockerService.to.blocker.openPermissionSettings(
                          BlockerPermission.batteryOptimization,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // OEM Guidance Accordion Card
                      _buildOemGuidanceCard(isBn),

                      const SizedBox(height: 32),

                      // Continue Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => Get.toNamed(AppRoutes.dailyGoal),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isBn ? 'এগিয়ে যান' : 'Continue',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
        ),
      );
    });
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required bool isRequired,
    required VoidCallback onTap,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isGranted
                      ? AppColors.primaryGreen.withValues(alpha: 0.15)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isGranted ? AppColors.brightGreen : AppColors.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isRequired) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'REQ',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isGranted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 14, color: AppColors.brightGreen),
                      SizedBox(width: 4),
                      Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brightGreen,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Grant',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOemGuidanceCard(bool isBn) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.brightGreen, size: 18),
              const SizedBox(width: 8),
              Text(
                isBn ? 'Xiaomi / Vivo / Oppo / Samsung ব্যবহারকারীদের জন্য' : 'Device Specific Tips (Xiaomi/Samsung/Oppo)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isBn
                ? 'কিছু ফোনে (MIUI, ColorOS, OneUI) স্বয়ংক্রিয় ব্যাকগ্রাউন্ড কিলিং থাকে। নিশ্চিত করুন FocusDeen এর Autostart চালু আছে এবং ব্যাটারি সেভারে "No Restrictions" বা "Unrestricted" দেওয়া আছে।'
                : 'Aggressive battery savers on Xiaomi (MIUI), Oppo, and Samsung can terminate background locks. Please enable "Autostart" and set Battery to "No restrictions".',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
