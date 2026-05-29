import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_routes.dart';
import '../../core/widgets/sd_button.dart';
import '../../core/services/firebase_service.dart';

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
  late String _sessionId;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _sessionId = args['sessionId'] as String;
      _myScore = args['myScore'] as int;
      _oppScore = args['oppScore'] as int;
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

  @override
  Widget build(BuildContext context) {
    if (_calculating) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary)),
              SizedBox(height: 16),
              Text('Menghitung Hasil Pertandingan...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    final win = _result == 'win';
    final draw = _result == 'draw';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: win
                ? [const Color(0xFF22C55E), const Color(0xFF16A34A)]
                : draw
                    ? [const Color(0xFF64748B), const Color(0xFF475569)]
                    : [AppColors.secondary, AppColors.secondaryDark],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                // Result emoji
                Text(
                  win ? '🏆' : draw ? '🤝' : '😓',
                  style: const TextStyle(fontSize: 100),
                )
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 16),
                Text(
                  win ? 'Kamu Menang!' : draw ? 'Hasil Seri!' : 'Kamu Kalah',
                  style: AppTextStyles.display.copyWith(color: Colors.white),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 8),
                Text(
                  win
                      ? 'Luar biasa! Terus semangat!'
                      : draw
                          ? 'Sama kuat! Terus belajar agar lebih tangguh!'
                          : 'Jangan menyerah, coba lagi!',
                  style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white70),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 40),
                // Score card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _ScoreCol(
                              label: 'Skormu',
                              value: '$_myScore',
                              color: AppColors.primary,
                              emoji: '🧑'),
                          Container(
                            width: 1,
                            height: 60,
                            color: AppColors.border,
                          ),
                          _ScoreCol(
                              label: 'Lawan',
                              value: '$_oppScore',
                              color: AppColors.secondary,
                              emoji: '🤖'),
                        ],
                      ),
                      const Divider(height: 28),
                      // XP earned
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('⚡', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 8),
                          Text(
                            '+$_xpReward XP',
                            style: AppTextStyles.h3
                                .copyWith(color: AppColors.primary),
                          ),
                          const SizedBox(width: 20),
                          const Text('💎', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 8),
                          Text(
                            '+$_gemsReward Gems',
                            style: AppTextStyles.h3
                                .copyWith(color: AppColors.accentDark),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().slideY(begin: 0.3, duration: 500.ms, delay: 400.ms),
                const Spacer(),
                // Buttons
                SdButton(
                  label: 'Main Lagi ⚔️',
                  variant: win ? SdButtonVariant.success : SdButtonVariant.secondary,
                  onPressed: () => Navigator.pushReplacementNamed(
                      context, AppRoutes.duelLobby),
                ).animate().fadeIn(delay: 600.ms),
                const SizedBox(height: 12),
                SdButton(
                  label: 'Kembali ke Beranda',
                  variant: SdButtonVariant.ghost,
                  onPressed: () => Navigator.pushReplacementNamed(
                      context, AppRoutes.home),
                ).animate().fadeIn(delay: 700.ms),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreCol extends StatelessWidget {
  final String label, value, emoji;
  final Color color;
  const _ScoreCol(
      {required this.label,
      required this.value,
      required this.color,
      required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.h1.copyWith(color: color)),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}
