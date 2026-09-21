import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/language_service.dart';
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
    final completedDeeds =
        (storage.read<List<dynamic>>('completed_lesson_ids') ?? []).length;
    const totalDeeds = 6;
    final progressPercent = (completedDeeds / totalDeeds).clamp(0.0, 1.0);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Greeting & Language Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBn ? 'শুভ সকাল, Sourav' : 'Good morning, Sourav',
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
                Row(
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
            const SizedBox(height: 24),

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
                    progress: progressPercent > 0 ? progressPercent : 0.33,
                    size: 110,
                    strokeWidth: 8,
                    centerChild: Text(
                      '${((progressPercent > 0 ? progressPercent : 0.33) * 100).toInt()}%',
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
                        ? '${completedDeeds > 0 ? completedDeeds : 2} / $totalDeeds টি আমল সম্পন্ন'
                        : '${completedDeeds > 0 ? completedDeeds : 2} / $totalDeeds deeds completed',
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
            Text(
              isBn ? 'সুরক্ষিত অ্যাপসমূহ' : 'Protected Apps',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildAppPill('TikTok'),
                  const SizedBox(width: 8),
                  _buildAppPill('Instagram'),
                  const SizedBox(width: 8),
                  _buildAppPill('Facebook'),
                  const SizedBox(width: 8),
                  _buildAppPill('YouTube'),
                  const SizedBox(width: 8),
                  _buildAppPill('Snapchat'),
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
                        isBn ? '🌿 ৩০ মিনিট ব্যবহার' : '🌿 30m access',
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
