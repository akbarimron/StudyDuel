import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/firebase_service.dart';
import '../../core/utils/icon_handler.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _calculating = true;
  String _result = 'draw';
  int _xpReward = 0;
  int _gemsReward = 0;
  late int _myScore;
  late int _oppScore;
  String _myAvatar = 'kinz.png';
  String _oppAvatar = 'kinz.png';
  late String _sessionId;
  late List<Map<String, dynamic>> _questions;
  late List<int?> _userAnswers;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _sessionId = args['sessionId'] as String;
      _myScore = args['myScore'] as int;
      _oppScore = args['oppScore'] as int;
      _myAvatar = args['myAvatar'] as String? ?? 'kinz.png';
      _oppAvatar = args['oppAvatar'] as String? ?? 'kinz.png';
      _questions = List<Map<String, dynamic>>.from(args['questions'] ?? []);
      _userAnswers = List<int?>.from(args['userAnswers'] ?? []);
      _initialized = true;
      _calculateRewards();
    }
  }

  void _calculateRewards() async {
    final myUid = FirebaseService().currentUser?.uid;
    if (myUid != null) {
      final rewards = await FirebaseService().finishDuel(_sessionId, myUid);
      if (mounted) {
        setState(() {
          _xpReward = rewards['xp'] as int;
          _gemsReward = rewards['gems'] as int;
          _result = rewards['result'] as String;
          _calculating = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _calculating = false);
      }
    }
  }

  int get _mmrChange {
    if (_result == 'win') {
      return (30 + (_myScore ~/ 20)).clamp(30, 40);
    } else if (_result == 'lose') {
      return (-15 + (_myScore ~/ 20)).clamp(-15, -10);
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_calculating) {
      return const Scaffold(
        backgroundColor: Color(0xFF1F1F2E),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white)),
              SizedBox(height: 16),
              Text(
                'Menghitung Hasil Pertandingan...',
                style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    final win = _result == 'win';
    final draw = _result == 'draw';

    final Color bgColorStart = win
        ? const Color(0xFF1B4332) // deep emerald green
        : draw
            ? const Color(0xFF2B2D42) // slate blue
            : const Color(0xFF590D22); // crimson red

    final Color bgColorEnd = win
        ? const Color(0xFF2D6A4F)
        : draw
            ? const Color(0xFF1F1F2E)
            : const Color(0xFF800F2F);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bgColorStart, bgColorEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                // Top Exit Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 40),
                    Text(
                      'HASIL DUEL',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white60,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 28),
                      onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
                    ),
                  ],
                ),
                const Spacer(),

                // Big Outcome Text
                Text(
                  win ? 'KAMU MENANG!' : draw ? 'HASIL SERI' : 'KAMU KALAH',
                  style: AppTextStyles.display.copyWith(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
                const SizedBox(height: 8),
                Text(
                  win
                      ? 'Luar biasa! Pertahananmu tak tertembus.'
                      : draw
                          ? 'Sama kuat! Duel sengit yang seimbang.'
                          : 'Jangan menyerah! Belajar lagi bersama AI.',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),

                if (win) ...[
                  const SizedBox(height: 24),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.amber.withValues(alpha: 0.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.4),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.emoji_events_rounded, size: 54, color: Color(0xFFFFD700))
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scale(duration: 800.ms, begin: const Offset(0.9, 0.9), end: const Offset(1.15, 1.15), curve: Curves.easeInOut)
                              .rotate(duration: 1000.ms, begin: -0.05, end: 0.05, curve: Curves.easeInOut),
                          const SizedBox(width: 8),
                          const Icon(Icons.redeem_rounded, size: 48, color: Color(0xFFFF8E3C))
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scale(duration: 800.ms, delay: 200.ms, begin: const Offset(0.9, 0.9), end: const Offset(1.15, 1.15), curve: Curves.easeInOut)
                              .rotate(duration: 1000.ms, delay: 200.ms, begin: 0.05, end: -0.05, curve: Curves.easeInOut),
                        ],
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 48),

                // Big Score Display
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        IconHandler.buildItemIcon(_myAvatar, size: 50, color: Colors.white),
                        const SizedBox(height: 8),
                        Text(
                          'Kamu',
                          style: AppTextStyles.label.copyWith(color: Colors.white70, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_myScore',
                          style: AppTextStyles.display.copyWith(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'VS',
                        style: AppTextStyles.h1.copyWith(
                          color: Colors.white30,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        IconHandler.buildItemIcon(_oppAvatar, size: 50, color: Colors.white),
                        const SizedBox(height: 8),
                        Text(
                          'Lawan',
                          style: AppTextStyles.label.copyWith(color: Colors.white70, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_oppScore',
                          style: AppTextStyles.display.copyWith(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ).animate().slideY(begin: 0.1, duration: 400.ms),

                const SizedBox(height: 48),

                // Reward chip overlays
                if (!win && !draw) ...[
                  // For lose, show MMR change
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.trending_down_rounded, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '$_mmrChange MMR',
                          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ] else if (win) ...[
                  // For win, show rewards
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt_rounded, color: Colors.orange, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              '+$_xpReward XP',
                              style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/diamond.png',
                              width: 16,
                              height: 16,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '+$_gemsReward Poin',
                              style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.trending_up_rounded, color: Colors.greenAccent, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '+$_mmrChange MMR',
                              style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],

                const Spacer(),

                // Lihat Review Button (Single prominent white button)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    minimumSize: const Size(double.infinity, 54),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.duelReview,
                      arguments: {
                        'questions': _questions,
                        'userAnswers': _userAnswers,
                      },
                    );
                  },
                  child: Text(
                    'LIHAT REVIEW',
                    style: AppTextStyles.button.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ).animate().scale(delay: 500.ms),

                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
                  child: Text(
                    'Kembali ke Beranda',
                    style: AppTextStyles.label.copyWith(color: Colors.white70, decoration: TextDecoration.underline),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
