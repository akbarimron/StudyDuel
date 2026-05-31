import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/firebase_service.dart';
import '../../core/constants/app_routes.dart';
import '../../core/utils/icon_handler.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _firebase = FirebaseService();
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  void _showAddFriendDialog() {
    showDialog(
      context: context,
      builder: (_) => const _AddFriendDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = _firebase.currentUser?.uid;

    if (myUid == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          'Friends',
          style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFriendDialog,
        backgroundColor: AppColors.success,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 26),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Search Bar ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Cari teman...',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, color: AppColors.textHint, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, duration: 300.ms),
            ),
          ),

          // ── Permintaan Pertemanan (Incoming Friend Requests) ──────────────
          SliverToBoxAdapter(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firebase.getFriendRequests(myUid),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.mail_rounded, color: AppColors.primary, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Text('Permintaan Pertemanan', style: AppTextStyles.h3),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              '${docs.length}',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
                      const SizedBox(height: 12),
                      ...List.generate(docs.length, (i) {
                        final data = docs[i].data();
                        final fromUid = data['from_uid'] as String? ?? '';
                        final fromName = data['from_name'] as String? ?? 'Pengguna';
                        final fromSchool = data['from_school'] as String? ?? '';
                        final fromAvatar = data['from_avatar'] as String? ?? 'kinz.png';
                        final sentAt = data['sent_at'];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _FriendRequestCard(
                            uid: fromUid,
                            name: fromName,
                            school: fromSchool,
                            avatar: fromAvatar,
                            timeAgo: _timeAgo(sentAt),
                            onAccept: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              await _firebase.acceptFriendRequest(fromUid);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('$fromName ditambahkan sebagai teman!'),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            },
                            onReject: () async {
                              await _firebase.rejectFriendRequest(fromUid);
                            },
                          ),
                        ).animate().fadeIn(
                              delay: Duration(milliseconds: 150 + (i * 80)),
                              duration: 300.ms,
                            ).slideX(begin: 0.05, delay: Duration(milliseconds: 150 + (i * 80)));
                      }),
                    ],
                  ),
                );
              },
            ),
          ),

          // ── Teman (Friends List) ──────────────────────────────────────
          SliverToBoxAdapter(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firebase.getFriendsList(myUid),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];

                // Filter friends by search query
                final filtered = _searchQuery.isEmpty
                    ? docs
                    : docs.where((doc) {
                        final name = (doc.data()['name'] as String? ?? '').toLowerCase();
                        return name.contains(_searchQuery);
                      }).toList();

                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.secondarySurface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.people_rounded, color: AppColors.secondary, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Text('Teman', style: AppTextStyles.h3),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              '${filtered.length}',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
                      const SizedBox(height: 12),
                      if (!snapshot.hasData)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(AppColors.primary),
                            ),
                          ),
                        )
                      else if (filtered.isEmpty)
                        _EmptyFriendsState(hasSearch: _searchQuery.isNotEmpty)
                      else
                        ...List.generate(filtered.length, (i) {
                          final friendUid = filtered[i].id;
                          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            stream: _firebase.getUserStream(friendUid),
                            builder: (context, friendSnapshot) {
                              if (!friendSnapshot.hasData) {
                                return const SizedBox(
                                  height: 80,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(AppColors.primary),
                                    ),
                                  ),
                                );
                              }
                              final friendData = friendSnapshot.data!.data() ?? {};
                              final name = friendData['name'] as String? ?? 'Pelajar';
                              final avatar = friendData['avatar_url'] as String? ?? 'kinz.png';
                              final level = friendData['level'] as int? ?? 1;
                              final mmr = friendData['mmr'] as int? ?? 80;
                              final isOnline = friendData['is_online'] as bool? ?? false;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _FriendCard(
                                  uid: friendUid,
                                  name: name,
                                  avatar: avatar,
                                  level: level,
                                  mmr: mmr,
                                  isOnline: isOnline,
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/other-profile',
                                      arguments: friendUid,
                                    );
                                  },
                                  onDuel: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/duel/lobby',
                                      arguments: {'challengeUid': friendUid, 'challengeName': name},
                                    );
                                  },
                                  onChat: () {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.chat,
                                      arguments: {
                                        'friendUid': friendUid,
                                        'friendName': name,
                                        'friendAvatar': avatar,
                                        'isOnline': isOnline,
                                      },
                                    );
                                  },
                                ),
                              );
                            },
                          ).animate().fadeIn(
                                delay: Duration(milliseconds: 250 + (i * 60)),
                                duration: 300.ms,
                              ).slideX(
                                begin: 0.04,
                                delay: Duration(milliseconds: 250 + (i * 60)),
                              );
                        }),
                    ],
                  ),
                );
              },
            ),
          ),

          // Bottom spacing
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ─── Friend Request Card ──────────────────────────────────────────────────────

