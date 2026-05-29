import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/firebase_service.dart';

class DuelLobbyScreen extends StatefulWidget {
  const DuelLobbyScreen({super.key});

  @override
  State<DuelLobbyScreen> createState() => _DuelLobbyScreenState();
}

class _DuelLobbyScreenState extends State<DuelLobbyScreen> {
  int _selectedMode = 0; // 0=1v1, 1=2v2, 2=Offline
  int _selectedSubject = 0;
  int _selectedClass = 0; // 0=Kelas 7, 1=Kelas 8, 2=Kelas 9
  int _selectedDiff = 1; // 0=Mudah, 1=Sedang, 2=Sulit

  final _modes = ['1 vs 1', '2 vs 2', 'Offline'];
  final _subjects = ['Matematika', 'IPA', 'IPS', 'Bahasa Indonesia', 'Bahasa'];
  final _classes = ['Kelas 7', 'Kelas 8', 'Kelas 9'];
  final _difficulties = ['Mudah', 'Sedang', 'Sulit'];
  final _diffColors = [AppColors.success, AppColors.accentDark, AppColors.error];

  bool _searching = false;
  String _searchPhase = 'searching'; // 'searching' or 'found'
  Map<String, dynamic>? _opponentData;

  StreamSubscription? _matchSubscription;
  Timer? _botTimer;

  @override
  void dispose() {
    _matchSubscription?.cancel();
    _botTimer?.cancel();
    super.dispose();
  }

  void _startSearch() async {
    setState(() {
      _searching = true;
      _searchPhase = 'searching';
      _opponentData = null;
    });

    try {
      final myUid = FirebaseService().currentUser?.uid;
      if (myUid == null) {
        throw Exception('Pengguna belum masuk!');
      }

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(myUid).get();
      final myName = userDoc.data()?['name'] ?? 'Pelajar';

      final rawSubject = _subjects[_selectedSubject];
      // Normalize subject to lower case to match seeded question pool
      String normalizedSubject = rawSubject.toLowerCase();

      final diff = _difficulties[_selectedDiff];
      String normalizedDiff = diff.toLowerCase(); // mudah | sedang | sulit

      // Matchmake call
      final sessionId = await FirebaseService().matchmake(
        subject: normalizedSubject,
        difficulty: normalizedDiff,
        myName: myName,
      );

      // Listen to the session stream
      _matchSubscription?.cancel();
      _matchSubscription = FirebaseService().getDuelStream(sessionId).listen((snapshot) async {
        if (!snapshot.exists) return;
        final data = snapshot.data()!;
        final p1Id = data['player1_id'] as String;
        final p2Id = data['player2_id'] as String;

        // When player2 has joined, trigger Phase B (found)
        if (p2Id.isNotEmpty && _searchPhase == 'searching') {
          _botTimer?.cancel();

          final isP1 = (myUid == p1Id);
          final oppId = isP1 ? p2Id : p1Id;
          final oppName = isP1 ? data['player2_name'] : data['player1_name'];
          final oppMmr = isP1 ? data['player2_mmr'] : data['player1_mmr'];

          Map<String, dynamic> oppProfile = {
            'name': oppName,
            'avatar_url': '🧑',
            'level': 1,
            'school_name': 'SMP Negeri 1 Jakarta',
            'mmr': oppMmr,
          };

          if (oppId == 'bot_id') {
            oppProfile['avatar_url'] = '🤖';
            oppProfile['level'] = 5;
            oppProfile['school_name'] = 'Sekolah Bot Pintar';
          } else {
            final profile = await FirebaseService().getUserProfile(oppId);
            if (profile != null) {
              oppProfile['avatar_url'] = profile['avatar_url'] ?? '🧑';
              oppProfile['level'] = profile['level'] ?? 1;
              oppProfile['school_name'] = profile['school_name'] ?? 'SMP Negeri 1 Jakarta';
            }
          }

          if (mounted) {
            setState(() {
              _searchPhase = 'found';
              _opponentData = oppProfile;
            });

            // Delay 1.5 seconds then navigate
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted) {
                setState(() {
                  _searching = false;
                });
                Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.battle,
                  arguments: {
                    'sessionId': sessionId,
                    'isPlayer1': isP1,
                  },
                );
              }
            });
          }
        }
      });

      // Handle matchmaking style
      if (_selectedMode == 2) {
        // Offline Mode: Immediately start bot match
        await FirebaseService().startBotMatch(sessionId);
      } else {
        // Online Mode: AI/Bot countdown (6 seconds)
        _botTimer?.cancel();
        _botTimer = Timer(const Duration(seconds: 6), () async {
          final doc = await FirebaseFirestore.instance.collection('duel_sessions').doc(sessionId).get();
          if (doc.exists) {
            final data = doc.data()!;
            if ((data['player2_id'] as String).isEmpty) {
              await FirebaseService().startBotMatch(sessionId);
            }
          }
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() => _searching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error matchmaking: $e')),
        );
      }
    }
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

        return Scaffold(
          backgroundColor: _searching ? const Color(0xFF1F1F2E) : AppColors.background,
          appBar: _searching
              ? null
              : AppBar(
                  backgroundColor: AppColors.surface,
                  elevation: 0,
                  title: Text('Lobi Duel', style: AppTextStyles.h2.copyWith(fontSize: 20, fontWeight: FontWeight.w900)),
                  centerTitle: false,
                ),
          body: _searching
              ? _SearchingView(
                  userData: userData,
                  phase: _searchPhase,
                  opponentData: _opponentData,
                )
              : _LobbyView(
                  selectedMode: _selectedMode,
                  selectedSubject: _selectedSubject,
                  selectedClass: _selectedClass,
                  selectedDiff: _selectedDiff,
                  modes: _modes,
                  subjects: _subjects,
                  classes: _classes,
                  difficulties: _difficulties,
                  diffColors: _diffColors,
                  uid: uid,
                  onModeTap: (i) => setState(() => _selectedMode = i),
                  onSubjectTap: (i) => setState(() => _selectedSubject = i),
                  onClassTap: (i) => setState(() => _selectedClass = i),
                  onDiffTap: (i) => setState(() => _selectedDiff = i),
                  onStart: _startSearch,
                ),
        );
      },
    );
  }
}

