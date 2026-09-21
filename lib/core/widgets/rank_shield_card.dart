import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../constants/app_colors.dart';
import '../services/gamification_service.dart';
import '../services/language_service.dart';

class RankShieldCard extends StatefulWidget {
  final bool compact;
  const RankShieldCard({super.key, this.compact = false});

  @override
  State<RankShieldCard> createState() => _RankShieldCardState();
}

class _RankShieldCardState extends State<RankShieldCard> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    final currentRank = GamificationService.to.currentRank;
    _currentPage = UserRank.values.indexOf(currentRank);
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gamification = GamificationService.to;
    final lang = LanguageService.to;

    return Obx(() {
      final currentXp = gamification.currentXp.value;
      final currentRank = gamification.currentRank;
      final streak = gamification.currentStreak.value;
      final isBn = lang.isBangla;

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Swipeable Rank Cards
            SizedBox(
              height: widget.compact ? 175 : 210,
              child: PageView.builder(
                controller: _pageController,
                itemCount: UserRank.values.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, index) {
                  final rank = UserRank.values[index];
                  final isUserRank = rank == currentRank;
                  return _buildRankPage(
                    rank: rank,
                    isUserRank: isUserRank,
                    currentXp: currentXp,
                    streak: streak,
                    isBn: isBn,
                  );
                },
              ),
            ),

            // Dot indicators
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(UserRank.values.length, (i) {
                  final isSel = i == _currentPage;
                  final r = UserRank.values[i];
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isSel ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isSel
                          ? r.color
                          : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildRankPage({
    required UserRank rank,
    required bool isUserRank,
    required int currentXp,
    required int streak,
    required bool isBn,
  }) {
    // XP math for this rank
    final range = rank.nextThreshold - rank.minXp;
    double progress = 0.0;
    if (currentXp >= rank.nextThreshold) {
      progress = 1.0;
    } else if (currentXp < rank.minXp) {
      progress = 0.0;
    } else {
      progress = ((currentXp - rank.minXp) / range).clamp(0.0, 1.0);
    }

    final rankTitle = isBn ? rank.nameBn : rank.nameEn;

    // Helper text
    String helperText = '';
    if (isUserRank) {
      if (rank == UserRank.platinum) {
        helperText = isBn ? 'সর্বোচ্চ পদমর্যাদা অর্জিত!' : 'Highest rank achieved!';
      } else {
        final remaining = rank.nextThreshold - currentXp;
        final nextRank = UserRank.values[rank.index + 1];
        final nextName = isBn ? nextRank.nameBn : nextRank.nameEn;
        helperText = isBn
            ? '$nextName-এ পৌঁছাতে $remaining XP বাকি'
            : '$remaining XP to $nextName';
      }
    } else if (rank.index < GamificationService.to.currentRank.index) {
      helperText = isBn ? 'অর্জিত পদমর্যাদা' : 'Rank unlocked';
    } else {
      helperText = isBn
          ? '${rank.minXp} XP প্রয়োজন'
          : 'Requires ${rank.minXp} XP';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        children: [
          // Top Row: Shield + Ribbon + Streak Chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 3D Shield & Ribbon
              Row(
                children: [
                  _build3DShieldBadge(rank),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            rankTitle.toUpperCase(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: rank.color,
                            ),
                          ),
                          if (isUserRank) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: rank.color.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: rank.color.withValues(alpha: 0.5),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                isBn ? 'সক্রিয়' : 'ACTIVE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: rank.color,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${rank.minXp} – ${rank.nextThreshold} XP',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Streak Chip (Flame icon, NOT emoji)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFFFF9500),
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isBn ? '$streak দিন' : '$streak d',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Spacer(),

          // XP Progress Numbers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$currentXp / ${rank.nextThreshold} XP',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: rank.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Glowing Progress Bar
          Stack(
            children: [
              Container(
                height: 9,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 9,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        rank.color.withValues(alpha: 0.7),
                        rank.color,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: rank.color.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Helper line: e.g. "20 XP to Silver"
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              helperText,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _build3DShieldBadge(UserRank rank) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [
            rank.color.withValues(alpha: 0.4),
            rank.color.withValues(alpha: 0.15),
            Colors.black.withValues(alpha: 0.5),
          ],
        ),
        border: Border.all(
          color: rank.color.withValues(alpha: 0.7),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: rank.color.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Iconsax.security_safe,
          size: 28,
          color: rank.color,
        ),
      ),
    );
  }
}
