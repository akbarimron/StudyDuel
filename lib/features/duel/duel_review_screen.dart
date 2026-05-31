import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class DuelReviewScreen extends StatefulWidget {
  const DuelReviewScreen({super.key});

  @override
  State<DuelReviewScreen> createState() => _DuelReviewScreenState();
}

class _DuelReviewScreenState extends State<DuelReviewScreen> {
  late List<Map<String, dynamic>> _questions;
  late List<int?> _userAnswers;
  bool _initialized = false;

  List<Map<String, dynamic>> _wrongQuestions = [];
  int _currentIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _questions = List<Map<String, dynamic>>.from(args['questions']);
      _userAnswers = List<int?>.from(args['userAnswers']);
      _initialized = true;
      _parseWrongAnswers();
    }
  }

  void _parseWrongAnswers() {
    List<Map<String, dynamic>> wrong = [];
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final uAnsIdx = _userAnswers[i];
      final opts = List<String>.from(q['options'] ?? q['opts'] ?? []);
      
      final String correctOptionText = (q['correct_answer'] ?? '').toString();
      final int correctIdxFromAns = q['ans'] as int? ?? -1;

      bool isCorrect = false;
      if (uAnsIdx != null && uAnsIdx >= 0 && uAnsIdx < opts.length) {
        final uAnsText = opts[uAnsIdx];
        if (correctOptionText.isNotEmpty && uAnsText == correctOptionText) {
          isCorrect = true;
        } else if (correctIdxFromAns == uAnsIdx) {
          isCorrect = true;
        }
      }

      if (!isCorrect) {
        wrong.add({
          'question': q,
          'userAnswerIdx': uAnsIdx,
          'userAnswerText': (uAnsIdx != null && uAnsIdx >= 0 && uAnsIdx < opts.length) ? opts[uAnsIdx] : 'Tidak dijawab',
          'correctAnswerText': correctOptionText.isNotEmpty ? correctOptionText : (correctIdxFromAns >= 0 && correctIdxFromAns < opts.length ? opts[correctIdxFromAns] : ''),
        });
      }
    }
    setState(() {
      _wrongQuestions = wrong;
    });
  }

  String _generateAiExplanation(String qText, String correctText) {
    return "*Analisis AI Kinz*:\n\nSoal ini meminta kita untuk mencari hasil dari pertanyaan \"$qText\". Jawaban yang tepat adalah \"$correctText\".\n\n*Mengapa Jawaban Ini Benar?*\nSetiap opsi dianalisis berdasarkan prinsip inti materi pelajaran ini. Konsep teoritis menunjukkan bahwa langkah logis paling valid akan langsung mengarah ke \"$correctText\". Pastikan untuk membaca soal secara teliti dan mengeliminasi pilihan yang kurang masuk akal terlebih dahulu.";
  }

  void _showAiChatModal(String qText, String correctText, String userText) {
    final chatController = TextEditingController();
    List<Map<String, String>> messages = [
      {
        'sender': 'ai',
        'text': 'Halo! Saya AI Kinz. Saya siap membantumu mempelajari lebih lanjut tentang soal ini. Apakah ada konsep atau bagian penjelasan di atas yang masih kurang jelas?'
      }
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Color(0xFF1F1F2E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white10)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.psychology_rounded, color: AppColors.primary, size: 24),
                            const SizedBox(width: 10),
                            Text(
                              'Diskusi AI Kinz',
                              style: AppTextStyles.h3.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white60),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Messages Area
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, i) {
                        final msg = messages[i];
                        final isAi = msg['sender'] == 'ai';
                        return Align(
                          alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isAi ? const Color(0xFF2A2A3E) : AppColors.primary,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isAi ? 4 : 16),
                                bottomRight: Radius.circular(isAi ? 16 : 4),
                              ),
                            ),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            child: Text(
                              msg['text']!,
                              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Input Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.white10)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: chatController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Tanyakan sesuatu...',
                              hintStyle: const TextStyle(color: Colors.white30),
                              filled: true,
                              fillColor: const Color(0xFF2A2A3E),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(100),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            final text = chatController.text.trim();
                            if (text.isEmpty) return;

                            setModalState(() {
                              messages.add({'sender': 'user', 'text': text});
                              chatController.clear();
                            });

                            // Simulate AI Typing
                            Future.delayed(const Duration(milliseconds: 1000), () {
                              setModalState(() {
                                messages.add({
                                  'sender': 'ai',
                                  'text': 'Sangat menarik pertanyaanmu! Untuk soal "$qText", konsep dasarnya berkaitan erat dengan hukum materi tersebut. Menggunakan jawaban "$correctText" terbukti paling logis karena alasan yang konsisten. Apakah kamu ingin saya berikan latihan soal serupa?'
                                });
                              });
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool allCorrect = _wrongQuestions.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF1F1F2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'AI Review Soal',
          style: AppTextStyles.h2.copyWith(color: Colors.white, fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: allCorrect ? _buildAllCorrectView() : _buildReviewFlowView(),
      ),
    );
  }

  Widget _buildAllCorrectView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Mascot
            Image.asset(
              'assets/images/char/kinz.png',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(
                  color: AppColors.successSurface,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.auto_awesome_rounded, size: 80, color: AppColors.success),
                ),
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 32),
            Text(
              'Kerennyoo!! - Kinz',
              style: AppTextStyles.h2.copyWith(color: Colors.white, fontSize: 26),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 12),
            Text(
              'Tidak ada Jawaban salah, kamu sudah sangat mahir!',
              style: AppTextStyles.bodyLarge.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 350.ms),
            const SizedBox(height: 48),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Kembali',
                style: AppTextStyles.button.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewFlowView() {
    final currentWrong = _wrongQuestions[_currentIndex];
    final Map<String, dynamic> q = currentWrong['question'] as Map<String, dynamic>;
    final String qText = (q['content'] ?? q['q'] ?? '').toString();
    final String uAns = currentWrong['userAnswerText'] as String;
    final String cAns = currentWrong['correctAnswerText'] as String;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Index Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Salah ${_currentIndex + 1} dari ${_wrongQuestions.length}',
                  style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                'AI Reviewer',
                style: AppTextStyles.caption.copyWith(color: Colors.white30, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Question Card
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A3E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pertanyaan:',
                          style: AppTextStyles.caption.copyWith(color: Colors.white60, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          qText,
                          style: AppTextStyles.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // User Answer (Red Card)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.errorSurface.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cancel_rounded, color: AppColors.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Jawaban Anda:',
                                style: AppTextStyles.caption.copyWith(color: Colors.white60),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                uAns,
                                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Correct Answer (Green Card)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.successSurface.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.success),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Jawaban Benar:',
                                style: AppTextStyles.caption.copyWith(color: Colors.white60),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                cAns,
                                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // AI Explanation
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _generateAiExplanation(qText, cAns),
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Action Buttons
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Chat AI Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8A70FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => _showAiChatModal(qText, cAns, uAns),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.psychology_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Tanya lebih lanjut ke AI',
                      style: AppTextStyles.button.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Navigation row
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white10,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _currentIndex > 0
                          ? () => setState(() => _currentIndex--)
                          : null,
                      child: Text(
                        'Sebelumnya',
                        style: AppTextStyles.label.copyWith(
                          color: _currentIndex > 0 ? Colors.white : Colors.white30,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white10,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _currentIndex < _wrongQuestions.length - 1
                          ? () => setState(() => _currentIndex++)
                          : null,
                      child: Text(
                        'Selanjutnya',
                        style: AppTextStyles.label.copyWith(
                          color: _currentIndex < _wrongQuestions.length - 1 ? Colors.white : Colors.white30,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate(key: ValueKey(_currentIndex)).fadeIn(duration: 300.ms);
  }
}
