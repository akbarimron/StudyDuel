import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/firebase_service.dart';
import '../../core/widgets/ribbon_badge.dart';

class BadgesListScreen extends StatelessWidget {
  const BadgesListScreen({super.key});

  Color _getBadgeColor(String id) {
    switch (id) {
      case 'top10':
        return const Color(0xFFE8DDF7); // Soft purple
      case 'win100':
        return const Color(0xFFFEF0D5); // Soft gold/yellow
      case 'ipa_expert':
        return const Color(0xFFDDE5F5); // Soft blue
      case 'math_master':
        return const Color(0xFFFDE4E4); // Soft red
      case 'social_star':
        return const Color(0xFFE2F4E2); // Soft green
      case 'pioneer':
        return const Color(0xFFE4F3F8); // Soft cyan
      default:
        return const Color(0xFFF1F1F1); // Soft grey
    }
  }

  Color _getBadgeBorderColor(String id) {
    switch (id) {
      case 'top10':
        return const Color(0xFF906CD4);
      case 'win100':
        return const Color(0xFFEAA62B);
      case 'ipa_expert':
        return const Color(0xFF5A87DE);
      case 'math_master':
        return const Color(0xFFDE5B5B);
      case 'social_star':
        return const Color(0xFF4FA84F);
      case 'pioneer':
        return const Color(0xFF2EA2C2);
      default:
        return const Color(0xFFBBBBBB);
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetUid = ModalRoute.of(context)!.settings.arguments as String? ?? '';
    final myUid = FirebaseService().currentUser?.uid;
    final uid = targetUid.isNotEmpty ? targetUid : (myUid ?? '');

    if (uid.isEmpty) {
      return Scaffold(
        appBar: AppBar(elevation: 0),
        body: const Center(child: Text('Pengguna tidak ditemukan')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        title: Text('Badges', style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseService().getUserBadges(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary)));
          }

          final badgeDocs = snapshot.data?.docs ?? [];
          final earnedBadges = badgeDocs.map((doc) => doc.data()['badge_id'] as String).toSet();
          final allDefinitions = FirebaseService().getAllBadgeDefinitions();

          return CustomScrollView(
            slivers: [
              // Header Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Badges', style: AppTextStyles.h1.copyWith(fontSize: 26, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 8),
                              Text(
                                'Kumpulkan badge dan tunjukan prestasimu',
                                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Character Mascot
                        Image.asset(
                          'assets/images/char/kinz.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.contain,
                        ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                      ],
                    ),
                  ),
                ),
              ),

              // Badges list
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final badge = allDefinitions[index];
                      final bId = badge['badge_id'] as String;
                      final earned = earnedBadges.contains(bId);
                      final softColor = _getBadgeColor(bId);
                      final borderColor = _getBadgeBorderColor(bId);

                      final docIndex = badgeDocs.indexWhere((doc) => doc.data()['badge_id'] == bId);
                      final bool isPinned = docIndex != -1 ? (badgeDocs[docIndex].data()['is_pinned'] == true) : false;
                      final isOwnProfile = uid == myUid;

                      Widget card = Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: earned ? softColor : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: earned ? borderColor.withValues(alpha: 0.3) : AppColors.border,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Badge icon
                            RibbonBadge(
                              type: bId,
                              earned: earned,
                              size: 64,
                            ),
                            const SizedBox(width: 16),
                            // Badge details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          badge['badge_name'] as String,
                                          style: AppTextStyles.h3.copyWith(
                                            fontSize: 16,
                                            color: earned ? AppColors.textPrimary : AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      if (!earned)
                                        const Icon(Icons.lock_rounded, color: AppColors.textHint, size: 16)
                                      else if (isOwnProfile)
                                        Icon(
                                          isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                                          color: isPinned ? AppColors.primary : AppColors.textHint,
                                          size: 18,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    badge['description'] as String,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: earned ? AppColors.textSecondary : AppColors.textHint,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );

                      if (earned && isOwnProfile) {
                        card = GestureDetector(
                          onTap: () async {
                            try {
                              await FirebaseService().toggleBadgePin(uid, bId, !isPinned);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString().replaceAll('Exception: ', '')),
                                    backgroundColor: const Color(0xFFFF4757),
                                  ),
                                );
                              }
                            }
                          },
                          child: card,
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: card,
                      ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideY(begin: 0.1, delay: Duration(milliseconds: 50 * index));
                    },
                    childCount: allDefinitions.length,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }
}
