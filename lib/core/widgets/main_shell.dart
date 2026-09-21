import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:focus_deen/core/constants/app_colors.dart';
import 'package:focus_deen/core/services/notification_service.dart';
import 'package:focus_deen/core/constants/app_strings.dart';
import 'package:focus_deen/features/dashboard/bindings/dashboard_binding.dart';
import 'package:focus_deen/features/dashboard/views/dashboard_screen.dart';
import 'package:focus_deen/features/learning/views/learning_catalog_screen.dart';
import 'package:focus_deen/features/limits/bindings/limit_binding.dart';
import 'package:focus_deen/features/limits/views/limit_screen.dart';
import 'package:focus_deen/features/schedule/views/schedule_screen.dart';
import 'package:focus_deen/features/settings/views/settings_screen.dart';
import 'package:focus_deen/features/statistics/views/statistics_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // Tab pages – kept alive via IndexedStack
  static const List<Widget> _pages = [
    DashboardScreen(),
    LearningCatalogScreen(),
    LimitScreen(),
    ScheduleScreen(),
    StatisticsScreen(),
    SettingsScreen(),
  ];

  static const List<String> _pageTitles = [
    AppStrings.appName,
    'Learning',
    'Limits',
    'Schedule',
    'Statistics',
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
    // Initialise all required bindings once
    DashboardBinding().dependencies();
    LimitBinding().dependencies();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _pageTitles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        actions: [
          // Notification bell with unread badge
          Obx(() {
            final notifService = Get.isRegistered<NotificationService>()
                ? NotificationService.to
                : null;
            final unread = notifService?.unreadCount.value ?? 0;
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  tooltip: 'Notifications',
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => Get.toNamed('/notifications'),
                ),
                if (unread > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unread > 9 ? '9+' : '$unread',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: _navColor(isDark)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book, color: _navColor(isDark)),
            label: 'Learning',
          ),
          NavigationDestination(
            icon: const Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer, color: _navColor(isDark)),
            label: 'Limits',
          ),
          NavigationDestination(
            icon: const Icon(Icons.alarm_outlined),
            selectedIcon: Icon(Icons.alarm, color: _navColor(isDark)),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: _navColor(isDark)),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: _navColor(isDark)),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Color _navColor(bool isDark) => AppColors.primaryEmerald;
}
