import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_routes.dart';
import '../../core/widgets/sd_button.dart';
import '../../core/services/firebase_service.dart';
import 'package:permission_handler/permission_handler.dart';

// ── Data tiap halaman onboarding ────────────────────────────────────────────

enum _PageType { singleChoice, gridChoice, notification }

class _OnbPage {
  final _PageType type;
  final String? question;
  final List<_OptionItem>? options;
  final List<_SubjectItem>? subjects;
  const _OnbPage({required this.type, this.question, this.options, this.subjects});
}

class _OptionItem {
  final String label;
  final String icon;
  const _OptionItem(this.icon, this.label);
}

class _SubjectItem {
  final String emoji;
  final String label;
  final Color color;
  const _SubjectItem(this.emoji, this.label, this.color);
}

final _pages = [
  _OnbPage(
    type: _PageType.singleChoice,
    question: 'Bagaimana kamu bisa\nmenemukan game ini?',
    options: const [
      _OptionItem('👥', 'Teman/Keluarga'),
      _OptionItem('🏫', 'Sekolah'),
      _OptionItem('📱', 'Iklan/Social Media'),
      _OptionItem('...', 'Lainnya'),
    ],
  ),
  _OnbPage(
    type: _PageType.singleChoice,
    question: 'Apa Alasan Kamu Ingin Belajar\nSecara Kompetitif?',
    options: const [
      _OptionItem('📖', 'Belajar Mandiri'),
      _OptionItem('✏️', 'Ujian dan Ulangan Harian'),
      _OptionItem('🏆', 'Memenangkan Pertandingan'),
      _OptionItem('🥇', 'Mencapai Rangking I'),
      _OptionItem('...', 'Lainnya'),
    ],
  ),
  _OnbPage(
    type: _PageType.gridChoice,
    question: 'Aku ingin belajar ...',
    subjects: const [
      _SubjectItem('🔬', 'Sains', AppColors.science),
      _SubjectItem('📐', 'Matematika', AppColors.math),
      _SubjectItem('🌍', 'Sosial', AppColors.social),
      _SubjectItem('📝', 'Bahasa', AppColors.indonesian),
      _SubjectItem('✨', 'Agama', AppColors.religion),
      _SubjectItem('🏛️', 'Negara', AppColors.civics),
      _SubjectItem('🎨', 'Seni', AppColors.arts),
      _SubjectItem('···', 'Lainnya', AppColors.rarityCommon),
    ],
  ),
  _OnbPage(
    type: _PageType.singleChoice,
    question: 'Berapa banyak waktu yang\nbisa kamu habiskan untuk\nbelajar mandiri?',
    options: const [
      _OptionItem('⏱️', '15 Menit'),
      _OptionItem('🕐', '30 Menit'),
      _OptionItem('🕑', '1 Jam'),
      _OptionItem('🕓', '2 - 4 Jam'),
      _OptionItem('🕔', '> 5 Jam'),
    ],
  ),
  _OnbPage(type: _PageType.notification),
];

