import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/sd_button.dart';
import 'gacha_screen.dart';
import '../../core/theme/profile_theme.dart';
import '../../core/widgets/profile_effect.dart';

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
    return switch (_currentItem.rarity) {
      'mythical' => 'Mythical Diperoleh!',
      'legendary' => 'Legendary Diperoleh!',
      'epic' => 'Epic Diperoleh!',
      'rare' => 'Rare Diperoleh!',
      _ => 'Diperoleh!',
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

                // Mascot if background is shown
                if (themeConfig != null && themeConfig.showMascot)
                  Positioned(
                    right: 8,
                    bottom: 120,
                    child: Image.asset(
                      'assets/images/mascot.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                  ),

                // Active particle effect overlay
                if (isEffect)
                  Positioned.fill(
                    child: ProfileEffectWidget(effectId: _currentItem.id),
                  ),

                // Rotating background glow (only for non-backgrounds or generic ones)
                if (!isBg)
                  AnimatedBuilder(
                    animation: _shimmer,
                    builder: (_, __) => Transform.rotate(
                      angle: _shimmer.value * 2 * 3.14159,
                      child: Container(
                        width: 320,
                        height: 320,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              _currentItem.color.withValues(alpha: 0.0),
                              _currentItem.color.withValues(alpha: 0.3),
                              _currentItem.color.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
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
                        .scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut, duration: 600.ms),

                    const SizedBox(height: 24),

                    // Main display based on item category
                    if (isBg && themeConfig != null)
                      // Preview Card
                      Container(
                        width: 260,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        decoration: BoxDecoration(
                          color: themeConfig.cardColor,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white24, width: 1.5),
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 15, offset: const Offset(0, 5)),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('TEMA BARU', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                            const SizedBox(height: 12),
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: themeConfig.id == 'crimson_spark' ? const Color(0xFFD32F2F) : const Color(0xFFFFECEF),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(child: Text('🧑', style: TextStyle(fontSize: 32))),
                            ),
                            const SizedBox(height: 12),
                            Text('Pelajar', style: themeConfig.nameStyle.copyWith(fontSize: 24)),
                            const SizedBox(height: 8),
                            Text('Kelas 8, SMP Labschool', style: TextStyle(color: themeConfig.bodyTextColor, fontSize: 11, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ).animate(key: ValueKey('preview-$_revealIndex'))
                          .scale(begin: const Offset(0.4, 0.4), duration: 700.ms, curve: Curves.elasticOut)
                          .fadeIn(duration: 400.ms)
                    else if (isSkin)
                      // Glowing avatar frame
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          shape: BoxShape.circle,
                          border: Border.all(color: _currentItem.color, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: _currentItem.color.withValues(alpha: 0.4),
                              blurRadius: 25,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _currentItem.emoji,
                            style: const TextStyle(fontSize: 85),
                          ),
                        ),
                      ).animate(key: ValueKey('emoji-$_revealIndex'))
                          .scale(begin: const Offset(0.0, 0.0), duration: 750.ms, curve: Curves.elasticOut)
                          .fadeIn(duration: 400.ms)
                    else
                      // Generic effect / standard emoji representation
                      Text(
                        _currentItem.emoji,
                        style: const TextStyle(fontSize: 130),
                      ).animate(key: ValueKey('emoji-$_revealIndex'))
                          .scale(begin: const Offset(0.0, 0.0), duration: 700.ms, curve: Curves.elasticOut)
                          .fadeIn(duration: 400.ms),

                    const SizedBox(height: 24),

                    // Item name
                    Text(
                      _currentItem.name,
                      style: AppTextStyles.display.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(color: _currentItem.color, blurRadius: 16),
                        ],
                      ),
                    ).animate(key: ValueKey('name-$_revealIndex'))
                        .fadeIn(delay: 300.ms, duration: 400.ms),

                    const SizedBox(height: 12),

                    // Stars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _starCount,
                        (i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: const Text('⭐', style: TextStyle(fontSize: 24))
                              .animate()
                              .scale(
                                delay: Duration(milliseconds: 100 + 100 * i),
                                duration: 400.ms,
                                curve: Curves.elasticOut,
                              ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: _currentItem.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: _currentItem.color.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        _currentItem.category.toUpperCase(),
                        style: AppTextStyles.label.copyWith(
                          color: _currentItem.color,
                          letterSpacing: 2,
                          fontSize: 11,
                        ),
                      ),
                    ).animate().fadeIn(delay: 500.ms),

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
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.7,
                ),
                itemCount: widget.results.length,
                itemBuilder: (_, i) {
                  final item = widget.results[i];
                  final isBg = item.category == 'background';
                  final isEffect = item.category == 'effect';
                  final isSkin = item.category == 'skin';
                  
                  final themeConfig = isBg ? ProfileThemeConfig.fromId(item.id, '') : null;

                  return Container(
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
                            child: Text(item.emoji, style: const TextStyle(fontSize: 24)),
                          )
                        else
                          Text(item.emoji, style: const TextStyle(fontSize: 28)),
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
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: item.color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.rarity.substring(0, 3).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .scale(delay: Duration(milliseconds: 50 * i), duration: 300.ms, curve: Curves.easeOut)
                      .fadeIn(delay: Duration(milliseconds: 50 * i));
                },
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