class _FriendRequestCard extends StatelessWidget {
  final String uid;
  final String name;
  final String school;
  final String avatar;
  final String timeAgo;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _FriendRequestCard({
    required this.uid,
    required this.name,
    required this.school,
    required this.avatar,
    required this.timeAgo,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: ClipOval(
                child: Center(
                  child: IconHandler.buildItemIcon(avatar, size: 36, color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.bodyLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (school.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      school,
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (timeAgo.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      timeAgo,
                      style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Accept button
            _CircleActionButton(
              icon: Icons.check_rounded,
              color: AppColors.success,
              onTap: onAccept,
            ),
            const SizedBox(width: 8),
            // Reject button
            _CircleActionButton(
              icon: Icons.close_rounded,
              color: AppColors.error,
              onTap: onReject,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Circle Action Button (Accept / Reject) ─────────────────────────────────

class _CircleActionButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CircleActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_CircleActionButton> createState() => _CircleActionButtonState();
}

class _CircleActionButtonState extends State<_CircleActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _pressed ? widget.color : widget.color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.icon,
            color: _pressed ? Colors.white : widget.color,
            size: 22,
          ),
        ),
      ),
    );
  }
}

// ─── Friend Card ──────────────────────────────────────────────────────────────

class _FriendCard extends StatelessWidget {
  final String uid;
  final String name;
  final String avatar;
  final int level;
  final int mmr;
  final bool isOnline;
  final VoidCallback onTap;
  final VoidCallback onDuel;
  final VoidCallback onChat;

  const _FriendCard({
    required this.uid,
    required this.name,
    required this.avatar,
    required this.level,
    required this.mmr,
    required this.isOnline,
    required this.onTap,
    required this.onDuel,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isOnline ? AppColors.success : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: IconHandler.buildItemIcon(avatar, size: 32, color: AppColors.primary),
                  ),
                ),
                if (isOnline)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: AppTextStyles.bodyLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isOnline) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.successSurface,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            'Online',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.accentSurface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Lv.$level',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.accentDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '•',
                        style: TextStyle(color: AppColors.textHint, fontSize: 10),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$mmr MMR',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Chat button
            GestureDetector(
              onTap: onChat,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Duel button
            GestureDetector(
              onTap: onDuel,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    const BoxShadow(
                      color: AppColors.primaryDark,
                      offset: Offset(0, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Text(
                  'Duel',
                  style: AppTextStyles.label.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty Friends State ────────────────────────────────────────────────────

class _EmptyFriendsState extends StatelessWidget {
  final bool hasSearch;

  const _EmptyFriendsState({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              hasSearch ? Icons.search_off_rounded : Icons.person_add_rounded,
              size: 54,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 12),
            Text(
              hasSearch ? 'Tidak ditemukan' : 'Belum ada teman',
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              hasSearch
                  ? 'Coba kata kunci lain'
                  : 'Tambahkan teman untuk mulai duel!',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ─── Add Friend Dialog ──────────────────────────────────────────────────────

class _AddFriendDialog extends StatefulWidget {
  const _AddFriendDialog();

  @override
  State<_AddFriendDialog> createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends State<_AddFriendDialog> {
  final _firebase = FirebaseService();
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  String _lastQuery = '';
  final Set<String> _sentRequests = {};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = [];
        _lastQuery = '';
        _isLoading = false;
      });
      return;
    }
    if (trimmed == _lastQuery) return;

    _lastQuery = trimmed;
    setState(() => _isLoading = true);

    try {
      final results = await _firebase.searchUsers(trimmed);
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendRequest(String targetUid, String targetName) async {
    try {
      await _firebase.sendFriendRequest(targetUid);
      if (mounted) {
        setState(() => _sentRequests.add(targetUid));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Permintaan dikirim ke $targetName!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim permintaan: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = _firebase.currentUser?.uid ?? '';

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.successSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person_add_rounded, color: AppColors.success, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tambah Teman',
                      style: AppTextStyles.h3,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.borderLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search field
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _controller,
                  onChanged: _search,
                  style: AppTextStyles.bodyLarge,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _search,
                  decoration: InputDecoration(
                    hintText: 'Cari username atau nama...',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint, size: 22),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 22),
                      onPressed: () => _search(_controller.text),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Results
              Flexible(
                child: _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(AppColors.primary),
                          ),
                        ),
                      )
                    : _results.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.person_search_rounded, size: 48, color: AppColors.textHint),
                                  const SizedBox(height: 12),
                                  Text(
                                    _lastQuery.isEmpty
                                        ? 'Ketik nama untuk mencari'
                                        : 'Tidak ditemukan',
                                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: _results.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderLight),
                            itemBuilder: (_, i) {
                              final user = _results[i];
                              final uid = user['user_id'] as String? ?? '';
                              final name = user['name'] as String? ?? 'Pengguna';
                              final username = user['username'] as String? ?? '';
                              final avatar = user['avatar_url'] as String? ?? 'kinz.png';
                              final school = user['school_name'] as String? ?? '';
                              final level = user['level'] as int? ?? 1;
                              final isMe = uid == myUid;
                              final alreadySent = _sentRequests.contains(uid);

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.borderLight,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Center(
                                        child: IconHandler.buildItemIcon(avatar, size: 28, color: AppColors.primary),
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
                                                  name,
                                                  style: AppTextStyles.bodyLarge,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isMe) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primarySurface,
                                                    borderRadius: BorderRadius.circular(100),
                                                  ),
                                                  child: Text(
                                                    'Kamu',
                                                    style: AppTextStyles.caption.copyWith(
                                                      color: AppColors.primary,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            [
                                              if (username.isNotEmpty) '@$username',
                                              if (school.isNotEmpty) school,
                                              'Lv.$level',
                                            ].join(' • '),
                                            style: AppTextStyles.bodySmall,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (!isMe)
                                      GestureDetector(
                                        onTap: alreadySent
                                            ? null
                                            : () => _sendRequest(uid, name),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: alreadySent ? AppColors.borderLight : AppColors.success,
                                            borderRadius: BorderRadius.circular(100),
                                            boxShadow: alreadySent
                                                ? null
                                                : [
                                                    const BoxShadow(
                                                      color: AppColors.successDark,
                                                      offset: Offset(0, 2),
                                                      blurRadius: 0,
                                                    ),
                                                  ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                alreadySent ? Icons.check_rounded : Icons.person_add_rounded,
                                                color: alreadySent ? AppColors.textHint : Colors.white,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                alreadySent ? 'Terkirim' : 'Tambah',
                                                style: AppTextStyles.label.copyWith(
                                                  color: alreadySent ? AppColors.textHint : Colors.white,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ).animate().fadeIn(
                                    delay: Duration(milliseconds: 50 * i),
                                    duration: 250.ms,
                                  );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    ).animate().scale(
          begin: const Offset(0.9, 0.9),
          duration: 250.ms,
          curve: Curves.easeOutBack,
        ).fadeIn(duration: 200.ms);
  }
}
