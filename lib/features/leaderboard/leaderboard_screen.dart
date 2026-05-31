import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/firebase_service.dart';
import '../../core/utils/icon_handler.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseService().currentUser?.uid;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseService().getLeaderboardStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary))),
          );
        }

        final rankings = snapshot.data!.docs.map((doc) {
          final data = doc.data();
          final mmr = data['mmr'] as int? ?? 80;
          return {
            'uid': doc.id,
            'name': data['name'] ?? 'Pelajar',
            'school': data['school_name'] ?? 'SMP Negeri 1',
            'avatar': data['avatar_url'] ?? 'kinz.png',
            'mmr': mmr,
            'rankName': _rankName(mmr),
            'rankColor': _rankColor(mmr),
          };
        }).toList();

        while (rankings.length < 3) {
          final index = rankings.length;
          final mmr = 120 - (index * 15);
          rankings.add({
            'uid': 'dummy_$index',
            'name': index == 0 ? 'Aulia' : index == 1 ? 'Budi' : 'Citra',
            'school': 'SMPN 1 Jakarta',
            'avatar': 'kinz.png',
            'mmr': mmr,
            'rankName': _rankName(mmr),
            'rankColor': _rankColor(mmr),
          });
        }

        final isMeInTop10 = myUid != null && rankings.any((r) => r['uid'] == myUid);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.surface,
                expandedHeight: 300,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.leaderboard_rounded, color: Colors.white, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Papan Peringkat',
                                style: AppTextStyles.h2.copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _PodiumItem(rank: 2, data: rankings[1]),
                              const SizedBox(width: 8),
                              _PodiumItem(rank: 1, data: rankings[0]),
                              const SizedBox(width: 8),
                              _PodiumItem(rank: 3, data: rankings[2]),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: _RankingList(rankings: rankings, myUid: myUid),
              ),
            ],
          ),
          bottomNavigationBar: myUid != null && !isMeInTop10
              ? _MyRankStickyFooter(myUid: myUid)
              : null,
        );
      },
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> data;

  const _PodiumItem({required this.rank, required this.data});

  double get _height => rank == 1 ? 80 : (rank == 2 ? 60 : 46);
  Color get _medalColor =>
      rank == 1 ? AppColors.gold : (rank == 2 ? AppColors.silver : AppColors.bronze);

  @override
  Widget build(BuildContext context) {
    final rankColor = data['rankColor'] as Color;
    return Column(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: _medalColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Center(
            child: Text(
              '$rank',
              style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: rankColor, width: 3),
          ),
          child: Center(
            child: IconHandler.buildItemIcon(data['avatar'] ?? 'kinz.png', size: 38),
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          width: 76,
          child: Text(
            data['name'].toString().split(' ')[0],
            style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: 72,
          height: _height,
          decoration: BoxDecoration(
            color: _medalColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Center(
            child: Text(
              data['rankName'] as String,
              style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

class _RankingList extends StatelessWidget {
  final List<Map<String, dynamic>> rankings;
  final String? myUid;

  const _RankingList({required this.rankings, required this.myUid});

  @override
  Widget build(BuildContext context) {
    return SliverList.separated(
      itemCount: rankings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final data = rankings[i];
        final isMe = data['uid'] == myUid;
        final rank = i + 1;
        final rankColor = data['rankColor'] as Color;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isMe ? AppColors.primarySurface : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: isMe
                ? Border.all(color: AppColors.primary, width: 2)
                : Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: rank <= 3 ? rankColor.withValues(alpha: 0.14) : AppColors.borderLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: AppTextStyles.caption.copyWith(
                      color: rank <= 3 ? rankColor : AppColors.textSecondary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isMe ? AppColors.primary : AppColors.borderLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: IconHandler.buildItemIcon(data['avatar'] ?? 'kinz.png', size: 30),
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
                            data['name'] as String,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: isMe ? AppColors.primary : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              'Kamu',
                              style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      data['school'] as String,
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    data['rankName'] as String,
                    style: AppTextStyles.label.copyWith(color: rankColor, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    '${data['mmr']} MMR',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
                  ),
                ],
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: 45 * i), duration: 260.ms)
            .slideX(begin: 0.04, delay: Duration(milliseconds: 45 * i));
      },
    );
  }
}

String _rankName(int mmr) {
  if (mmr < 100) return 'Perunggu';
  if (mmr < 200) return 'Perak';
  if (mmr < 400) return 'Emas';
  if (mmr < 800) return 'Platinum';
  return 'Berlian';
}

Color _rankColor(int mmr) {
  if (mmr < 100) return AppColors.bronze;
  if (mmr < 200) return AppColors.silver;
  if (mmr < 400) return AppColors.gold;
  if (mmr < 800) return const Color(0xFF4EA8DE);
  return const Color(0xFF906CD4);
}

class _MyRankStickyFooter extends StatelessWidget {
  final String myUid;
  
  const _MyRankStickyFooter({required this.myUid});
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: FirebaseService().getUserProfile(myUid),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData || userSnapshot.data == null) {
          return const SizedBox.shrink();
        }
        
        final userData = userSnapshot.data!;
        final name = userData['name'] ?? 'Kamu';
        final school = userData['school_name'] ?? 'Sekolah';
        final avatar = userData['avatar_url'] ?? 'kinz.png';
        final mmr = userData['mmr'] ?? 80;
        final rankName = _rankName(mmr);
        final rankColor = _rankColor(mmr);
        
        return FutureBuilder<int>(
          future: FirebaseService().getUserLeaderboardRank(myUid),
          builder: (context, rankSnapshot) {
            if (!rankSnapshot.hasData) {
              return const SizedBox.shrink();
            }
            final rank = rankSnapshot.data!;
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                border: Border.all(color: AppColors.primary, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '#$rank',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: IconHandler.buildItemIcon(avatar, size: 30),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  'Kamu',
                                  style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            school,
                            style: AppTextStyles.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          rankName,
                          style: AppTextStyles.label.copyWith(color: rankColor, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          '$mmr MMR',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
