import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    // Initialise all required bindings once
    DashboardBinding().dependencies();
    LimitBinding().dependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Learning',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: 'Limits',
          ),
          NavigationDestination(
            icon: Icon(Icons.alarm_outlined),
            selectedIcon: Icon(Icons.alarm),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