// ── Main Widget ──────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _current = 0;

  // answers[pageIndex] = selected index or set of indexes
  final Map<int, dynamic> _answers = {};

  void _next() async {
    if (_current < _pages.length - 1) {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      // Save onboarding answers to Firestore
      final uid = FirebaseService().currentUser?.uid;
      if (uid != null) {
        try {
          final p0Opt = _answers[0] != null ? _pages[0].options![_answers[0] as int].label : 'Skip';
          final p1Opt = _answers[1] != null ? _pages[1].options![_answers[1] as int].label : 'Skip';
          
          final selectedSubjIndices = (_answers[2] as Set<int>?) ?? {};
          final p2Opts = selectedSubjIndices.map((idx) => _pages[2].subjects![idx].label).toList();
          
          final p3Opt = _answers[3] != null ? _pages[3].options![_answers[3] as int].label : 'Skip';

          await FirebaseService().updateOnboarding(
            uid,
            source: p0Opt,
            reason: p1Opt,
            subjects: p2Opts,
            timeLimit: p3Opt,
            enableNotif: true,
          );
        } catch (e) {
          debugPrint("Gagal menyimpan data onboarding: $e");
        }
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    }
  }

  void _back() {
    if (_current > 0) {
      _ctrl.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  bool get _canProceed {
    final page = _pages[_current];
    if (page.type == _PageType.notification) return true;
    return _answers.containsKey(_current);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_current + 1) / _pages.length;

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: Stack(
        children: [
          // Stars decorations
          const Positioned(top: 60, right: 20, child: Text('⭐', style: TextStyle(fontSize: 36))),
          const Positioned(top: 100, left: 12, child: Text('⭐', style: TextStyle(fontSize: 20))),
          const Positioned(bottom: 90, left: 20, child: Text('⭐', style: TextStyle(fontSize: 32))),
          const Positioned(bottom: 70, right: 16, child: Text('⭐', style: TextStyle(fontSize: 22))),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      if (_current > 0)
                        GestureDetector(
                          onTap: _back,
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 22),
                        )
                      else
                        const SizedBox(width: 22),
                      const Spacer(),
                      _StudyDuelLogo(),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(
                            context, AppRoutes.home),
                        child: Text(
                          'Lewati',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white60,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Pages
                Expanded(
                  child: PageView.builder(
                    controller: _ctrl,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _current = i),
                    itemCount: _pages.length,
                    itemBuilder: (_, i) => _buildPage(i),
                  ),
                ),

                // Bottom: progress bar + button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                  child: Column(
                    children: [
                      // Next button
                      if (_pages[_current].type != _PageType.notification)
                        SdButton(
                          label: _current == _pages.length - 1 ? 'Mulai!' : 'Lanjut',
                          onPressed: _canProceed ? _next : null,
                        ),
                      const SizedBox(height: 16),
                      // Red progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: Colors.white24,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(int i) {
    final page = _pages[i];
    switch (page.type) {
      case _PageType.singleChoice:
        return _SingleChoicePage(
          question: page.question!,
          options: page.options!,
          selected: _answers[i] as int?,
          onSelect: (idx) => setState(() => _answers[i] = idx),
        );
      case _PageType.gridChoice:
        return _GridChoicePage(
          question: page.question!,
          subjects: page.subjects!,
          selected: (_answers[i] as Set<int>?) ?? {},
          onToggle: (idx) {
            setState(() {
              final s = ((_answers[i] as Set<int>?) ?? <int>{})..toSet();
              final updated = Set<int>.from(s);
              if (updated.contains(idx)) {
                updated.remove(idx);
              } else {
                updated.add(idx);
              }
              _answers[i] = updated;
            });
          },
        );
      case _PageType.notification:
        return _NotificationPage(onEnable: _next);
    }
  }
}

// ── Logo ────────────────────────────────────────────────────────────────────

class _StudyDuelLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'STUDY\nDUEL',
      style: AppTextStyles.h2.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        height: 1.0,
        letterSpacing: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }
}

// ── Single Choice Page ───────────────────────────────────────────────────────

class _SingleChoicePage extends StatelessWidget {
  final String question;
  final List<_OptionItem> options;
  final int? selected;
  final ValueChanged<int> onSelect;

  const _SingleChoicePage({
    required this.question,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Text(
            question,
            style: AppTextStyles.h3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.separated(
              itemCount: options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final opt = options[i];
                final isSelected = selected == i;
                return GestureDetector(
                  onTap: () => onSelect(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(opt.icon, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 12),
                        Text(
                          opt.label,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().slideX(
                      begin: 0.1,
                      delay: Duration(milliseconds: 60 * i),
                      duration: 300.ms,
                    );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Grid Choice Page ─────────────────────────────────────────────────────────

class _GridChoicePage extends StatelessWidget {
  final String question;
  final List<_SubjectItem> subjects;
  final Set<int> selected;
  final ValueChanged<int> onToggle;

  const _GridChoicePage({
    required this.question,
    required this.subjects,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Text(
            question,
            style: AppTextStyles.h3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.85,
              ),
              itemCount: subjects.length,
              itemBuilder: (_, i) {
                final s = subjects[i];
                final isSelected = selected.contains(i);
                return GestureDetector(
                  onTap: () => onToggle(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: isSelected ? s.color : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: s.color,
                        width: isSelected ? 0 : 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: s.color.withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          s.emoji,
                          style: TextStyle(
                            fontSize: s.emoji == '···' ? 14 : 28,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.label,
                          style: AppTextStyles.caption.copyWith(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ).animate().scale(
                      delay: Duration(milliseconds: 50 * i),
                      duration: 300.ms,
                      curve: Curves.easeOut,
                    );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notification Page ────────────────────────────────────────────────────────

class _NotificationPage extends StatelessWidget {
  final VoidCallback onEnable;
  const _NotificationPage({required this.onEnable});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mascot karakter Kinz
          Container(
            width: 140,
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.accentSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.accent, width: 2),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🧙', style: TextStyle(fontSize: 72)),
                Text('Kinz', style: TextStyle(
                  color: AppColors.accentDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                )),
              ],
            ),
          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.darkNavyCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(
              'Jangan lupa\nnyalakan Notifikasi\nsebagai\npengingat\nbelajar\nharianmu ya!\n- Kinz',
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.white,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 28),
          SdButton(
            label: 'Nyalakan Notifikasi 🔔',
            onPressed: () async {
              await Permission.notification.request();
              onEnable();
            },
          ).animate().fadeIn(delay: 500.ms),
        ],
      ),
    );
  }
}
