import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_routes.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../profile/profile_screen.dart';
import '../duel/duel_lobby_screen.dart';
import '../gacha/gacha_screen.dart';
import '../friends/friends_screen.dart';
import '../../core/services/firebase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  final _pages = const [
    _HomeTab(),
    LeaderboardScreen(),
    DuelLobbyScreen(),
    FriendsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _navIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Beranda',
                  active: _navIndex == 0,
                  onTap: () => setState(() => _navIndex = 0),
                ),
                _NavItem(
                  icon: Icons.leaderboard_rounded,
                  label: 'Ranking',
                  active: _navIndex == 1,
                  onTap: () => setState(() => _navIndex = 1),
                ),
                _NavItem(
                  icon: Icons.sports_kabaddi_rounded,
                  label: 'Duel',
                  active: _navIndex == 2,
                  onTap: () => setState(() => _navIndex = 2),
                  highlight: true,
                ),
                _NavItem(
                  icon: Icons.people_rounded,
                  label: 'Friend',
                  active: _navIndex == 3,
                  onTap: () => setState(() => _navIndex = 3),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Profil',
                  active: _navIndex == 4,
                  onTap: () => setState(() => _navIndex = 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool highlight;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    if (highlight) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.secondary, Color(0xFFFF4757)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.label.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: active ? AppColors.primary : AppColors.textHint,
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: active ? AppColors.primary : AppColors.textHint,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Home Tab ───────────────────────────────────────────────────────────────

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  bool _hasSynced = false;

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseService().currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseService().getUserStream(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary))),
          );
        }

        final userData = snapshot.data!.data() ?? {};
        final String name = userData['name'] ?? 'Pelajar';
        final int streak = userData['streak'] ?? 0;
        final int gems = userData['gems'] ?? 0;
        final int xp = userData['xp'] ?? 0;
        final int level = userData['level'] ?? 1;
        final String avatar = userData['avatar_url'] ?? '🧑';
        final int winRate = (((userData['win_rate'] ?? 0.0) as num) * 100).toInt();
        final int totalDuels = userData['total_duels'] ?? 0;
        final int mmr = userData['mmr'] ?? 80;

        final int relativeXp = xp % 1000;
        final int xpRemaining = 1000 - relativeXp;

        if (!_hasSynced) {
          _hasSynced = true;
          FirebaseService().checkAndSyncUserData(uid, userData);
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header Section
                  _buildHeader(name, streak, avatar),
                  const SizedBox(height: 20),

                  // 2. Stats & Level Progress Card
                  _buildStatsCard(xp, gems, winRate, totalDuels, level, relativeXp, xpRemaining, mmr),
                  const SizedBox(height: 24),

                  // 3. Tantangan Harian
                  _buildDailyChallenges(context, uid, userData['daily_challenges'] as List<dynamic>? ?? []),
                  const SizedBox(height: 20),

                  // Friend Requests
                  _HomeFriendRequests(uid: uid),
                  const SizedBox(height: 20),

                  // 4. Action Buttons (DUEL & GACHA)
                  _buildActionButtons(context),
                  const SizedBox(height: 28),

                  // 5. Kalender (Streak Calendar)
                  _buildStreakCalendar(streak, userData['streak_last_date'] as Timestamp?),
                  const SizedBox(height: 28),

                  // 6. XP Diperoleh (Weekly XP Chart)
                  _buildXpChart(userData['weekly_xp'] as Map<String, dynamic>?),
                  const SizedBox(height: 100), // Spacing for bottom navigation bar
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(String name, int streak, String avatar) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, Pejuang!',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: AppTextStyles.h2.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Streak indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$streak',
                style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFEAA62B),
                ),
              ),
              const SizedBox(width: 4),
              const Text('🔥', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // Bell Icon
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFFC107),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 20),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '2',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        // Circular Avatar
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFFECEF),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFFC107), width: 2),
          ),
          child: Center(
            child: Text(avatar, style: const TextStyle(fontSize: 24)),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildStatsCard(int xp, int gems, int winRate, int totalDuels, int level, int relativeXp, int xpRemaining, int mmr) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _showRankTiersDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getRankColor(mmr).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: _getRankColor(mmr).withValues(alpha: 0.3), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getRankName(mmr).toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                      color: _getRankColor(mmr),
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(_getRankEmoji(mmr), style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Icon(Icons.info_outline_rounded, size: 10, color: _getRankColor(mmr)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_formatNumber(xp)} XP',
                    style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$mmr MMR',
                    style: AppTextStyles.caption.copyWith(color: const Color(0xFF8A70FF), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              _buildStatsMiniCol('$winRate%', 'Win rate'),
              _buildStatsMiniCol('$totalDuels', 'Total Duel'),
              _buildStatsMiniCol('$gems', 'Poin', labelColor: const Color(0xFFFFC107)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'lv $level',
                style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Level berikutnya: $xpRemaining XP lagi',
                style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: relativeXp / 1000,
              minHeight: 10,
              backgroundColor: const Color(0xFFEAEAEA),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF52B788)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }

  String _getRankName(int mmr) {
    if (mmr < 100) return 'Perunggu';
    if (mmr < 200) return 'Perak';
    if (mmr < 400) return 'Emas';
    if (mmr < 800) return 'Platinum';
    return 'Berlian';
  }

  String _getRankEmoji(int mmr) {
    if (mmr < 100) return '🥉';
    if (mmr < 200) return '🥈';
    if (mmr < 400) return '🥇';
    if (mmr < 800) return '💎';
    return '🏆';
  }

  Color _getRankColor(int mmr) {
    if (mmr < 100) return const Color(0xFFCD7F32); // Bronze
    if (mmr < 200) return const Color(0xFFC0C0C0); // Silver
    if (mmr < 400) return const Color(0xFFFFD700); // Gold
    if (mmr < 800) return const Color(0xFF4EA8DE); // Platinum
    return const Color(0xFF906CD4); // Diamond/Berlian
  }

  void _showRankTiersDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Text('🏆', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Text('Tingkatan Rank MMR', style: AppTextStyles.h3),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRankTierRow('🥉 Perunggu', '0 - 99 MMR', const Color(0xFFCD7F32)),
            const Divider(),
            _buildRankTierRow('🥈 Perak', '100 - 199 MMR', const Color(0xFFC0C0C0)),
            const Divider(),
            _buildRankTierRow('🥇 Emas', '200 - 399 MMR', const Color(0xFFFFD700)),
            const Divider(),
            _buildRankTierRow('💎 Platinum', '400 - 799 MMR', const Color(0xFF4EA8DE)),
            const Divider(),
            _buildRankTierRow('🏆 Berlian', '>= 800 MMR', const Color(0xFF906CD4)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Mengerti', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildRankTierRow(String title, String range, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.bodyLarge.copyWith(color: color, fontWeight: FontWeight.bold)),
          Text(range, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildStatsMiniCol(String value, String label, {Color? labelColor}) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h3.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: labelColor ?? AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDailyChallenges(BuildContext context, String uid, List<dynamic> challenges) {
    final List<Map<String, dynamic>> sortedChallenges = challenges.map((c) => Map<String, dynamic>.from(c as Map)).toList();
    
    // Sort: unclaimed first, then claimed
    sortedChallenges.sort((a, b) {
      final aClaimed = a['claimed'] ?? false;
      final bClaimed = b['claimed'] ?? false;
      if (aClaimed == bClaimed) return 0;
      return aClaimed ? 1 : -1;
    });

    final displayChallenges = sortedChallenges.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tantangan Harian',
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w900),
            ),
            TextButton(
              onPressed: () => _showAllChallengesDialog(context, uid, sortedChallenges),
              child: Text(
                'Lihat Semua',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (displayChallenges.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEAEAEA)),
            ),
            child: Center(
              child: Text(
                'Tidak ada tantangan hari ini.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayChallenges.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final challenge = displayChallenges[index];
              return _buildChallengeCard(context, uid, challenge);
            },
          ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }

  Widget _buildChallengeCard(BuildContext context, String uid, Map<String, dynamic> challenge) {
    final String challengeId = challenge['challenge_id'] ?? '';
    final String title = challenge['title'] ?? '';
    final int current = challenge['current_progress'] ?? 0;
    final int target = challenge['target_progress'] ?? 1;
    final int xpReward = challenge['xp_reward'] ?? 0;
    final int gemsReward = challenge['gems_reward'] ?? 0;
    final bool claimed = challenge['claimed'] ?? false;
    final bool isCompleted = current >= target;

    String rewardText = '';
    if (xpReward > 0 && gemsReward > 0) {
      rewardText = '+$xpReward XP / +$gemsReward Poin';
    } else if (xpReward > 0) {
      rewardText = '+$xpReward XP';
    } else if (gemsReward > 0) {
      rewardText = '+$gemsReward Poin';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: current / target,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFEAEAEA),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            claimed ? const Color(0xFF52B788).withValues(alpha: 0.5) : const Color(0xFF52B788)
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$current/$target',
                      style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (isCompleted && !claimed) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      try {
                        await FirebaseService().claimChallenge(uid, challengeId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Klaim reward sukses! $rewardText 🎉'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gagal mengklaim reward: $e'),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF52B788),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        'Claim Reward',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ] else if (claimed) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Selesai & Diklaim',
                    style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFF52B788),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            rewardText,
            style: AppTextStyles.label.copyWith(
              color: claimed ? Colors.grey : const Color(0xFFEAA62B),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showAllChallengesDialog(BuildContext context, String uid, List<Map<String, dynamic>> challenges) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseService().getUserStream(uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userData = snapshot.data!.data() ?? {};
                final rawChallenges = userData['daily_challenges'] as List<dynamic>? ?? [];
                final list = rawChallenges.map((c) => Map<String, dynamic>.from(c as Map)).toList();

                // Sort: unclaimed first, then claimed
                list.sort((a, b) {
                  final aClaimed = a['claimed'] ?? false;
                  final bClaimed = b['claimed'] ?? false;
                  if (aClaimed == bClaimed) return 0;
                  return aClaimed ? 1 : -1;
                });

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Semua Tantangan Hari Ini',
                        style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final challenge = list[index];
                            final String challengeId = challenge['challenge_id'] ?? '';
                            final String title = challenge['title'] ?? '';
                            final int current = challenge['current_progress'] ?? 0;
                            final int target = challenge['target_progress'] ?? 1;
                            final int xpReward = challenge['xp_reward'] ?? 0;
                            final int gemsReward = challenge['gems_reward'] ?? 0;
                            final bool claimed = challenge['claimed'] ?? false;
                            final bool isCompleted = current >= target;

                            String rewardText = '';
                            if (xpReward > 0 && gemsReward > 0) {
                              rewardText = '+$xpReward XP\n+$gemsReward Poin';
                            } else if (xpReward > 0) {
                              rewardText = '+$xpReward XP';
                            } else if (gemsReward > 0) {
                              rewardText = '+$gemsReward Poin';
                            }

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFEAEAEA)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(10),
                                                child: LinearProgressIndicator(
                                                  value: current / target,
                                                  minHeight: 8,
                                                  backgroundColor: const Color(0xFFEAEAEA),
                                                  valueColor: AlwaysStoppedAnimation<Color>(
                                                    claimed ? const Color(0xFF52B788).withValues(alpha: 0.5) : const Color(0xFF52B788)
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              '$current/$target',
                                              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        if (isCompleted && !claimed) ...[
                                          const SizedBox(height: 8),
                                          GestureDetector(
                                            onTap: () async {
                                              try {
                                                await FirebaseService().claimChallenge(uid, challengeId);
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Klaim reward sukses! 🎉'),
                                                      backgroundColor: AppColors.success,
                                                      behavior: SnackBarBehavior.floating,
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Gagal mengklaim: $e'),
                                                      backgroundColor: AppColors.error,
                                                      behavior: SnackBarBehavior.floating,
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF52B788),
                                                borderRadius: BorderRadius.circular(100),
                                              ),
                                              child: Text(
                                                'Claim Reward',
                                                style: AppTextStyles.caption.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ] else if (claimed) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            'Selesai & Diklaim',
                                            style: AppTextStyles.caption.copyWith(
                                              color: const Color(0xFF52B788),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    rewardText,
                                    style: AppTextStyles.label.copyWith(
                                      color: claimed ? Colors.grey : const Color(0xFFEAA62B),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        _buildActionPillButton('DUEL', AppColors.primary, const Color(0xFFC94A4A), () {
          Navigator.pushNamed(context, AppRoutes.duelLobby);
        }),
        const SizedBox(height: 12),
        _buildActionPillButton('GACHA', const Color(0xFF4EA8DE), const Color(0xFF3A8BB7), () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GachaScreen()),
          );
        }),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 250.ms);
  }

  Widget _buildActionPillButton(String label, Color color, Color shadowColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              offset: const Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.button.copyWith(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStreakCalendar(int streak, Timestamp? streakLastDate) {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    
    final daysOfWeek = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final monthName = _getIndonesianMonth(month);
    
    final numDays = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday;
    final startOffset = firstWeekday % 7;
    
    final totalCells = startOffset + numDays;
    final today = now.day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Kalender Streak',
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w900),
            ),
            Text(
              '$monthName $year',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFEAEAEA)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: daysOfWeek.map((day) => Expanded(
                  child: Center(
                    child: Text(
                      day.substring(0, 3),
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.85,
                ),
                itemCount: totalCells,
                itemBuilder: (context, index) {
                  if (index < startOffset) {
                    return const SizedBox.shrink();
                  }
                  
                  final dayNum = index - startOffset + 1;
                  final bool isStreakActive = dayNum <= today && dayNum >= (today - streak + 1);
                  final bool isToday = dayNum == today;
                  final bool isFuture = dayNum > today;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isStreakActive)
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 22)),
                            Positioned(
                              top: 6,
                              child: Text(
                                '$dayNum',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        )
                      else if (isToday)
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.primary, width: 2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$dayNum',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        )
                      else if (isFuture)
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF9F9F9),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$dayNum',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textHint,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEAEAEA),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$dayNum',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms);
  }

  String _getIndonesianMonth(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month - 1];
  }

  Widget _buildXpChart(Map<String, dynamic>? weeklyXp) {
    final Map<String, int> xpMap = {};
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const daysIndo = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    
    for (var day in days) {
      xpMap[day] = weeklyXp?[day] as int? ?? 0;
    }
    
    int maxVal = 100;
    xpMap.forEach((k, v) {
      if (v > maxVal) maxVal = v;
    });
    
    int chartMax = ((maxVal + 99) ~/ 100) * 100;
    if (chartMax < 500) chartMax = 500;

    final weekdayIndex = DateTime.now().weekday;
    final todayDayAbbr = days[weekdayIndex - 1];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'XP Diperoleh Pekan Ini',
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          height: 220,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFEAEAEA)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  '$chartMax',
                  '${(chartMax * 4) ~/ 5}',
                  '${(chartMax * 3) ~/ 5}',
                  '${(chartMax * 2) ~/ 5}',
                  '${(chartMax * 1) ~/ 5}',
                  '0'
                ].map((val) => Text(
                  val,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                )).toList(),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(days.length, (index) {
                    final dayKey = days[index];
                    final dayLabel = daysIndo[index];
                    final xpVal = xpMap[dayKey] ?? 0;
                    final percent = xpVal / chartMax;
                    final isToday = dayKey == todayDayAbbr;

                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (xpVal > 0)
                            Text(
                              '$xpVal',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: isToday ? AppColors.primary : AppColors.textSecondary,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final barHeight = constraints.maxHeight * percent;
                                return Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    width: 16,
                                    height: barHeight,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isToday
                                            ? [AppColors.primary, const Color(0xFFFF5E5E)]
                                            : [const Color(0xFF8A70FF), const Color(0xFF6C52EE)],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (isToday ? AppColors.primary : const Color(0xFF6C52EE))
                                              .withValues(alpha: 0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dayLabel,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 9,
                              color: isToday ? AppColors.primary : AppColors.textSecondary,
                              fontWeight: isToday ? FontWeight.w900 : FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 350.ms);
  }
}

class _HomeFriendRequests extends StatelessWidget {
  final String uid;
  const _HomeFriendRequests({required this.uid});

  String _timeAgo(dynamic timestamp) {
    if (timestamp == null) return '';
    final DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else {
      return '';
    }
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays} hari lalu';
    if (diff.inHours > 0) return '${diff.inHours} jam lalu';
    if (diff.inMinutes > 0) return '${diff.inMinutes} menit lalu';
    return 'Baru saja';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseService().getFriendRequestsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.mail_rounded, color: AppColors.primary, size: 16),
                ),
                const SizedBox(width: 8),
                Text('Permintaan Teman', style: AppTextStyles.h3),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${docs.length}',
                    style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final data = docs[index].data();
                final fromUid = data['from_uid'] as String? ?? data['uid'] as String? ?? '';
                final fromName = data['from_name'] as String? ?? data['name'] as String? ?? 'Pengguna';
                final fromAvatar = data['from_avatar'] as String? ?? data['avatar_url'] as String? ?? '🧑';
                final sentAt = data['sent_at'];

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEAEAEA)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.borderLight,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(fromAvatar, style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fromName,
                              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (sentAt != null)
                              Text(
                                _timeAgo(sentAt),
                                style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Accept Button
                      IconButton(
                        onPressed: () async {
                          await FirebaseService().acceptFriendRequest(fromUid);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$fromName ditambahkan sebagai teman! 🎉'),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
                      ),
                      // Decline Button
                      IconButton(
                        onPressed: () async {
                          await FirebaseService().rejectFriendRequest(fromUid);
                        },
                        icon: const Icon(Icons.cancel_rounded, color: AppColors.error, size: 28),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}
