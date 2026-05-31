import 'dart:math';
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
  final dynamic icon; // Can be String path or IconData
  const _OptionItem(this.icon, this.label);
}

class _SubjectItem {
  final IconData icon;
  final String label;
  final Color color;
  const _SubjectItem(this.icon, this.label, this.color);
}

final _pages = [
  _OnbPage(
    type: _PageType.singleChoice,
    question: 'Bagaimana kamu bisa\nmenemukan game ini?',
    options: const [
      _OptionItem('assets/images/logo/onboarding_teman.png', 'Teman/Keluarga'),
      _OptionItem('assets/images/logo/onboarding_sekolah.png', 'Sekolah'),
      _OptionItem('assets/images/logo/onboarding_sosiall.png', 'Iklan/Social Media'),
      _OptionItem('assets/images/logo/onboarding_llainnya.png', 'Lainnya'),
    ],
  ),
  _OnbPage(
    type: _PageType.singleChoice,
    question: 'Apa Alasan Kamu Ingin Belajar\nSecara Kompetitif?',
    options: const [
      _OptionItem(Icons.person_search_rounded, 'Belajar Mandiri'),
      _OptionItem(Icons.assignment_rounded, 'Ujian dan Ulangan Harian'),
      _OptionItem(Icons.emoji_events_rounded, 'Memenangkan Pertandingan'),
      _OptionItem(Icons.workspace_premium_rounded, 'Mencapai Rangking I'),
      _OptionItem(Icons.more_horiz_rounded, 'Lainnya'),
    ],
  ),
  _OnbPage(
    type: _PageType.gridChoice,
    question: 'Aku ingin belajar ...',
    subjects: const [
      _SubjectItem(Icons.science_rounded, 'Sains', AppColors.science),
      _SubjectItem(Icons.architecture_rounded, 'Matematika', AppColors.math),
      _SubjectItem(Icons.public_rounded, 'Sosial', AppColors.social),
      _SubjectItem(Icons.import_contacts_rounded, 'Bahasa', AppColors.indonesian),
      _SubjectItem(Icons.auto_awesome_rounded, 'Agama', AppColors.religion),
      _SubjectItem(Icons.account_balance_rounded, 'Negara', AppColors.civics),
      _SubjectItem(Icons.palette_rounded, 'Seni', AppColors.arts),
      _SubjectItem(Icons.more_horiz_rounded, 'Lainnya', AppColors.rarityCommon),
    ],
  ),
  _OnbPage(
    type: _PageType.singleChoice,
    question: 'Berapa banyak waktu yang\nbisa kamu habiskan untuk\nbelajar mandiri?',
    options: const [
      _OptionItem(Icons.timer_rounded, '15 Menit'),
      _OptionItem(Icons.schedule_rounded, '30 Menit'),
      _OptionItem(Icons.schedule_rounded, '1 Jam'),
      _OptionItem(Icons.schedule_rounded, '2 - 4 Jam'),
      _OptionItem(Icons.schedule_rounded, '> 5 Jam'),
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
          Positioned(
            top: -15,
            right: -15,
            child: Transform.rotate(
              angle: 0.15,
              child: const ChubbyStar(size: 65),
            ),
          ),
          Positioned(
            bottom: -15,
            left: -15,
            child: Transform.rotate(
              angle: -0.15,
              child: const ChubbyStar(size: 65),
            ),
          ),

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
    return Image.asset(
      'assets/images/studyDuel_logo.png',
      height: 40,
      fit: BoxFit.contain,
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
                      borderRadius: BorderRadius.circular(10),
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
                        if (opt.icon is String && (opt.icon as String).contains('/'))
                          Image.asset(
                            opt.icon as String,
                            width: 32,
                            height: 32,
                            color: isSelected ? Colors.white : null,
                          )
                        else if (opt.icon is IconData)
                          Icon(
                            opt.icon as IconData,
                            size: 26,
                            color: isSelected ? Colors.white : AppColors.primary,
                          )
                        else if (opt.icon is String)
                          Text(opt.icon as String, style: const TextStyle(fontSize: 22))
                        else
                          const SizedBox(width: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            opt.label,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
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

  Widget _getSubjectIcon(String label) {
    switch (label) {
      case 'Sains':
        return const _SainsIcon();
      case 'Matematika':
        return const _MatematikaIcon();
      case 'Sosial':
        return const _SosialIcon();
      case 'Bahasa':
        return const _BahasaIcon();
      case 'Agama':
        return const _AgamaIcon();
      case 'Negara':
        return const _NegaraIcon();
      case 'Seni':
        return const _SeniIcon();
      default:
        return const _LainnyaIcon();
    }
  }

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
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.25,
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
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: isSelected ? 3.0 : 0.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? s.color.withValues(alpha: 0.4)
                              : Colors.black.withValues(alpha: 0.08),
                          blurRadius: isSelected ? 20 : 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 36,
                          child: Center(
                            child: isSelected
                                ? ColorFiltered(
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                    child: _getSubjectIcon(s.label),
                                  )
                                : _getSubjectIcon(s.label),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.label,
                          style: AppTextStyles.caption.copyWith(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
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
          const Image(
            image: AssetImage('assets/images/char/kinz.png'),
            height: 300,
            fit: BoxFit.contain,
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
              'Jangan lupa nyalakan Notifikasi sebagai pengingat belajar harianmu ya!\n- Kinz',
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.white,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 28),
          SdButton(
            label: 'Nyalakan Notifikasi',
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

// ── Custom Decorative Chubby Star Painter & Widget ──────────────────────────

class ChubbyStarPainter extends CustomPainter {
  final Color color;
  ChubbyStarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final path = Path();
    
    path.moveTo(w * 0.5, 0);
    path.quadraticBezierTo(w * 0.55, h * 0.45, w, h * 0.5);
    path.quadraticBezierTo(w * 0.55, h * 0.55, w * 0.5, h);
    path.quadraticBezierTo(w * 0.45, h * 0.55, 0, h * 0.5);
    path.quadraticBezierTo(w * 0.45, h * 0.45, w * 0.5, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ChubbyStar extends StatelessWidget {
  final double size;
  const ChubbyStar({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: ChubbyStarPainter(color: const Color(0xFFFFD166)),
      ),
    );
  }
}

// ── Subject Icon Widgets & Painters ──────────────────────────────────────────

class _SainsIcon extends StatelessWidget {
  const _SainsIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: CustomPaint(
        painter: _AtomPainter(),
      ),
    );
  }
}

class _AtomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2;

    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Orbit 1: Diagonal 1
    orbitPaint.color = const Color(0xFF52B788); // Green
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(pi / 4);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: radius * 1.8, height: radius * 0.6), orbitPaint);
    
    final electronPaint = Paint()..style = PaintingStyle.fill;
    electronPaint.color = const Color(0xFFFFB703); // Yellow electron
    canvas.drawCircle(Offset(radius * 0.9, 0), 3.0, electronPaint);
    canvas.restore();

    // Orbit 2: Diagonal 2
    orbitPaint.color = const Color(0xFF1E88E5); // Blue
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-pi / 4);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: radius * 1.8, height: radius * 0.6), orbitPaint);
    
    electronPaint.color = const Color(0xFF52B788); // Green electron
    canvas.drawCircle(Offset(-radius * 0.9, 0), 3.0, electronPaint);
    canvas.restore();

    // Orbit 3: Vertical/Horizontal
    orbitPaint.color = const Color(0xFFE53935); // Red
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(pi / 2);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: radius * 1.8, height: radius * 0.6), orbitPaint);
    
    electronPaint.color = const Color(0xFF1E88E5); // Blue electron
    canvas.drawCircle(Offset(0, radius * 0.3), 3.0, electronPaint);
    canvas.restore();

    // Nucleus
    final nucleusPaint = Paint()
      ..color = const Color(0xFFFFB703)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 5.0, nucleusPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MatematikaIcon extends StatelessWidget {
  const _MatematikaIcon();

  Widget _box(String text, Color color) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _box('+', const Color(0xFFFF4D4D)),
            const SizedBox(width: 3),
            _box('−', const Color(0xFFFFC107)),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _box('÷', const Color(0xFF4CAF50)),
            const SizedBox(width: 3),
            _box('×', const Color(0xFF2196F3)),
          ],
        ),
      ],
    );
  }
}

