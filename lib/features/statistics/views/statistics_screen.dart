import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/statistics_controller.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StatisticsController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Wellbeing & Statistics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.secondaryGold,
          labelColor: AppColors.secondaryGold,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Weekly'),
            Tab(text: 'Achievements'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayTab(context, controller, isDark),
          _buildWeeklyTab(context, controller, isDark),
          _buildAchievementsTab(context, controller, isDark),
        ],
      ),
    );
  }

  Widget _buildTodayTab(BuildContext context, StatisticsController controller, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        final s = controller.todayStats.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Focus Score Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F6B4F), Color(0xFF094332)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryEmerald.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 74,
                        height: 74,
                        child: CircularProgressIndicator(
                          value: controller.focusScore.value / 100,
                          strokeWidth: 8,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation(AppColors.secondaryGold),
                        ),
                      ),
                      Text(
                        '${controller.focusScore.value}%',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Today\'s Focus Score',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Calculated from limit discipline, completed focus sessions & lessons.',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '* Motivational estimate, non-medical',
                            style: TextStyle(fontSize: 10, color: Colors.white60),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Streak Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF16201C) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.secondaryGold.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 26)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${controller.learningStreakDays.value} Day Learning Streak',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          '7 consecutive days completed. MashaAllah!',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Metrics Grid
            const Text(
              'Activity Overview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.45,
              children: [
                _buildStatTile(
                  'Screen Time',
                  _formatMinutes(s.totalScreenTimeMinutes),
                  Icons.phone_android,
                  AppColors.primaryEmerald,
                  isDark,
                ),
                _buildStatTile(
                  'Social Media',
                  _formatMinutes(s.socialMediaMinutes),
                  Icons.public,
                  Colors.blueAccent,
                  isDark,
                ),
                _buildStatTile(
                  'Focus Time',
                  _formatMinutes(s.focusMinutes),
                  Icons.timer_outlined,
                  AppColors.secondaryGold,
                  isDark,
                ),
                _buildStatTile(
                  'Blocked Attempts',
                  '${s.blockedAttempts}',
                  Icons.block_outlined,
                  AppColors.danger,
                  isDark,
                ),
                _buildStatTile(
                  'Islamic Lessons',
                  '${s.lessonsCompleted} Completed',
                  Icons.menu_book,
                  AppColors.primaryEmerald,
                  isDark,
                ),
                _buildStatTile(
                  'Avg Practice Score',
                  '${s.averagePracticeScore}%',
                  Icons.verified,
                  AppColors.secondaryGold,
                  isDark,
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _buildWeeklyTab(BuildContext context, StatisticsController controller, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        final list = controller.weeklyStats;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Screen Time vs. Focus (Minutes)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Green: Focus Time • Blue: Screen Time',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Visual Comparison Bars
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF14201C) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
              ),
              child: Column(
                children: list.map((day) {
                  final dayLabel = _formatDayName(day.dateString);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 44,
                          child: Text(
                            dayLabel,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Screen time bar
                              Container(
                                height: 8,
                                width: (day.totalScreenTimeMinutes * 1.0).clamp(20.0, 200.0),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 3),
                              // Focus time bar
                              Container(
                                height: 8,
                                width: (day.focusMinutes * 2.5).clamp(10.0, 200.0),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryEmerald,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${day.totalScreenTimeMinutes}m / ${day.focusMinutes}m',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Weekly summary list
            const Text(
              'Daily Breakdown',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final day = list[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF16201C) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        day.dateString,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Blocked: ${day.blockedAttempts} • Lessons: ${day.lessonsCompleted} • Score: ${day.averagePracticeScore}%',
                        style: const TextStyle(fontSize: 12, color: AppColors.secondaryGold),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      }),
    );
  }

  Widget _buildAchievementsTab(BuildContext context, StatisticsController controller, bool isDark) {
    return Obx(() {
      final list = controller.achievements;

      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final ach = list[index];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: ach.isUnlocked
                    ? AppColors.secondaryGold
                    : (isDark ? Colors.white12 : Colors.black12),
              ),
            ),
            color: isDark ? const Color(0xFF14201C) : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: ach.isUnlocked
                          ? AppColors.secondaryGold.withOpacity(0.15)
                          : Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      ach.isUnlocked ? Icons.emoji_events : Icons.lock_outline,
                      color: ach.isUnlocked ? AppColors.secondaryGold : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ach.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (ach.isUnlocked)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryEmerald,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'UNLOCKED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ach.description,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: ach.progressPercentage,
                          backgroundColor: isDark ? Colors.white10 : Colors.black12,
                          valueColor: AlwaysStoppedAnimation(
                            ach.isUnlocked ? AppColors.secondaryGold : AppColors.primaryEmerald,
                          ),
                          minHeight: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14201C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }

  String _formatDayName(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[d.weekday - 1];
    } catch (_) {
      return dateStr;
    }
  }
}
