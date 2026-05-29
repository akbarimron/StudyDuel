import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/firebase_service.dart';

class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen>
    with SingleTickerProviderStateMixin {
  int _qIndex = 0;
  int _timeLeft = 30;
  int _myScore = 0;
  int _oppScore = 0;
  int? _selected;
  bool _answered = false;
  Timer? _timer;
  late AnimationController _timerAnim;

  bool _initialized = false;
  late String _sessionId;
  late bool _isPlayer1;
  List<Map<String, dynamic>> _battleQuestions = [];
  bool _loadingQuestions = true;
  StreamSubscription? _duelSub;
  String _oppName = 'Lawan';
  bool _isBot = false;

  @override
  void initState() {
    super.initState();
    _timerAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _sessionId = args['sessionId'] as String;
      _isPlayer1 = args['isPlayer1'] as bool;
      _initialized = true;
      _initBattle();
    }
  }

  void _initBattle() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('duel_sessions').doc(_sessionId).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final subject = data['subject'] as String;
      final diff = data['difficulty'] as String;
      _isBot = data['player2_id'] == 'bot_id';
      _oppName = _isPlayer1
          ? (data['player2_name'] != '' ? data['player2_name'] : 'Lawan')
          : (data['player1_name'] != '' ? data['player1_name'] : 'Lawan');

      final qList = await FirebaseService().getQuestionsForDuel(subject, diff);
      if (mounted) {
        setState(() {
          _battleQuestions = qList;
          _loadingQuestions = false;
        });
        _timerAnim.forward();
        _startTimer();
      }

      // Listen to score updates of opponent
      _duelSub?.cancel();
      _duelSub = FirebaseService().getDuelStream(_sessionId).listen((snapshot) {
        if (!snapshot.exists) return;
        final sessionData = snapshot.data()!;
        final s1 = sessionData['score_player1'] as int;
        final s2 = sessionData['score_player2'] as int;

        if (mounted) {
          setState(() {
            _oppScore = _isPlayer1 ? s2 : s1;
            _myScore = _isPlayer1 ? s1 : s2;
          });
        }
      });
    } catch (e) {
      debugPrint("Failed to init battle: $e");
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timerAnim
      ..reset()
      ..forward();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_timeLeft <= 1) {
        _nextQuestion();
      } else {
        if (mounted) {
          setState(() => _timeLeft--);
        }

        // If opponent is bot, simulate bot answering with a probability
        if (_isBot && !_answered && _timeLeft == 22) {
          final correct = Random().nextDouble() < 0.7;
          if (correct) {
            final newOppScore = _oppScore + 100;
            await FirebaseService().updateScore(_sessionId, !_isPlayer1, newOppScore);
          }
        }
      }
    });
  }

  void _answer(int idx) async {
    if (_answered) return;
    
    final q = _battleQuestions[_qIndex];
    final isCorrect = q['ans'] == idx || q['correct_answer'] == q['options'][idx];

    setState(() {
      _selected = idx;
      _answered = true;
      if (isCorrect) {
        _myScore += 100;
      }
    });

    try {
      await FirebaseService().updateScore(_sessionId, _isPlayer1, _myScore);
    } catch (e) {
      debugPrint("Failed to update score: $e");
    }

    Future.delayed(const Duration(milliseconds: 1200), _nextQuestion);
  }

  void _nextQuestion() {
    _timer?.cancel();
    if (_qIndex < _battleQuestions.length - 1) {
      if (mounted) {
        setState(() {
          _qIndex++;
          _timeLeft = 30;
          _selected = null;
          _answered = false;
        });
        _startTimer();
      }
    } else {
      _duelSub?.cancel();
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.result,
        arguments: {
          'sessionId': _sessionId,
          'myScore': _myScore,
          'oppScore': _oppScore,
        },
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timerAnim.dispose();
    _duelSub?.cancel();
    super.dispose();
  }

  Color _optionColor(int i) {
    if (!_answered) return AppColors.surface;
    final q = _battleQuestions[_qIndex];
    final correct = q['ans'] == i || q['correct_answer'] == q['options'][i];
    if (_selected == i) return correct ? AppColors.successSurface : AppColors.errorSurface;
    if (correct) return AppColors.successSurface;
    return AppColors.surface;
  }

  Color _optionBorder(int i) {
    if (!_answered) return AppColors.border;
    final q = _battleQuestions[_qIndex];
    final correct = q['ans'] == i || q['correct_answer'] == q['options'][i];
    if (_selected == i) return correct ? AppColors.success : AppColors.error;
    if (correct) return AppColors.success;
    return AppColors.border;
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingQuestions) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Menyiapkan Arena Duel...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    final q = _battleQuestions[_qIndex];
    final opts = List<String>.from(q['options'] ?? q['opts']);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header: scores & timer
              Row(
                children: [
                  _PlayerCard(
                    name: 'Kamu',
                    emoji: '🧑',
                    score: _myScore,
                    color: AppColors.primary,
                    isMe: true,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _timerAnim,
                          builder: (_, __) => Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 60,
                                height: 60,
                                child: CircularProgressIndicator(
                                  value: 1 - _timerAnim.value,
                                  strokeWidth: 5,
                                  backgroundColor: AppColors.borderLight,
                                  valueColor: AlwaysStoppedAnimation(
                                    _timeLeft > 10
                                        ? AppColors.primary
                                        : AppColors.error,
                                  ),
                                ),
                              ),
                              Text(
                                '$_timeLeft',
                                style: AppTextStyles.h3.copyWith(
                                  color: _timeLeft > 10
                                      ? AppColors.primary
                                      : AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('VS', style: AppTextStyles.label.copyWith(
                            color: AppColors.textHint)),
                      ],
                    ),
                  ),
                  _PlayerCard(
                    name: _oppName,
                    emoji: _isBot ? '🤖' : '🧑',
                    score: _oppScore,
                    color: AppColors.secondary,
                    isMe: false,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Progress dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _battleQuestions.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _qIndex == i ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color:
                          i < _qIndex ? AppColors.success : (i == _qIndex ? AppColors.primary : AppColors.border),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Question card
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          'Soal ${_qIndex + 1} dari ${_battleQuestions.length}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: Center(
                          child: Text(
                            (q['content'] ?? q['q']) as String,
                            style: AppTextStyles.h3,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate(key: ValueKey(_qIndex)).fadeIn(duration: 300.ms),
              const SizedBox(height: 16),
              // Options
              ...List.generate(
                opts.length,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => _answer(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: _optionColor(i),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _optionBorder(i),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.borderLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                ['A', 'B', 'C', 'D'][i],
                                style: AppTextStyles.label,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              opts[i],
                              style: AppTextStyles.bodyLarge,
                            ),
                          ),
                          if (_answered && (q['ans'] == i || q['correct_answer'] == opts[i]))
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.success),
                          if (_answered &&
                              _selected == i &&
                              !(q['ans'] == i || q['correct_answer'] == opts[i]))
                            const Icon(Icons.cancel_rounded,
                                color: AppColors.error),
                        ],
                      ),
                    ),
                  ).animate(key: ValueKey('$_qIndex-$i'))
                      .slideX(begin: 0.05, duration: 300.ms, delay: Duration(milliseconds: 60 * i))
                      .fadeIn(duration: 300.ms, delay: Duration(milliseconds: 60 * i)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final String name, emoji;
  final int score;
  final Color color;
  final bool isMe;

  const _PlayerCard({
    required this.name,
    required this.emoji,
    required this.score,
    required this.color,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 2),
          Text(name, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
          Text(
            '$score',
            style: AppTextStyles.h3.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
