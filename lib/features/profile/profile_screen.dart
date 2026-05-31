import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/profile_theme.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/firebase_service.dart';
import '../../core/widgets/ribbon_badge.dart';
import '../../core/widgets/profile_effect.dart';

import '../../core/utils/icon_handler.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
        final name = userData['name'] ?? 'Pelajar';
        final school = userData['school_name'] ?? 'SMP Negeri 1';
        final grade = userData['grade'] ?? '8A';
        final level = userData['level'] ?? 1;
        final xp = userData['xp'] ?? 0;
        final totalDuels = userData['total_duels'] ?? 0;
        final winRate = (((userData['win_rate'] ?? 0.0) as num) * 100).toInt();
        final streak = userData['streak'] ?? 0;
        final gems = userData['gems'] ?? 0;
        final mmr = userData['mmr'] ?? 80;
        final tickets = userData['tickets'] ?? 0;
        final avatar = userData['avatar_url'] ?? 'kinz.png';
        final joinedAt = userData['created_at'];

        final themeId = userData['theme_id'] as String?;
        final effectId = userData['effect_id'] as String?;
        final themeConfig = ProfileThemeConfig.fromId(null, name);

        final relativeXp = xp % 1000;
        final xpRemaining = 1000 - relativeXp;

        String joinedText = 'April 2026';
        if (joinedAt is Timestamp) {
          final dt = joinedAt.toDate();
          final months = [
            'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
            'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
          ];
          joinedText = '${months[dt.month - 1]} ${dt.year}';
        }
        final profileCardContent = Stack(
          children: [
            // Tickets & Gems Indicators
            Positioned(
              top: 20,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF52B788).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.confirmation_num_rounded, color: Color(0xFF52B788), size: 12),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$tickets',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: themeConfig.hasGradientBg ? Colors.white : AppColors.textPrimary,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00B4D8).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Image.asset(
                          'assets/images/diamond.png',
                          width: 14,
                          height: 14,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$gems',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: themeConfig.hasGradientBg ? Colors.white : AppColors.textPrimary,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main Card Content Column
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                children: [
                  // Avatar & Notification Bell
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: IconHandler.buildItemIcon(avatar, size: 70, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 16),

                  // Name
                  Text(
                    name,
                    style: themeConfig.nameStyle,
                  ),
                  const SizedBox(height: 6),

                  // Class, School & Joined Date
                  Text(
                    'Kelas $grade, $school',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: themeConfig.bodyTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Joined $joinedText',
                    style: AppTextStyles.caption.copyWith(color: themeConfig.hasGradientBg ? Colors.white38 : AppColors.textHint),
                  ),
                  const SizedBox(height: 4),
                  FutureBuilder<int>(
                    future: FirebaseService().getFriendsCount(uid),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return Text(
                        '$count Friends',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Edit profile button (Full Width)
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.settings);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF52B788), // Green matching mockup
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Edit Profil',
                      style: AppTextStyles.label.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Statistik Title
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Statistik',
                      style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.15,
                    children: [
                      _StatBox(
                        color: themeConfig.statsBoxColor,
                        borderColor: themeConfig.statsBoxBorderColor,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Emas',
                              style: AppTextStyles.label.copyWith(
                                color: const Color(0xFFEAA62B),
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_formatNumber(xp)} XP',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                color: themeConfig.hasGradientBg ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StatBox(
                        color: themeConfig.statsBoxColor,
                        borderColor: themeConfig.statsBoxBorderColor,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$mmr MMR',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: const Color(0xFF8A70FF),
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StatBox(
                        color: themeConfig.statsBoxColor,
                        borderColor: themeConfig.statsBoxBorderColor,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$streak',
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    color: const Color(0xFFEAA62B),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.whatshot_rounded, color: Colors.orange, size: 15),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _StatBox(
                        color: themeConfig.statsBoxColor,
                        borderColor: themeConfig.statsBoxBorderColor,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$winRate%',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: themeConfig.hasGradientBg ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Win rate',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 10,
                                color: themeConfig.hasGradientBg ? Colors.white70 : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StatBox(
                        color: themeConfig.statsBoxColor,
                        borderColor: themeConfig.statsBoxBorderColor,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$totalDuels',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: themeConfig.hasGradientBg ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Total Duel',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 10,
                                color: themeConfig.hasGradientBg ? Colors.white70 : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FutureBuilder<int>(
                        future: FirebaseService().getUserLeaderboardRank(uid),
                        builder: (context, snapshot) {
                          final rank = snapshot.data ?? 1;
                          return _StatBox(
                            color: themeConfig.statsBoxColor,
                            borderColor: themeConfig.statsBoxBorderColor,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '#$rank',
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    color: themeConfig.hasGradientBg ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Rank',
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 10,
                                    color: themeConfig.hasGradientBg ? Colors.white70 : themeConfig.bodyTextColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Level Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'lv $level',
                            style: AppTextStyles.caption.copyWith(
                              color: themeConfig.hasGradientBg ? Colors.white70 : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10.5,
                            ),
                          ),
                          Text(
                            'Level berikutnya: $xpRemaining XP lagi',
                            style: AppTextStyles.caption.copyWith(
                              color: themeConfig.hasGradientBg ? Colors.white70 : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: (xp % 1000) / 1000,
                          minHeight: 12,
                          backgroundColor: themeConfig.hasGradientBg ? const Color(0x33FFFFFF) : const Color(0xFFEAEAEA),
                          valueColor: AlwaysStoppedAnimation<Color>(themeConfig.progressBarColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );

        final badgesCardContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Badges',
              style: AppTextStyles.h2.copyWith(
                fontWeight: FontWeight.w900,
                color: themeConfig.hasGradientBg ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseService().getUserBadges(uid),
              builder: (context, badgeSnapshot) {
                if (!badgeSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary)));
                }

                final badgeDocs = badgeSnapshot.data!.docs;
                final earnedBadges = badgeDocs.map((doc) => doc.data()['badge_id'] as String).toSet();
                
                final pinnedBadgeIds = badgeDocs
                    .where((doc) => doc.data()['is_pinned'] == true)
                    .map((doc) => doc.data()['badge_id'] as String)
                    .toList();
                
                final allDefinitions = FirebaseService().getAllBadgeDefinitions();
                
                List<Map<String, dynamic>> displayBadges = [];
                if (pinnedBadgeIds.isNotEmpty) {
                  for (var pId in pinnedBadgeIds.take(3)) {
                    final definition = allDefinitions.firstWhere((b) => b['badge_id'] == pId, orElse: () => {'badge_id': pId, 'badge_name': pId, 'badge_icon': 'medal', 'description': ''});
                    displayBadges.add(definition);
                  }
                } else {
                  final earnedList = badgeDocs.map((doc) => doc.data()['badge_id'] as String).toList();
                  for (var eId in earnedList.take(3)) {
                    final definition = allDefinitions.firstWhere((b) => b['badge_id'] == eId, orElse: () => {'badge_id': eId, 'badge_name': eId, 'badge_icon': 'medal', 'description': ''});
                    displayBadges.add(definition);
                  }
                }
                
                while (displayBadges.length < 3) {
                  final nextDef = allDefinitions.firstWhere(
                    (def) => !displayBadges.any((b) => b['badge_id'] == def['badge_id']),
                    orElse: () => allDefinitions.first,
                  );
                  displayBadges.add(nextDef);
                }

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: displayBadges.map((b) {
                        final bId = b['badge_id'] as String;
                        final earned = earnedBadges.contains(bId);

                        return GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: AppColors.surface,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                title: Row(
                                  children: [
                                    Text(b['badge_icon'] as String, style: const TextStyle(fontSize: 32)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        b['badge_name'] as String,
                                        style: AppTextStyles.h3,
                                      ),
                                    ),
                                  ],
                                ),
                                content: Text(
                                  b['description'] as String,
                                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Tutup', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              RibbonBadge(
                                type: bId,
                                earned: earned,
                                size: 64,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                b['badge_name'] as String,
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10.5,
                                  color: themeConfig.hasGradientBg ? Colors.white : AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.badgesList,
                            arguments: uid,
                          );
                        },
                        child: Text(
                          'Lihat Semua',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: themeConfig.hasGradientBg ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        );

        final mainBody = Stack(
          children: [
            if (effectId != null && effectId.isNotEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: ProfileEffectWidget(effectId: effectId),
                ),
              ),
            // Star Ornaments for background if required
            if (themeConfig.showStars) ...[
              Positioned(
                top: 130,
                left: 10,
                child: Transform.rotate(
                  angle: -0.2,
                  child: const Icon(Icons.star_rounded, color: Color(0xFFFFD600), size: 36),
                ),
              ),
              Positioned(
                bottom: 230,
                right: 8,
                child: Transform.rotate(
                  angle: 0.3,
                  child: const Icon(Icons.star_rounded, color: Color(0xFFFFD600), size: 38),
                ),
              ),
            ],

            // Main CustomScrollView
            CustomScrollView(
              slivers: [
                // Header title
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Profile',
                          style: AppTextStyles.h1.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: themeConfig.hasGradientBg ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Main profile card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: themeConfig.hasGradientBg
                            ? themeConfig.cardColor.withOpacity(0.75)
                            : themeConfig.cardColor,
                        borderRadius: BorderRadius.circular(32),
                        border: themeConfig.hasGradientBg
                            ? Border.all(color: Colors.white.withOpacity(0.12), width: 1.5)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: themeConfig.hasGradientBg ? 0.15 : 0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: themeConfig.hasGradientBg
                          ? BackdropFilter(
                              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: profileCardContent,
                            )
                          : profileCardContent,
                    ),
                  ),
                ),

                // Badges Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: themeConfig.hasGradientBg
                            ? themeConfig.cardColor.withOpacity(0.75)
                            : themeConfig.cardColor,
                        borderRadius: BorderRadius.circular(32),
                        border: themeConfig.hasGradientBg
                            ? Border.all(color: Colors.white.withOpacity(0.12), width: 1.5)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: themeConfig.hasGradientBg ? 0.15 : 0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: themeConfig.hasGradientBg
                          ? BackdropFilter(
                              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: badgesCardContent,
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.all(24),
                              child: badgesCardContent,
                            ),
                    ),
                  ),
                ),

                // Display Items Card (Koleksi Display)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: themeConfig.cardColor,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Display Tampilan',
                              style: AppTextStyles.h2.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                              stream: FirebaseService().getUserInventory(uid),
                              builder: (context, invSnapshot) {
                                if (!invSnapshot.hasData) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation(AppColors.primary),
                                    ),
                                  );
                                }

                                final docs = invSnapshot.data!.docs;
                                Map<String, dynamic>? avatarItem;
                                Map<String, dynamic>? bgItem;
                                Map<String, dynamic>? effectItem;

                                for (var doc in docs) {
                                  final data = doc.data();
                                  if (data['is_equipped'] == true) {
                                    final type = data['item_type'] ?? '';
                                    if (type == 'avatar') {
                                      avatarItem = data;
                                    } else if (type == 'background') {
                                      bgItem = data;
                                    } else if (type == 'effect') {
                                      effectItem = data;
                                    }
                                  }
                                }

                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildDisplaySlot(
                                      'Avatar',
                                      avatarItem,
                                      defaultName: 'Kinz Bawaan',
                                      defaultEmoji: 'kinz.png',
                                    ),
                                    _buildDisplaySlot(
                                      'Background',
                                      bgItem,
                                      defaultName: 'Default Theme',
                                      defaultEmoji: 'wallpaper',
                                    ),
                                    _buildDisplaySlot(
                                      'Effect',
                                      effectItem,
                                      defaultName: 'Tidak ada',
                                      defaultEmoji: 'auto_awesome',
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );

        return Scaffold(
          backgroundColor: themeConfig.hasGradientBg ? Colors.transparent : themeConfig.screenBgColorStart,
          body: themeConfig.hasGradientBg
              ? AnimatedGradientWrapper(
                  colors: [themeConfig.screenBgColorStart, themeConfig.screenBgColorEnd],
                  child: mainBody,
                )
              : Container(
                  color: themeConfig.screenBgColorStart,
                  child: mainBody,
                ),
        );
      },
    );
  }

  Widget _buildDisplaySlot(String label, Map<String, dynamic>? item, {required String defaultName, required String defaultEmoji}) {
    final name = item != null ? (item['item_name'] ?? defaultName) : defaultName;
    final emoji = item != null ? (item['item_image'] ?? defaultEmoji) : defaultEmoji;
    final rarity = item != null ? (item['rarity'] ?? 'common').toString().toLowerCase() : 'common';
    
    Color rarityColor = AppColors.rarityCommon;
    if (rarity == 'rare') rarityColor = AppColors.rarityRare;
    if (rarity == 'epic') rarityColor = AppColors.rarityEpic;
    if (rarity == 'legendary') rarityColor = AppColors.rarityLegendary;
    if (rarity == 'mythical') rarityColor = AppColors.rarityMythical;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: rarityColor.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: rarityColor.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: rarityColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: IconHandler.buildItemIcon(emoji, size: 30, color: rarityColor),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: rarityColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                rarity.toUpperCase(),
                style: TextStyle(
                  color: rarityColor,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final Widget child;
  final Color? color;
  final Color? borderColor;
  const _StatBox({required this.child, this.color, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? const Color(0xFFEAEAEA), width: 1.5),
      ),
      child: child,
    );
  }
}


