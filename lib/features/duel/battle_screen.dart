import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/firebase_service.dart';
import '../../core/utils/icon_handler.dart';

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
  List<int?> _userAnswers = [];
  bool _loadingQuestions = true;
  StreamSubscription? _duelSub;
  String _oppName = 'Lawan';
  String _myAvatar = 'kinz.png';
  String _oppAvatar = 'kinz.png';
  bool _isBot = false;

  // Smarter Bot simulation parameters
  bool _botAnsweredThisQuestion = false;
  int? _botResponseTime;
  bool? _botCorrect;
  String _difficulty = 'sedang';

  // Waiting for opponent parameters
  bool _waitingForOpponent = false;
  int _oppAnsweredCount = 0;
  Timer? _waitingTimer;
  int _waitingTimeLeft = 25;
  bool _p1Finished = false;
  bool _p2Finished = false;

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

  void _setupBotForQuestion() {
    if (!_isBot) return;
    final r = Random();
    if (_difficulty == 'mudah') {
      _botCorrect = r.nextDouble() < 0.50; // 50% accuracy
      _botResponseTime = 8 + r.nextInt(8); // 8 to 15 seconds
    } else if (_difficulty == 'sulit') {
      _botCorrect = true; // 100% accuracy (always correct on hard difficulty)
      _botResponseTime = 2 + r.nextInt(3); // 2 to 4 seconds
    } else { // sedang
      _botCorrect = r.nextDouble() < 0.75; // 75% accuracy
      _botResponseTime = 4 + r.nextInt(5); // 4 to 8 seconds
    }
    _botAnsweredThisQuestion = false;
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

      // Fetch Avatars
      String myAvatar = 'kinz.png';
      String oppAvatar = 'kinz.png';
      
      final myUid = FirebaseService().currentUser?.uid;
      if (myUid != null) {
        final myDoc = await FirebaseFirestore.instance.collection('users').doc(myUid).get();
        if (myDoc.exists) {
          myAvatar = myDoc.data()?['avatar_url'] ?? 'kinz.png';
        }
      }

      if (_isBot) {
        oppAvatar = 'robot';
      } else {
        final oppId = _isPlayer1 ? data['player2_id'] : data['player1_id'];
        if (oppId != null && oppId.toString().isNotEmpty) {
          final oppDoc = await FirebaseFirestore.instance.collection('users').doc(oppId).get();
          if (oppDoc.exists) {
            oppAvatar = oppDoc.data()?['avatar_url'] ?? 'kinz.png';
          }
        }
      }

      List<Map<String, dynamic>> qList = [];
      if (data['questions'] != null) {
        final List<dynamic> rawQs = data['questions'];
        qList = rawQs.map((q) => Map<String, dynamic>.from(q as Map)).toList();
      } else {
        qList = await FirebaseService().getQuestionsForDuel(subject, diff);
      }

      if (mounted) {
        setState(() {
          _difficulty = diff.toLowerCase();
          _battleQuestions = qList;
          _userAnswers = List.filled(qList.length, null);
          _loadingQuestions = false;
          _myAvatar = myAvatar;
          _oppAvatar = oppAvatar;
          _setupBotForQuestion();
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

        final p1Finished = sessionData['player1_finished'] as bool? ?? false;
        final p2Finished = sessionData['player2_finished'] as bool? ?? false;

        if (mounted) {
          setState(() {
            _p1Finished = p1Finished;
            _p2Finished = p2Finished;
            _oppScore = _isPlayer1 ? s2 : s1;
            _myScore = _isPlayer1 ? s1 : s2;

            // Calculate opponent answered count
            final oppPlayerKey = _isPlayer1 ? 'p2' : 'p1';
            _oppAnsweredCount = 0;
            if (sessionData['answers'] != null) {
              final Map<String, dynamic> answers = sessionData['answers'] as Map<String, dynamic>;
              for (int i = 0; i < _battleQuestions.length; i++) {
                final qKey = 'q_$i';
                if (answers.containsKey(qKey) && answers[qKey] is Map) {
                  final qAns = answers[qKey] as Map<String, dynamic>;
                  if (qAns.containsKey(oppPlayerKey)) {
                    _oppAnsweredCount++;
                  }
                }
              }
            }
          });

          // If both finished, navigate to results
          if (_waitingForOpponent && p1Finished && p2Finished) {
            _navigateToResults();
          }
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

        // Smarter Bot simulation (runs independently of player answering status)
        if (_isBot && !_botAnsweredThisQuestion) {
          final elapsed = 30 - _timeLeft;
          if (elapsed >= _botResponseTime!) {
            _botAnsweredThisQuestion = true;
            final oppPlayerKey = _isPlayer1 ? 'p2' : 'p1';
            
            if (_botCorrect!) {
              final List<int> questionWeights = [10, 10, 15, 15, 20, 20, 25, 25, 30, 30];
              final basePoints = questionWeights[_qIndex.clamp(0, questionWeights.length - 1)];
              final speedBonus = _timeLeft ~/ 2;
              
              // Check if player has answered correctly first
              final myPlayerKey = _isPlayer1 ? 'p1' : 'p2';
              final sessionDoc = await FirebaseFirestore.instance.collection('duel_sessions').doc(_sessionId).get();
              final sessionData = sessionDoc.data() ?? {};
              final answers = sessionData['answers'] as Map<String, dynamic>? ?? {};
              final qKey = 'q_$_qIndex';
              
              bool playerCorrectFirst = false;
              if (answers.containsKey(qKey)) {
                final myAns = answers[qKey][myPlayerKey] as Map<String, dynamic>?;
                if (myAns != null && myAns['correct'] == true) {
                  playerCorrectFirst = true;
                }
              }
              
              int firstCorrectBonus = playerCorrectFirst ? 0 : 10;
              final botEarnedPoints = basePoints + speedBonus + firstCorrectBonus;
              
              final currentBotScore = sessionData[_isPlayer1 ? 'score_player2' : 'score_player1'] as int? ?? 0;
              final newBotScore = currentBotScore + botEarnedPoints;
              
              await FirebaseFirestore.instance.collection('duel_sessions').doc(_sessionId).update({
                _isPlayer1 ? 'score_player2' : 'score_player1': newBotScore,
                'answers.q_$_qIndex.$oppPlayerKey': {
                  'correct': true,
                  'time_left': _timeLeft,
                  'timestamp': FieldValue.serverTimestamp(),
                }
              });
            } else {
              await FirebaseFirestore.instance.collection('duel_sessions').doc(_sessionId).update({
                'answers.q_$_qIndex.$oppPlayerKey': {
                  'correct': false,
                  'time_left': _timeLeft,
                  'timestamp': FieldValue.serverTimestamp(),
                }
              });
            }
          }
        }
      }
    });
  }

  void _answer(int idx) async {
    if (_answered) return;
    
    final q = _battleQuestions[_qIndex];
    final isCorrect = q['ans'] == idx || q['correct_answer'] == (q['options'] ?? q['opts'])[idx];

    _userAnswers[_qIndex] = idx;
    
    int earnedPoints = 0;
    int basePoints = 0;
    int speedBonus = 0;
    int firstCorrectBonus = 0;

    if (isCorrect) {
      final List<int> questionWeights = [10, 10, 15, 15, 20, 20, 25, 25, 30, 30];
      basePoints = questionWeights[_qIndex.clamp(0, questionWeights.length - 1)];
      speedBonus = _timeLeft ~/ 2;
      
      final oppPlayerKey = _isPlayer1 ? 'p2' : 'p1';
      
      final sessionDoc = await FirebaseFirestore.instance.collection('duel_sessions').doc(_sessionId).get();
      final sessionData = sessionDoc.data() ?? {};
      final answers = sessionData['answers'] as Map<String, dynamic>? ?? {};
      final qKey = 'q_$_qIndex';
      
      bool oppCorrectFirst = false;
      if (answers.containsKey(qKey)) {
        final oppAns = answers[qKey][oppPlayerKey] as Map<String, dynamic>?;
        if (oppAns != null && oppAns['correct'] == true) {
          oppCorrectFirst = true;
        }
      }
      
      if (!oppCorrectFirst) {
        firstCorrectBonus = 10;
      }
      
      earnedPoints = basePoints + speedBonus + firstCorrectBonus;
    }

    setState(() {
      _selected = idx;
      _answered = true;
      if (isCorrect) {
        _myScore += earnedPoints;
      }
    });

    if (isCorrect && mounted) {
      String message = '+$basePoints poin';
      if (speedBonus > 0) message += ' \n+$speedBonus Poin Kecepatan';
      if (firstCorrectBonus > 0) message += ' \n+$firstCorrectBonus Poin Tercepat';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
          duration: const Duration(milliseconds: 1200),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 200, left: 50, right: 50),
        ),
      );
    }

    try {
      final myPlayerKey = _isPlayer1 ? 'p1' : 'p2';
      await FirebaseFirestore.instance.collection('duel_sessions').doc(_sessionId).update({
        _isPlayer1 ? 'score_player1' : 'score_player2': _myScore,
        'answers.q_$_qIndex.$myPlayerKey': {
          'correct': isCorrect,
          'time_left': _timeLeft,
          'timestamp': FieldValue.serverTimestamp(),
        }
      });
    } catch (e) {
      debugPrint("Failed to update score: $e");
    }

    Future.delayed(const Duration(milliseconds: 1500), _nextQuestion);
  }

  void _navigateToResults() {
    _timer?.cancel();
    _waitingTimer?.cancel();
    _duelSub?.cancel();
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.result,
      arguments: {
        'sessionId': _sessionId,
        'myScore': _myScore,
        'oppScore': _oppScore,
        'myAvatar': _myAvatar,
        'oppAvatar': _oppAvatar,
        'questions': _battleQuestions,
        'userAnswers': _userAnswers,
      },
    );
  }

  void _startWaitingTimeout() {
    _waitingTimer?.cancel();
    _waitingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_waitingTimeLeft <= 1) {
        timer.cancel();
        _navigateToResults();
      } else {
        if (mounted) {
          setState(() {
            _waitingTimeLeft--;
          });
        }
      }
    });
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
          _setupBotForQuestion();
        });
        _startTimer();
      }
    } else {
      // Mark myself as finished in Firestore
      final myFinishKey = _isPlayer1 ? 'player1_finished' : 'player2_finished';
      final updates = <String, dynamic>{
        myFinishKey: true,
      };
      if (_isBot) {
        final oppFinishKey = _isPlayer1 ? 'player2_finished' : 'player1_finished';
        updates[oppFinishKey] = true;
      }
      FirebaseFirestore.instance.collection('duel_sessions').doc(_sessionId).update(updates);

      if (mounted) {
        setState(() {
          _waitingForOpponent = true;
          if (_isPlayer1) {
            _p1Finished = true;
          } else {
            _p2Finished = true;
          }
          if (_isBot) {
            _p1Finished = true;
            _p2Finished = true;
          }
        });
        
        // Immediately navigate if both finished (avoiding stream event lag)
        if (_p1Finished && _p2Finished) {
          _navigateToResults();
          return;
        }
        
        _startWaitingTimeout();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waitingTimer?.cancel();
    _timerAnim.dispose();
    _duelSub?.cancel();
    super.dispose();
  }

  Color _optionColor(int i) {
    if (!_answered) return AppColors.surface;
    final q = _battleQuestions[_qIndex];
    final correct = q['ans'] == i || q['correct_answer'] == (q['options'] ?? q['opts'])[i];
    if (_selected == i) return correct ? AppColors.successSurface : AppColors.errorSurface;
    if (correct) return AppColors.successSurface;
    return AppColors.surface;
  }

  Color _optionBorder(int i) {
    if (!_answered) return AppColors.border;
    final q = _battleQuestions[_qIndex];
    final correct = q['ans'] == i || q['correct_answer'] == (q['options'] ?? q['opts'])[i];
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

    if (_waitingForOpponent) {
      return Scaffold(
        backgroundColor: const Color(0xFF1F1F2E),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          strokeWidth: 6,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ).animate(onPlay: (c) => c.repeat()).rotate(duration: 2000.ms),
                      const Icon(Icons.hourglass_empty_rounded, color: Colors.white, size: 36)
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(duration: 1000.ms, begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Menunggu Lawan Selesai...',
                    style: AppTextStyles.h2.copyWith(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Lawan sedang menjawab: $_oppAnsweredCount / ${_battleQuestions.length} soal',
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 48),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      'Otomatis lanjut dalam $_waitingTimeLeft detik...',
                      style: AppTextStyles.caption.copyWith(color: Colors.white60, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: _navigateToResults,
                    child: Text(
                      'Lewati & Lihat Hasil',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                    emoji: _myAvatar,
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
                    emoji: _oppAvatar,
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
          IconHandler.buildItemIcon(emoji, size: 28, color: color),
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
