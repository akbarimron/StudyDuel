import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/profile_theme.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/firebase_service.dart';
import '../../core/widgets/ribbon_badge.dart';

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
        final tickets = userData['tickets'] ?? 0;
        final avatar = userData['avatar_url'] ?? '🧑';
        final joinedAt = userData['created_at'];

        final themeId = userData['theme_id'] as String?;
        final effectId = userData['effect_id'] as String?;
        final themeConfig = ProfileThemeConfig.fromId(themeId, name);

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

                // Main CustomScrollView
                CustomScrollView(
                  slivers: [
                    // Header title
                    SliverToBoxAdapter(
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Profile',
                                style: AppTextStyles.h1.copyWith(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: themeConfig.hasGradientBg ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.settings_outlined, color: themeConfig.hasGradientBg ? Colors.white : AppColors.textPrimary),
                                onPressed: () {
                                  Navigator.pushNamed(context, AppRoutes.settings);
                                },
                              ),
                            ],
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
                              Positioned.fill(
                                child: ProfileEffectOverlay(effectId: effectId),
                              ),
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
                                            color: const Color(0xFFFFB703).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFB703), size: 12),
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

                              // Edit Pencil
                              Positioned(
                                top: 20,
                                right: 20,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(context, AppRoutes.settings);
                                  },
                                  child: Icon(
                                    Icons.edit_rounded,
                                    color: themeConfig.hasGradientBg ? Colors.white70 : AppColors.textSecondary,
                                    size: 20,
                                  ),
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
                        
                        // Edit profile button row
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, AppRoutes.settings);
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFF52B788), // Green matching mockup
                                  padding: const EdgeInsets.symmetric(vertical: 14),
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
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, AppRoutes.settings);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
                                ),
                                child: const Icon(
                                  Icons.settings_rounded,
                                  color: AppColors.textSecondary,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
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
                                      color: AppColors.textPrimary,
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
                                      color: const Color(0xFFE55B5B), // Coral/red
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
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Win rate',
                                    style: AppTextStyles.caption.copyWith(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
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
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Total Duel',
                                    style: AppTextStyles.caption.copyWith(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
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
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Rank',
                                    style: AppTextStyles.caption.copyWith(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
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
                          stream: FirebaseService().getUserBadges(uid),
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

class ProfileEffectOverlay extends StatefulWidget {
  final String? effectId;
  const ProfileEffectOverlay({super.key, this.effectId});

  @override
  State<ProfileEffectOverlay> createState() => _ProfileEffectOverlayState();
}

class _ProfileEffectOverlayState extends State<ProfileEffectOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(_updateParticles);
    
    if (widget.effectId != null && widget.effectId!.isNotEmpty) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ProfileEffectOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.effectId != oldWidget.effectId) {
      _particles.clear();
      if (widget.effectId != null && widget.effectId!.isNotEmpty) {
        if (!_controller.isAnimating) {
          _controller.repeat();
        }
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateParticles() {
    if (!mounted || widget.effectId == null || widget.effectId!.isEmpty) return;

    double spawnChance = 0.08;
    if (widget.effectId == 'matrix_effect') spawnChance = 0.15;
    
    if (_rand.nextDouble() < spawnChance && _particles.length < 25) {
      _particles.add(_Particle.generate(widget.effectId!, _rand));
    }

    setState(() {
      for (var p in _particles) {
        p.update();
      }
      _particles.removeWhere((p) => p.isDead);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.effectId == null || widget.effectId!.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        for (var p in _particles) {
          p.setBounds(constraints.maxWidth, constraints.maxHeight);
        }

        return Stack(
          children: _particles.map((p) {
            return Positioned(
              left: p.x,
              top: p.y,
              child: Opacity(
                opacity: p.opacity,
                child: Transform.rotate(
                  angle: p.angle,
                  child: Text(
                    p.char,
                    style: TextStyle(
                      fontSize: p.size,
                      color: p.color,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _Particle {
  final String effectId;
  final Random rand;
  
  double x = 0;
  double y = 0;
  double vx = 0;
  double vy = 0;
  double size = 12;
  double opacity = 1.0;
  double fadeSpeed = 0.015;
  double angle = 0;
  double rotationSpeed = 0;
  String char = '';
  Color? color;

  bool _initialized = false;
  double _height = 100;

  _Particle.generate(this.effectId, this.rand) {
    if (effectId == 'fire_effect') {
      char = '🔥';
      size = 14 + rand.nextDouble() * 12;
      vy = -1.2 - rand.nextDouble() * 1.5;
      vx = -0.3 + rand.nextDouble() * 0.6;
      fadeSpeed = 0.01 + rand.nextDouble() * 0.01;
      rotationSpeed = -0.05 + rand.nextDouble() * 0.1;
    } else if (effectId == 'star_effect') {
      char = rand.nextBool() ? '✨' : '⭐';
      size = 12 + rand.nextDouble() * 14;
      vy = -0.3 - rand.nextDouble() * 0.5;
      vx = -0.4 + rand.nextDouble() * 0.8;
      fadeSpeed = 0.008 + rand.nextDouble() * 0.01;
      rotationSpeed = 0.05 + rand.nextDouble() * 0.05;
    } else if (effectId == 'bubble_effect') {
      char = '🫧';
      size = 10 + rand.nextDouble() * 16;
      vy = -0.8 - rand.nextDouble() * 1.2;
      vx = -0.5 + rand.nextDouble() * 1.0;
      fadeSpeed = 0.006 + rand.nextDouble() * 0.008;
    } else if (effectId == 'sakura_effect') {
      char = '🌸';
      size = 12 + rand.nextDouble() * 14;
      vy = 0.8 + rand.nextDouble() * 1.0;
      vx = -0.6 + rand.nextDouble() * 0.6;
      fadeSpeed = 0.006 + rand.nextDouble() * 0.008;
      rotationSpeed = -0.03 + rand.nextDouble() * 0.06;
    } else if (effectId == 'matrix_effect') {
      char = rand.nextBool() ? '0' : '1';
      size = 10 + rand.nextDouble() * 10;
      vy = 2.0 + rand.nextDouble() * 2.0;
      vx = 0;
      fadeSpeed = 0.015 + rand.nextDouble() * 0.01;
      color = const Color(0xFF00FF00);
    }
  }

  void setBounds(double width, double height) {
    if (_initialized) return;
    _height = height;
    _initialized = true;

    x = rand.nextDouble() * width;
    if (effectId == 'sakura_effect' || effectId == 'matrix_effect') {
      y = -20;
    } else {
      y = height + 10;
    }
  }

  void update() {
    x += vx;
    y += vy;
    angle += rotationSpeed;
    opacity = max(0, opacity - fadeSpeed);
    
    if (effectId == 'bubble_effect') {
      vx += sin(y / 15) * 0.05;
    }
  }

  bool get isDead => opacity <= 0.01 || y < -30 || y > _height + 30;
}