class _LobbyView extends StatelessWidget {
  final int selectedMode;
  final int selectedSubject;
  final int selectedClass;
  final int selectedDiff;
  final List<String> modes;
  final List<String> subjects;
  final List<String> classes;
  final List<String> difficulties;
  final List<Color> diffColors;
  final String uid;

  final ValueChanged<int> onModeTap;
  final ValueChanged<int> onSubjectTap;
  final ValueChanged<int> onClassTap;
  final ValueChanged<int> onDiffTap;
  final VoidCallback onStart;

  const _LobbyView({
    required this.selectedMode,
    required this.selectedSubject,
    required this.selectedClass,
    required this.selectedDiff,
    required this.modes,
    required this.subjects,
    required this.classes,
    required this.difficulties,
    required this.diffColors,
    required this.uid,
    required this.onModeTap,
    required this.onSubjectTap,
    required this.onClassTap,
    required this.onDiffTap,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mode Battle selection
          Text('Pilih Mode Battle', style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(modes.length, (i) {
              final isSelected = selectedMode == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onModeTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: i < modes.length - 1 ? 10 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : const Color(0xFFEAEAEA),
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          ['⚔️ 1 vs 1', '👥 2 vs 2', '🤖 Offline'][i],
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          // Subject Grid
          Text('Mata Pelajaran', style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(subjects.length, (i) {
              final isSelected = selectedSubject == i;
              final emoji = ['📐', '🔬', '🌍', '📚', '🇬🇧'][i];
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji),
                    const SizedBox(width: 6),
                    Text(subjects[i]),
                  ],
                ),
                labelStyle: AppTextStyles.label.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                selected: isSelected,
                onSelected: (_) => onSubjectTap(i),
                selectedColor: AppColors.primary,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : const Color(0xFFEAEAEA),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          // Class selection
          Text('Tingkatan Kelas', style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(classes.length, (i) {
              final isSelected = selectedClass == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onClassTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: i < classes.length - 1 ? 10 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : const Color(0xFFEAEAEA),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        classes[i],
                        style: AppTextStyles.label.copyWith(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          // Difficulty chips
          Text('Tingkatan Kesulitan', style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(difficulties.length, (i) {
              final isSelected = selectedDiff == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onDiffTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: i < difficulties.length - 1 ? 10 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? diffColors[i] : Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: diffColors[i],
                        width: isSelected ? 0 : 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        difficulties[i],
                        style: AppTextStyles.label.copyWith(
                          color: isSelected ? Colors.white : diffColors[i],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 36),

          // Red Mulai Duel Button
          GestureDetector(
            onTap: () {
              if (selectedMode == 1) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text('👥 Mode 2 vs 2'),
                    content: const Text('Mode 2 vs 2 akan segera hadir di update selanjutnya! Mari main Mode 1 vs 1 atau Offline.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('OK', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
                      ),
                    ],
                  ),
                );
              } else {
                onStart();
              }
            },
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(100),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFFB13D3D),
                    offset: Offset(0, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'MULAI DUEL ⚔️',
                  style: AppTextStyles.button.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 36),

          // Last Duel History Section
          Text('Duel Terakhir', style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          _buildHistoryList(uid),
        ],
      ),
    );
  }

  Widget _buildHistoryList(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseService().getDuelHistoryStream(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFEAEAEA)),
            ),
            child: Center(
              child: Text(
                'Belum ada riwayat duel. Mulai duel pertama Anda sekarang!',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final oppName = data['opponent_name'] ?? 'Lawan';
            final oppAvatar = data['opponent_avatar'] ?? '🧑';
            final subject = data['subject'] ?? 'Matematika';
            final result = data['result'] ?? 'draw';
            final xpEarned = data['xp_earned'] ?? 0;
            final gemsEarned = data['gems_earned'] ?? 0;

            final isWin = result == 'win';
            final isLose = result == 'lose';

            Color resultColor = Colors.grey;
            String resultText = 'DRAW';
            if (isWin) {
              resultColor = const Color(0xFF52B788);
              resultText = 'MENANG';
            } else if (isLose) {
              resultColor = AppColors.primary;
              resultText = 'KALAH';
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
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0F0F0),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(oppAvatar, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          oppName,
                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subject.toUpperCase(),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: resultColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          resultText,
                          style: AppTextStyles.caption.copyWith(
                            color: resultColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isWin
                            ? '+$xpEarned XP / +$gemsEarned Poin'
                            : isLose
                                ? '-10 MMR'
                                : '0 XP',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isWin ? const Color(0xFFEAA62B) : AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SearchingView extends StatelessWidget {
  final Map<String, dynamic> userData;
  final String phase;
  final Map<String, dynamic>? opponentData;

  const _SearchingView({
    required this.userData,
    required this.phase,
    this.opponentData,
  });

  @override
  Widget build(BuildContext context) {
    final String myName = userData['name'] ?? 'Pelajar';
    final String myAvatar = userData['avatar_url'] ?? '🧑';
    final int myLevel = userData['level'] ?? 1;
    final String mySchool = userData['school_name'] ?? 'SMP Negeri 1 Jakarta';
    final int myMmr = userData['mmr'] ?? 80;

    final isSearching = phase == 'searching';

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF1F1F2E),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Text(
            isSearching ? 'MENCARI LAWAN...' : 'LOBBY DISINKRONKAN!',
            style: AppTextStyles.h3.copyWith(
              color: Colors.white,
              letterSpacing: 2,
              fontWeight: FontWeight.w900,
            ),
          ).animate().fadeIn().scale(),
          const SizedBox(height: 8),
          Text(
            isSearching ? 'Menyelaraskan MMR ($myMmr)...' : 'Lawan ditemukan! Siapkan dirimu!',
            style: AppTextStyles.caption.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 50),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildFighterCard(
                          name: myName,
                          avatar: myAvatar,
                          level: myLevel,
                          school: mySchool,
                          mmr: myMmr,
                          isLeft: true,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: isSearching
                            ? _buildSearchingOpponentCard()
                            : _buildFighterCard(
                                name: opponentData?['name'] ?? 'Lawan',
                                avatar: opponentData?['avatar_url'] ?? '🧑',
                                level: opponentData?['level'] ?? 1,
                                school: opponentData?['school_name'] ?? 'SMP Negeri 1 Jakarta',
                                mmr: opponentData?['mmr'] ?? 0,
                                isLeft: false,
                              ),
                      ),
                    ],
                  ),
                  Transform.rotate(
                    angle: -0.15,
                    child: Container(
                      width: 8,
                      height: 320,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'VS',
                      style: AppTextStyles.h1.copyWith(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.1, 1.1),
                    duration: 800.ms,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 12,
                    child: isSearching
                        ? LinearProgressIndicator(
                            backgroundColor: Colors.white10,
                            valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
                          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1500.ms)
                        : const LinearProgressIndicator(
                            value: 1.0,
                            backgroundColor: Colors.white10,
                            valueColor: AlwaysStoppedAnimation(Colors.green),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isSearching ? 'Menghubungkan ke server duel...' : 'Lawan Ditemukan! Bersiaplah...',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSearching ? Colors.white54 : Colors.greenAccent,
                    fontWeight: isSearching ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildFighterCard({
    required String name,
    required String avatar,
    required int level,
    required String school,
    int mmr = 0,
    required bool isLeft,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLeft ? const Color(0xFF4EA8DE) : AppColors.primary,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isLeft ? const Color(0xFF4EA8DE) : AppColors.primary).withValues(alpha: 0.15),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned(
              right: isLeft ? null : -20,
              left: isLeft ? -20 : null,
              bottom: -20,
              child: Opacity(
                opacity: 0.05,
                child: Icon(
                  isLeft ? Icons.shield_rounded : Icons.bolt_rounded,
                  size: 150,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1F2E),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isLeft ? const Color(0xFF4EA8DE) : AppColors.primary,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(avatar, style: const TextStyle(fontSize: 40)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    school,
                    style: AppTextStyles.caption.copyWith(color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'LV $level',
                          style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFFFFC107),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (mmr > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '$mmr MMR',
                            style: AppTextStyles.caption.copyWith(
                              color: const Color(0xFF8A70FF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().slideX(
      begin: isLeft ? -0.2 : 0.2,
      duration: 400.ms,
      curve: Curves.easeOut,
    ).fadeIn(duration: 400.ms);
  }

  Widget _buildSearchingOpponentCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white12,
          width: 2,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1F1F2E),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('❓', style: TextStyle(fontSize: 40)),
                  ),
                ),
                ...List.generate(3, (index) {
                  return Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                  ).animate(onPlay: (c) => c.repeat()).scale(
                    begin: const Offset(1, 1),
                    end: const Offset(2.0, 2.0),
                    duration: 1500.ms,
                    delay: (index * 500).ms,
                    curve: Curves.easeOut,
                  ).fadeOut(duration: 1500.ms);
                }),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Mencari Lawan...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeOut(duration: 800.ms),
            const SizedBox(height: 4),
            Text(
              'Menyinkronkan MMR...',
              style: AppTextStyles.caption.copyWith(color: Colors.white30),
            ),
          ],
        ),
      ),
    );
  }
}