class PersonIcon extends StatelessWidget {
  final Color color;
  const PersonIcon({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 1),
        Container(
          width: 16,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ),
      ],
    );
  }
}

class _SosialIcon extends StatelessWidget {
  const _SosialIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 28,
      child: Stack(
        children: [
          Positioned(
            left: 1,
            bottom: 0,
            child: const PersonIcon(color: Color(0xFF52B788)),
          ),
          Positioned(
            right: 1,
            top: 2,
            child: const PersonIcon(color: Color(0xFFFFB703)),
          ),
        ],
      ),
    );
  }
}

class _BahasaIcon extends StatelessWidget {
  const _BahasaIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 28,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: const BoxDecoration(
                color: Color(0xFF52B788),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                  bottomLeft: Radius.circular(6),
                  bottomRight: Radius.circular(0),
                ),
              ),
              child: const Text(
                'ツ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: const BoxDecoration(
                color: Color(0xFFE53935),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                  bottomLeft: Radius.circular(0),
                  bottomRight: Radius.circular(6),
                ),
              ),
              child: const Text(
                'A',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgamaIcon extends StatelessWidget {
  const _AgamaIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 28,
      child: CustomPaint(
        painter: _AgamaPainter(),
      ),
    );
  }
}

class _AgamaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // 1. Cross (Top/Center-Right)
    canvas.drawLine(const Offset(19, 2), const Offset(19, 13), paint);
    canvas.drawLine(const Offset(15, 5), const Offset(23, 5), paint);

    // 2. Mosque (Bottom-Left)
    final Path mosquePath = Path();
    mosquePath.moveTo(2, 24);
    mosquePath.lineTo(13, 24);
    mosquePath.lineTo(13, 19);
    mosquePath.arcTo(
      Rect.fromLTWH(5, 12, 6, 6),
      0,
      -pi,
      false,
    );
    mosquePath.lineTo(2, 19);
    mosquePath.close();

    mosquePath.moveTo(8, 12);
    mosquePath.lineTo(8, 9);

    canvas.drawPath(mosquePath, paint);

    canvas.drawLine(const Offset(1, 24), const Offset(1, 15), paint);
    canvas.drawCircle(const Offset(1, 14), 1.0, paint);
    
    canvas.drawLine(const Offset(14, 24), const Offset(14, 15), paint);
    canvas.drawCircle(const Offset(14, 14), 1.0, paint);

    // 3. Om symbol as Text
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    textPainter.text = TextSpan(
      text: String.fromCharCode(Icons.school_rounded.codePoint),
      style: TextStyle(
        color: Colors.black54,
        fontSize: 10,
        fontFamily: Icons.school_rounded.fontFamily,
        package: Icons.school_rounded.fontPackage,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(20, 12));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NegaraIcon extends StatelessWidget {
  const _NegaraIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 18,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFFD0D0D0), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 3,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: const Color(0xFFFF0000),
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeniIcon extends StatelessWidget {
  const _SeniIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 28,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 2,
            child: CustomPaint(
              size: const Size(14, 18),
              painter: _MaskPainter(color: const Color(0xFFE53935), isHappy: false),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 1,
            child: CustomPaint(
              size: const Size(14, 18),
              painter: _MaskPainter(color: const Color(0xFF52B788), isHappy: true),
            ),
          ),
        ],
      ),
    );
  }
}

class _MaskPainter extends CustomPainter {
  final Color color;
  final bool isHappy;
  _MaskPainter({required this.color, required this.isHappy});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.4)), paint);

    final eyePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.35), 1.2, eyePaint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.35), 1.2, eyePaint);

    final mouthPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    if (isHappy) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height * 0.62),
          width: size.width * 0.4,
          height: size.height * 0.25,
        ),
        0,
        pi,
        false,
        mouthPaint,
      );
    } else {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height * 0.72),
          width: size.width * 0.4,
          height: size.height * 0.25,
        ),
        0,
        -pi,
        false,
        mouthPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LainnyaIcon extends StatelessWidget {
  const _LainnyaIcon();

  @override
  Widget build(BuildContext context) {
    Widget dot() {
      return Container(
        width: 5,
        height: 5,
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          shape: BoxShape.circle,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        dot(),
        const SizedBox(width: 3),
        dot(),
        const SizedBox(width: 3),
        dot(),
      ],
    );
  }
}
