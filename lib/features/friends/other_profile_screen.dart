import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/firebase_service.dart';
import '../../core/widgets/ribbon_badge.dart';
import '../../core/theme/profile_theme.dart';
import '../../core/widgets/profile_effect.dart';

class OtherProfileScreen extends StatefulWidget {
  const OtherProfileScreen({super.key});

  @override
  State<OtherProfileScreen> createState() => _OtherProfileScreenState();
}

class _OtherProfileScreenState extends State<OtherProfileScreen> {
  final _firebase = FirebaseService();
  bool _isProcessing = false;

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final targetUid = ModalRoute.of(context)!.settings.arguments as String? ?? '';
    final myUid = _firebase.currentUser?.uid;

    if (targetUid.isEmpty || myUid == null) {
      return Scaffold(
        appBar: AppBar(elevation: 0),
        body: const Center(child: Text('Pengguna tidak ditemukan')),
      );
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _firebase.getUserProfile(targetUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary))),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(elevation: 0),
            body: const Center(child: Text('Gagal memuat profil pengguna')),
          );
        }

        final userData = snapshot.data!;
        final name = userData['name'] ?? 'Pelajar';
        final school = userData['school_name'] ?? 'Sekolah';
        final grade = userData['grade'] ?? '-';
        final level = userData['level'] ?? 1;
        final xp = userData['xp'] ?? 0;
        final totalDuels = userData['total_duels'] ?? 0;
        final winRate = (((userData['win_rate'] ?? 0.0) as num) * 100).toInt();
        final streak = userData['streak'] ?? 0;
        final gems = userData['gems'] ?? 0;
        final avatar = userData['avatar_url'] ?? '🧑';
        final joinedAt = userData['created_at'];

        String joinedText = 'April 2026';
        if (joinedAt is Timestamp) {
          final dt = joinedAt.toDate();
          final months = [
            'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
            'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
          ];
          joinedText = '${months[dt.month - 1]} ${dt.year}';
        }

        final themeId = userData['theme_id'] as String?;
        final effectId = userData['effect_id'] as String?;
        final themeConfig = ProfileThemeConfig.fromId(themeId, name);

        final relativeXp = xp % 1000;
        final xpRemaining = 1000 - relativeXp;

        return Scaffold(
          backgroundColor: themeConfig.hasGradientBg ? null : themeConfig.screenBgColorStart,
          body: Container(
            decoration: themeConfig.hasGradientBg
                ? BoxDecoration(
                    gradient: LinearGradient(
                      colors: [themeConfig.screenBgColorStart, themeConfig.screenBgColorEnd],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  )
                : null,
            child: Stack(
              children: [
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

                // Active profile effect visual overlay
                if (effectId != null)
                  Positioned.fill(
                    child: ProfileEffectWidget(effectId: effectId),
                  ),

                // Main CustomScrollView
                CustomScrollView(
                  slivers: [
                    // Header Back button
                    SliverToBoxAdapter(
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 20, 4),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.arrow_back_rounded, color: themeConfig.hasGradientBg ? Colors.white : AppColors.textPrimary),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Profile',
                                style: AppTextStyles.h1.copyWith(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: themeConfig.hasGradientBg ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Profile Card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: themeConfig.cardColor,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: themeConfig.hasGradientBg ? 0.15 : 0.04),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Mascot character if theme requires it
                              if (themeConfig.showMascot)
                                Positioned(
                                  right: 0,
                                  top: 50,
                                  child: Image.asset(
                                    'assets/images/mascot.png',
                                    width: 95,
                                    height: 95,
                                    fit: BoxFit.contain,
                                  ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                                ),

                              // Main Card Content Column
                              Padding(
                                padding: const EdgeInsets.all(24),
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
                                color: themeConfig.id == 'crimson_spark'
                                    ? const Color(0xFFD32F2F)
                                    : const Color(0xFFFFECEF), // Soft pink matching profile illustration bg
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary, width: 3),
                              ),
                              child: Center(
                                child: Text(avatar, style: const TextStyle(fontSize: 50)),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Stack(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFFC107), // Yellow bell background
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 16),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
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
                                  )
                                ],
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
                          future: _firebase.getFriendsCount(targetUid),
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
                        const SizedBox(height: 20),

                        // Action Buttons row (Tambahkan Teman + Red Flag)
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(myUid)
                              .collection('friends')
                              .doc(targetUid)
                              .snapshots(),
                          builder: (context, friendSnapshot) {
                            final isFriend = friendSnapshot.hasData && friendSnapshot.data!.exists;

                            return StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(targetUid)
                                  .collection('friend_requests')
                                  .doc(myUid)
                                  .snapshots(),
                              builder: (context, requestSnapshot) {
                                final hasSentRequest = requestSnapshot.hasData && requestSnapshot.data!.exists;

                                return Row(
                                  children: [
                                    Expanded(
                                      child: isFriend
                                          ? TextButton(
                                              onPressed: _isProcessing
                                                  ? null
                                                  : () async {
                                                      setState(() => _isProcessing = true);
                                                      try {
                                                        await _firebase.removeFriend(targetUid);
                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(
                                                              content: Text('Teman berhasil dihapus'),
                                                              behavior: SnackBarBehavior.floating,
                                                            ),
                                                          );
                                                        }
                                                      } catch (e) {
                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text('Gagal menghapus teman: $e'),
                                                              behavior: SnackBarBehavior.floating,
                                                            ),
                                                          );
                                                        }
                                                      } finally {
                                                        if (mounted) setState(() => _isProcessing = false);
                                                      }
                                                    },
                                              style: TextButton.styleFrom(
                                                backgroundColor: Colors.white,
                                                side: const BorderSide(color: AppColors.border, width: 1.5),
                                                padding: const EdgeInsets.symmetric(vertical: 14),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                              ),
                                              child: Text(
                                                'Hapus Teman',
                                                style: AppTextStyles.label.copyWith(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            )
                                          : hasSentRequest
                                              ? TextButton(
                                                  onPressed: null,
                                                  style: TextButton.styleFrom(
                                                    backgroundColor: const Color(0xFFF5F5F5),
                                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(16),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Permintaan Dikirim',
                                                    style: AppTextStyles.label.copyWith(
                                                      color: AppColors.textHint,
                                                      fontWeight: FontWeight.w900,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                )
                                              : TextButton(
                                                  onPressed: _isProcessing
                                                      ? null
                                                      : () async {
                                                          setState(() => _isProcessing = true);
                                                          try {
                                                            await _firebase.sendFriendRequest(targetUid);
                                                            if (context.mounted) {
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                SnackBar(
                                                                  content: Text('Permintaan teman dikirim ke $name!'),
                                                                  behavior: SnackBarBehavior.floating,
                                                                  backgroundColor: AppColors.success,
                                                                ),
                                                              );
                                                            }
                                                          } catch (e) {
                                                            if (context.mounted) {
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                SnackBar(
                                                                  content: Text('Gagal mengirim permintaan: $e'),
                                                                  behavior: SnackBarBehavior.floating,
                                                                ),
                                                              );
                                                            }
                                                          } finally {
                                                            if (mounted) setState(() => _isProcessing = false);
                                                          }
                                                        },
                                                  style: TextButton.styleFrom(
                                                    backgroundColor: const Color(0xFF52B788), // Green matching mockup
                                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(16),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Tambahkan Teman',
                                                    style: AppTextStyles.label.copyWith(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w900,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Red Flag Icon Button
                                    GestureDetector(
                                      onTap: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Pemain berhasil dilaporkan.'),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFECEF),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: const Color(0xFFFFD1D8), width: 1.5),
                                        ),
                                        child: const Icon(
                                          Icons.flag_rounded,
                                          color: AppColors.primary,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Statistik Title
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Statistik',
                            style: AppTextStyles.h3.copyWith(
                              fontWeight: FontWeight.w800,
                              color: themeConfig.hasGradientBg ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Stats Grid (6 items)
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
                                    '$gems Poin',
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      color: const Color(0xFFE55B5B),
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
                                      const Text(
                                        '🔥',
                                        style: TextStyle(fontSize: 15),
                                      ),
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
                                      color: themeConfig.bodyTextColor,
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
                                      color: themeConfig.bodyTextColor,
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
                                    '12',
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
                                      color: themeConfig.bodyTextColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
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
              ),
            ),
          ),
        ),

              // Badges Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: themeConfig.cardColor,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: themeConfig.hasGradientBg ? 0.15 : 0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
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
                          stream: FirebaseService().getUserBadges(targetUid),
                          builder: (context, badgeSnapshot) {
                            if (!badgeSnapshot.hasData) {
                              return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary)));
                            }

                            final badgeDocs = badgeSnapshot.data!.docs;
                            final earnedBadges = badgeDocs.map((doc) => doc.data()['badge_id'] as String).toSet();
                            final allDefinitions = FirebaseService().getAllBadgeDefinitions();
                            final displayBadges = allDefinitions.take(3).toList();

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
                                              color: themeConfig.hasGradientBg ? Colors.white70 : AppColors.textPrimary,
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
                                        arguments: targetUid,
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
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
},
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
