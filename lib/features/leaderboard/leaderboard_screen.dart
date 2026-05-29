import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/firebase_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

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

        final docs = snapshot.data!.docs;
        final List<Map<String, dynamic>> rankings = docs.map((d) {
          final data = d.data();
          return {
            'uid': d.id,
            'name': data['name'] ?? 'Pelajar',
            'school': data['school_name'] ?? 'SMP Negeri 1',
            'xp': data['xp'] ?? 0,
            'emoji': d.id == myUid ? '😊' : '🎓',
          };
        }).toList();

        // Fallback dummy padding if not enough users are registered yet
        while (rankings.length < 3) {
          final dummyIndex = rankings.length;
          rankings.add({
            'uid': 'dummy_$dummyIndex',
            'name': dummyIndex == 0 ? 'Aulia' : dummyIndex == 1 ? 'Budi' : 'Citra',
            'school': 'SMPN 1 Jakarta',
            'xp': 1000 - (dummyIndex * 100),
            'emoji': '🎓',
          });
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: NestedScrollView(
            headerSliverBuilder: (_, __) => [
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.surface,
                expandedHeight: 290,
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
                          Text(
                            '🏆 Papan Peringkat',
                            style: AppTextStyles.h2.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 20),
                          // Top 3 podium
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
                bottom: TabBar(
                  controller: _tab,
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textHint,
                  labelStyle: AppTextStyles.label,
                  tabs: const [
                    Tab(text: 'Harian'),
                    Tab(text: 'Mingguan'),
                    Tab(text: 'Bulanan'),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tab,
              children: List.generate(3, (_) => _RankingList(rankings: rankings, myUid: myUid)),
            ),
          ),
        );
      },
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> data;

  const _PodiumItem({required this.rank, required this.data});

  double get _height => rank == 1 ? 90 : (rank == 2 ? 70 : 55);
  Color get _color =>
      rank == 1 ? AppColors.gold : (rank == 2 ? AppColors.silver : AppColors.bronze);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          rank == 1 ? '👑' : (rank == 2 ? '🥈' : '🥉'),
          style: TextStyle(fontSize: rank == 1 ? 28 : 22),
        ),
        const SizedBox(height: 4),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: _color, width: 3),
          ),
          child: Center(
            child: Text(
              data['name'].toString().substring(0, 1),
              style: AppTextStyles.h2.copyWith(color: _color),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          data['name'].toString().split(' ')[0],
          style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Container(
          width: 70,
          height: _height,
          decoration: BoxDecoration(
            color: _color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: AppTextStyles.h3.copyWith(color: Colors.white),
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
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rankings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final d = rankings[i];
        final isMe = d['uid'] == myUid;
        final rank = i + 1;
        
        String rankEmoji = '🎓';
        if (rank == 1) rankEmoji = '👑';
        if (rank == 2) rankEmoji = '🥈';
        if (rank == 3) rankEmoji = '🥉';

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
              SizedBox(
                width: 32,
                child: Text(
                  rank <= 3
                      ? ['🥇', '🥈', '🥉'][rank - 1]
                      : '#$rank',
                  style: rank <= 3
                      ? const TextStyle(fontSize: 20)
                      : AppTextStyles.label,
                  textAlign: TextAlign.center,
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
                  child: Text(
                    d['name'].toString().substring(0, 1),
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: isMe ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          d['name'] as String,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: isMe ? AppColors.primary : AppColors.textPrimary,
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
                              style: AppTextStyles.caption
                                  .copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(d['school'] as String, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${d['xp']} XP',
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.primary),
                  ),
                  Text(rankEmoji,
                      style: const TextStyle(fontSize: 16)),
                ],
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: 50 * i), duration: 300.ms)
            .slideX(begin: 0.05, delay: Duration(milliseconds: 50 * i));
      },
    );
  }
}
