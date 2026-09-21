import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/language_service.dart';
import '../../../core/services/native_bridge_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/app_icon_widget.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../learning/views/deeds_library_view.dart';
import '../../settings/views/profile_view.dart';
import '../../statistics/views/progress_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final languageService = LanguageService.to;

    return Obx(() {
      final isBn = languageService.isBangla;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(
          index: _currentTabIndex,
          children: [
            _buildHomeTab(context, isBn),
            const ProgressView(),
            const DeedsLibraryView(),
            const ProfileView(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.border, width: 1.0),
            ),
          ),
          child: NavigationBar(
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.primaryGreen.withValues(alpha: 0.18),
            selectedIndex: _currentTabIndex,
            onDestinationSelected: (idx) =>
                setState(() => _currentTabIndex = idx),
            destinations: [
              NavigationDestination(
                icon: const Icon(
                  Icons.home_outlined,
                  color: AppColors.textSecondary,
                ),
                selectedIcon: const Icon(
                  Icons.home,
                  color: AppColors.brightGreen,
                ),
                label: isBn ? 'হোম' : 'Home',
              ),
              NavigationDestination(
                icon: const Icon(
                  Icons.show_chart_rounded,
                  color: AppColors.textSecondary,
                ),
                selectedIcon: const Icon(
                  Icons.show_chart_rounded,
                  color: AppColors.brightGreen,
                ),
                label: isBn ? 'অগ্রগতি' : 'Progress',
              ),
              NavigationDestination(
                icon: const Icon(
                  Icons.menu_book_outlined,
                  color: AppColors.textSecondary,
                ),
                selectedIcon: const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.brightGreen,
                ),
                label: isBn ? 'আমল' : 'Deeds',
              ),
              NavigationDestination(
                icon: const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.textSecondary,
                ),
                selectedIcon: const Icon(
                  Icons.person_rounded,
                  color: AppColors.brightGreen,
                ),
                label: isBn ? 'প্রোফাইল' : 'Profile',
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHomeTab(BuildContext context, bool isBn) {
    final storage = Get.find<StorageService>();
    final languageService = LanguageService.to;
    final completedDeeds = storage.getCompletedDeedsCount();
    final totalDeeds =
        storage.getTotalDeedsCount() > 0 ? storage.getTotalDeedsCount() : 6;
    final progressPercent = (completedDeeds / totalDeeds).clamp(0.0, 1.0);
    final userName = storage.getUserName();
    final unlockDuration = storage.getDefaultUnlockDurationMinutes();
    final monitoredPkgs = storage.getMonitoredPackages();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Greeting & Language Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBn ? 'শুভ সকাল, $userName' : 'Good morning, $userName',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isBn
                            ? 'আজকের স্ক্রিন টাইমকে করুন অর্থপূর্ণ ও কল্যাণময়।'
                            : "Let's make today's screen time meaningful.",
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Language Switcher Chip
                    GestureDetector(
                      onTap: () =>
                          languageService.showLanguageSelector(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isBn ? '🇧🇩 বাং' : '🇬🇧 EN',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.brightGreen,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_drop_down,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Accessibility Permission Alert Banner
            FutureBuilder<bool>(
              future: Get.find<NativeBridgeService>()
                  .checkAccessibilityPermission(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data == false) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.warning,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isBn
                                    ? 'লক কাজ করতে পারমিশন দিন'
                                    : 'Enable App Lock Service',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isBn
                                    ? 'অ্যাপ ব্লক কার্যকর রাখতে অ্যাক্সেসিবিলিটি চালু করুন।'
                                    : 'Accessibility is required to block selected apps.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            await Get.find<NativeBridgeService>()
                                .requestPermission('accessibility');
                            setState(() {});
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warning,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            isBn ? 'অন করুন' : 'Enable',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Main Card: Today's Progress
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                children: [
                  Text(
                    isBn ? "আজকের অগ্রগতি" : "Today's progress",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ProgressRing(
                    progress: progressPercent,
                    size: 110,
                    strokeWidth: 8,
                    centerChild: Text(
                      '${(progressPercent * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isBn
                        ? '$completedDeeds / $totalDeeds টি আমল সম্পন্ন'
                        : '$completedDeeds / $totalDeeds deeds completed',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Protected Apps Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isBn ? 'সুরক্ষিত অ্যাপসমূহ' : 'Protected Apps',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.toNamed('/app-selection'),
                  child: Text(
                    isBn ? 'পরিবর্তন করুন' : 'Edit',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brightGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...monitoredPkgs.map((pkg) {
                    final appName = _getFriendlyAppName(pkg);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: _buildAppPill(appName),
                    );
                  }),
                  GestureDetector(
                    onTap: () => Get.toNamed('/app-selection'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primaryGreen.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: AppColors.brightGreen,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isBn ? 'যোগ করুন' : 'Add',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brightGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Next Task / Deed Card
            AppCard(
              onTap: () => Get.toNamed('/intention'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isBn ? 'পরবর্তী আমল' : 'NEXT DEED',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: AppColors.brightGreen,
                          ),
                        ),
                      ),
                      Text(
                        isBn
                            ? '🌿 $unlockDuration মিনিট ব্যবহার'
                            : '🌿 ${unlockDuration}m access',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isBn
                        ? 'ইস্তিগফার ৩ বার পাঠ করুন'
                        : 'Recite Istighfar 3 times',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isBn
                        ? 'আস্তাগফিরুল্লাহা ওয়া আতূবু ইলাইহি — আল্লাহর কাছে ক্ষমা প্রার্থনা'
                        : 'Astaghfirullah — Seek forgiveness and invite peace',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        isBn ? 'শুরু করুন' : 'Start',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brightGreen,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: AppColors.brightGreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _getFriendlyAppName(String pkg) {
    final lower = pkg.toLowerCase();
    if (lower.contains('tiktok') ||
        lower.contains('musically') ||
        lower.contains('trill')) {
      return 'TikTok';
    }
    if (lower.contains('instagram')) return 'Instagram';
    if (lower.contains('facebook') || lower.contains('katana')) return 'Facebook';
    if (lower.contains('youtube')) return 'YouTube';
    if (lower.contains('snapchat')) return 'Snapchat';
    if (lower.contains('twitter') || lower.contains('.x.')) return 'X';
    if (lower.contains('reddit')) return 'Reddit';
    if (lower.contains('whatsapp')) return 'WhatsApp';
    final parts = pkg.split('.');
    return parts.length > 1 ? parts.last.capitalizeFirst ?? parts.last : pkg;
  }

  Widget _buildAppPill(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIconWidget(appName: name, size: 20, borderRadius: 6),
          const SizedBox(width: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
