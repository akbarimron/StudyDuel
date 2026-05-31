import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/sd_button.dart';
import 'gacha_screen.dart';
import '../../core/theme/profile_theme.dart';
import '../../core/widgets/profile_effect.dart';
import '../../core/utils/icon_handler.dart';

class GachaResultScreen extends StatefulWidget {
  final List<GachaItem> results;
  const GachaResultScreen({super.key, required this.results});

  @override
  State<GachaResultScreen> createState() => _GachaResultScreenState();
}

class _GachaResultScreenState extends State<GachaResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmer;
  int _revealIndex = 0;
  bool _showAll = false;

  bool get _isSingle => widget.results.length == 1;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  GachaItem get _currentItem =>
      widget.results[_revealIndex.clamp(0, widget.results.length - 1)];

  Color get _bgGradientStart {
    return switch (_currentItem.rarity) {
      'mythical' => const Color(0xFF1a0010),
      'legendary' => const Color(0xFF1a0f00),
      'epic' => const Color(0xFF0d0020),
      'rare' => const Color(0xFF001a3a),
      _ => AppColors.darkNavy,
    };
  }

  Color get _bgGradientEnd {
    return switch (_currentItem.rarity) {
      'mythical' => const Color(0xFF6b0030),
      'legendary' => const Color(0xFF7a4500),
      'epic' => const Color(0xFF3d0070),
      'rare' => const Color(0xFF004080),
      _ => AppColors.darkNavyCard,
    };
  }

  String get _rarityLabel {
    final prefix = _currentItem.category == 'points' ? 'Hadiah ' : '';
    return switch (_currentItem.rarity) {
      'mythical' => '${prefix}Mythical Diperoleh!',
      'legendary' => '${prefix}Legendary Diperoleh!',
      'epic' => '${prefix}Epic Diperoleh!',
      'rare' => '${prefix}Rare Diperoleh!',
      _ => '${prefix}Diperoleh!',
    };
  }

  int get _starCount {
    return switch (_currentItem.rarity) {
      'mythical' => 5,
      'legendary' => 4,
      'epic' => 3,
      'rare' => 2,
      _ => 1,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isSingle || !_showAll) {
      return _SingleReveal();
    }
    return _MultiReveal();
  }

  Widget _SingleReveal() {
    final themeConfig = _currentItem.category == 'background'
        ? ProfileThemeConfig.fromId(_currentItem.id, 'Pratinjau')
        : null;

    final isBg = _currentItem.category == 'background';
    final isEffect = _currentItem.category == 'effect';
    final isSkin = _currentItem.category == 'skin';

    return Scaffold(
      body: GestureDetector(
        onTap: () {
          if (!_isSingle && _revealIndex < widget.results.length - 1) {
            setState(() => _revealIndex++);
          } else if (!_isSingle) {
            setState(() => _showAll = true);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(
            gradient: themeConfig != null && themeConfig.hasGradientBg
                ? LinearGradient(
                    colors: [themeConfig.screenBgColorStart, themeConfig.screenBgColorEnd],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : RadialGradient(
                    colors: [_bgGradientEnd, _bgGradientStart],
                    center: Alignment.center,
                    radius: 1.2,
                  ),
          ),
          child: SafeArea(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Star Ornaments if background is shown
                if (themeConfig != null && themeConfig.showStars) ...[
                  Positioned(
                    top: 130,
                    left: 20,
                    child: Transform.rotate(
                      angle: -0.2,
                      child: const Icon(Icons.star_rounded, color: Color(0xFFFFD600), size: 36),
                    ),
                  ),
                  Positioned(
                    bottom: 230,
                    right: 18,
                    child: Transform.rotate(
                      angle: 0.3,
                      child: const Icon(Icons.star_rounded, color: Color(0xFFFFD600), size: 38),
                    ),
                  ),
                ],

                // mascot if theme config allows
                if (themeConfig != null && themeConfig.showMascot)
                  Positioned(
                    right: 8,
                    bottom: 120,
                    child: Image.asset(
                      'assets/images/char/kinz.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                  ),

                // Sophisticated Background Layers
                if (!isBg) ...[
                  // 1. Pulsing Rays
                  AnimatedBuilder(
                    animation: _shimmer,
                    builder: (context, child) {
                      return Opacity(
                        opacity: 0.3 + (0.2 * sin(_shimmer.value * 2 * pi)),
                        child: CustomPaint(
                          size: const Size(600, 600),
                          painter: _GachaRaysPainter(
                            color: _currentItem.color,
                            rotation: _shimmer.value * 2 * pi * 0.2, // Slower rotation
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // 2. Inner Glow
                  Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _currentItem.color.withValues(alpha: 0.4),
                          _currentItem.color.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 2.seconds, curve: Curves.easeInOut),
                ],

                // Active particle effect overlay
                if (isEffect)
                  Positioned.fill(
                    child: ProfileEffectWidget(effectId: _currentItem.id),
                  ),

                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Rarity label
                    Text(
                      _rarityLabel,
                      style: AppTextStyles.h2.copyWith(
                        color: _currentItem.color,
                        fontWeight: FontWeight.w900,
                    shadows: [
                          Shadow(color: _currentItem.color, blurRadius: 20),
                        ],
                      ),
                    ).animate(key: ValueKey(_revealIndex))
                        .fadeIn(duration: 400.ms)
                        .scale(begin: const Offset(0.2, 0.2), curve: Curves.elasticOut, duration: 800.ms)
                        .shimmer(delay: 800.ms, duration: 1.seconds, color: Colors.white24),

                    const SizedBox(height: 32),

                    // Main display based on item category
                    if (isBg && themeConfig != null)
                      // Preview Card
                      Container(
                        width: 280,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        decoration: BoxDecoration(
                          color: themeConfig.cardColor,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Colors.white24, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: themeConfig.cardColor.withValues(alpha: 0.5),
                              blurRadius: 30,
                              spreadRadius: -5,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('TEMA BARU', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 3)),
                            const SizedBox(height: 16),
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: themeConfig.id == 'crimson_spark' ? const Color(0xFFD32F2F) : const Color(0xFFFFECEF),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                              child: Center(
                                child: Image.asset('assets/images/char/kinz.png', width: 40, height: 40),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text('Pelajar', style: themeConfig.nameStyle.copyWith(fontSize: 28)),
                            const SizedBox(height: 8),
                            Text('Kelas 8, SMP Labschool', style: TextStyle(color: themeConfig.bodyTextColor, fontSize: 13, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ).animate(key: ValueKey('preview-$_revealIndex'))
                          .scale(begin: const Offset(0.4, 0.4), duration: 800.ms, curve: Curves.elasticOut)
                          .fadeIn(duration: 400.ms)
                          .then()
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .moveY(begin: -5, end: 5, duration: 2.seconds, curve: Curves.easeInOut)
                    else if (isSkin)
                      // Glowing avatar frame
                      Builder(builder: (context) {
                        final isPremium = _currentItem.rarity == 'mythical' || _currentItem.rarity == 'legendary';
                        Widget skinCard = Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _currentItem.color.withValues(alpha: isPremium ? 0.75 : 0.3),
                                blurRadius: isPremium ? 55 : 25,
                                spreadRadius: isPremium ? 12 : 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: IconHandler.buildItemIcon(_currentItem.emoji, size: 100, color: Colors.white),
                          ),
                        );

                        if (isPremium) {
                          skinCard = skinCard.animate(onPlay: (c) => c.repeat(reverse: true))
                              .shimmer(duration: 1800.ms, color: Colors.white30)
                              .scale(begin: const Offset(0.96, 0.96), end: const Offset(1.04, 1.04), duration: 1000.ms);
                        }

                        return skinCard.animate(key: ValueKey('emoji-$_revealIndex'))
                            .scale(begin: const Offset(0.0, 0.0), duration: 750.ms, curve: Curves.elasticOut)
                            .fadeIn(duration: 400.ms)
                            .then()
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .moveY(begin: -8, end: 8, duration: 1.5.seconds, curve: Curves.easeInOut);
                      })
                    else
                      // Generic effect / standard icon representation
                      Builder(builder: (context) {
                        final isPremium = _currentItem.rarity == 'mythical' || _currentItem.rarity == 'legendary';
                        Widget genericCard = Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              if (isPremium)
                                BoxShadow(
                                  color: _currentItem.color.withValues(alpha: 0.75),
                                  blurRadius: 55,
                                  spreadRadius: 12,
                                ),
                            ],
                          ),
                          child: IconHandler.buildItemIcon(_currentItem.emoji, size: 130, color: Colors.white),
                        );

                        if (isPremium) {
                          genericCard = genericCard.animate(onPlay: (c) => c.repeat(reverse: true))
                              .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 1200.ms);
                        }

                        return genericCard.animate(key: ValueKey('emoji-$_revealIndex'))
                            .scale(begin: const Offset(0.0, 0.0), duration: 700.ms, curve: Curves.elasticOut)
                            .fadeIn(duration: 400.ms)
                            .then()
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .moveY(begin: -5, end: 5, duration: 1.8.seconds, curve: Curves.easeInOut);
                      }),

                    const SizedBox(height: 32),

                    // Item name
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _currentItem.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.display.copyWith(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(color: _currentItem.color, blurRadius: 20),
                            Shadow(color: _currentItem.color.withValues(alpha: 0.5), blurRadius: 40),
                          ],
                        ),
                      ),
                    ).animate(key: ValueKey('name-$_revealIndex'))
                        .fadeIn(delay: 300.ms, duration: 500.ms)
                        .scale(begin: const Offset(0.8, 0.8), delay: 300.ms, duration: 500.ms, curve: Curves.easeOutBack),

                    const SizedBox(height: 16),

                    // Stars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _starCount,
                        (i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.star_rounded, color: Colors.amber, size: 32)
                              .animate()
                              .scale(
                                delay: Duration(milliseconds: 400 + 100 * i),
                                duration: 500.ms,
                                curve: Curves.elasticOut,
                              )
                              .shimmer(delay: 1.seconds, duration: 1.seconds),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _currentItem.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: _currentItem.color.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _currentItem.category == 'points'
                              ? Image.asset(
                                  'assets/images/diamond.png',
                                  width: 14,
                                  height: 14,
                                  fit: BoxFit.contain,
                                )
                              : Icon(
                                  switch (_currentItem.category) {
                                    'skin' => Icons.person_rounded,
                                    'background' => Icons.wallpaper_rounded,
                                    'effect' => Icons.auto_awesome_rounded,
                                    _ => Icons.stars_rounded,
                                  },
                                  color: _currentItem.color,
                                  size: 14,
                                ),
                          const SizedBox(width: 8),
                          Text(
                            (_currentItem.category == 'points' ? 'poin' : _currentItem.category).toUpperCase(),
                            style: AppTextStyles.label.copyWith(
                              color: _currentItem.color,
                              letterSpacing: 2,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),

                    const SizedBox(height: 48),

                    if (_isSingle)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: SdButton(
                          label: 'Selesai',
                          onPressed: () => Navigator.pop(context),
                        ).animate().fadeIn(delay: 700.ms),
                      )
                    else
                      Text(
                        'Ketuk layar untuk lanjut (${_revealIndex + 1}/${widget.results.length})',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.white38),
                      ).animate(onPlay: (c) => c.repeat(reverse: true))
                          .fadeIn(duration: 800.ms),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _MultiReveal() {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              '${widget.results.length}x Hasil Gacha',
              style: AppTextStyles.h2.copyWith(color: Colors.white),
            ).animate().fadeIn(),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: widget.results.length,
                  itemBuilder: (_, i) {
                    final item = widget.results[i];
                    final isBg = item.category == 'background';
                    final isEffect = item.category == 'effect';
                    final isSkin = item.category == 'skin';
                                    final themeConfig = isBg ? ProfileThemeConfig.fromId(item.id, '') : null;
                    final isPremium = item.rarity == 'mythical' || item.rarity == 'legendary';
                    final starCount = switch (item.rarity) {
                      'mythical' => 5,
                      'legendary' => 4,
                      'epic' => 3,
                      'rare' => 2,
                      _ => 1,
                    };

                    Widget gridCard = Container(
                      decoration: BoxDecoration(
                        color: isBg && themeConfig != null ? null : AppColors.darkNavyCard,
                        gradient: isBg && themeConfig != null && themeConfig.hasGradientBg
                            ? LinearGradient(
                                colors: [themeConfig.screenBgColorStart, themeConfig.screenBgColorEnd],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: item.color.withValues(alpha: 0.6), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: item.color.withValues(alpha: isEffect ? 0.45 : 0.25),
                            blurRadius: isEffect ? 12 : 8,
                            spreadRadius: isEffect ? 2 : 0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isSkin)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white12,
                                shape: BoxShape.circle,
                              ),
                              child: IconHandler.buildItemIcon(item.emoji, size: 24, color: Colors.white),
                            )
                          else
                            IconHandler.buildItemIcon(item.emoji, size: 28, color: Colors.white),
                          const SizedBox(height: 6),
                          Text(
                            item.name,
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 9,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              starCount,
                              (_) => const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFD600),
                                size: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (isPremium) {
                      gridCard = gridCard.animate(onPlay: (c) => c.repeat(reverse: true))
                          .shimmer(duration: 1500.ms, color: Colors.white24)
                          .scale(begin: const Offset(0.97, 0.97), end: const Offset(1.03, 1.03), duration: 1200.ms);
                    }

                    return gridCard
                        .animate()
                        .scale(delay: Duration(milliseconds: 50 * i), duration: 300.ms, curve: Curves.easeOut)
                        .fadeIn(delay: Duration(milliseconds: 50 * i));
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SdButton(
                label: 'Selesai',
                onPressed: () => Navigator.pop(context),
              ).animate().fadeIn(delay: 500.ms),
            ),
          ],
        ),
      ),
    );
  }
}

class _GachaRaysPainter extends CustomPainter {
  final Color color;
  final double rotation;

  _GachaRaysPainter({required this.color, required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.8),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius / 2));

    const int rayCount = 16;
    const double rayAngle = (2 * pi) / rayCount;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);

    for (int i = 0; i < rayCount; i++) {
      final path = Path();
      path.moveTo(center.dx, center.dy);
      path.arcToPoint(
        Offset(
          center.dx + radius * cos(i * rayAngle - rayAngle / 4),
          center.dy + radius * sin(i * rayAngle - rayAngle / 4),
        ),
      );
      path.lineTo(
        center.dx + radius * cos(i * rayAngle + rayAngle / 4),
        center.dy + radius * sin(i * rayAngle + rayAngle / 4),
      );
      path.close();
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GachaRaysPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.rotation != rotation;
}
