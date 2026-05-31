import 'dart:math';
import 'package:flutter/material.dart';

class ProfileEffectWidget extends StatefulWidget {
  final String? effectId;
  const ProfileEffectWidget({super.key, this.effectId});

  @override
  State<ProfileEffectWidget> createState() => _ProfileEffectWidgetState();
}

class _ProfileEffectWidgetState extends State<ProfileEffectWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(_updateParticles);
    
    if (widget.effectId != null && widget.effectId!.isNotEmpty) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ProfileEffectWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.effectId != oldWidget.effectId) {
      _particles.clear();
      if (widget.effectId != null && widget.effectId!.isNotEmpty) {
        if (!_controller.isAnimating) {
          _controller.repeat();
        }
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateParticles() {
    if (!mounted || widget.effectId == null || widget.effectId!.isEmpty) return;

    final id = widget.effectId!.toLowerCase();
    double spawnChance = 0.08;
    if (id.contains('matrix')) spawnChance = 0.15;
    if (id.contains('bubble') || id.contains('aqua')) spawnChance = 0.18; // Spawn bubbles more frequently
    
    final maxCount = (id.contains('bubble') || id.contains('aqua')) ? 35 : 25;
    
    if (_rand.nextDouble() < spawnChance && _particles.length < maxCount) {
      _particles.add(_Particle.generate(widget.effectId!, _rand));
    }

    setState(() {
      for (var p in _particles) {
        p.update();
      }
      _particles.removeWhere((p) => p.isDead);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.effectId == null || widget.effectId!.isEmpty || widget.effectId == 'classic') {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        for (var p in _particles) {
          p.setBounds(constraints.maxWidth, constraints.maxHeight);
        }

        return Stack(
          clipBehavior: Clip.none,
          children: _particles.map((p) {
            final id = p.effectId.toLowerCase();
            final isBubble = id.contains('bubble') || id.contains('aqua');
            return Positioned(
              left: p.x,
              top: p.y,
              child: Opacity(
                opacity: p.opacity,
                child: Transform.rotate(
                  angle: p.angle,
                  child: isBubble
                      ? CustomPaint(
                          size: Size(p.size, p.size),
                          painter: _GlossyBubblePainter(),
                        )
                      : id.contains('matrix')
                          ? Text(
                              p.char,
                              style: TextStyle(
                                fontSize: p.size,
                                color: p.color,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : Icon(
                              p.iconData,
                              size: p.size,
                              color: p.color?.withOpacity(p.opacity),
                            ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _GlossyBubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Soft bubble shell gradient
    final shellPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.8),
          Colors.white.withOpacity(0.15),
        ],
        stops: const [0.85, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    // Soft inner glow fill
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.02),
          Colors.white.withOpacity(0.18),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    // Paint fill and shell
    canvas.drawCircle(center, radius, fillPaint);
    canvas.drawCircle(center, radius, shellPaint);

    // Glossy highlights (reflective light arc)
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // Draw main light highlight near top-left
    canvas.drawOval(
      Rect.fromLTWH(
        radius * 0.4,
        radius * 0.3,
        radius * 0.45,
        radius * 0.3,
      ),
      highlightPaint,
    );

    // Draw secondary soft reflection at bottom-right
    final softHighlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawOval(
      Rect.fromLTWH(
        radius * 1.1,
        radius * 1.2,
        radius * 0.3,
        radius * 0.2,
      ),
      softHighlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Particle {
  final String effectId;
  final Random rand;
  
  double x = 0;
  double y = 0;
  double vx = 0;
  double vy = 0;
  double size = 12;
  double opacity = 1.0;
  double fadeSpeed = 0.015;
  double angle = 0;
  double rotationSpeed = 0;
  IconData iconData = Icons.circle;
  String char = '';
  Color? color;

  bool _initialized = false;
  double _height = 100;

  _Particle.generate(this.effectId, this.rand) {
    final id = effectId.toLowerCase();
    if (id.contains('fire') || id.contains('sun_blaster')) {
      iconData = Icons.local_fire_department_rounded;
      size = 14 + rand.nextDouble() * 12;
      vy = -1.2 - rand.nextDouble() * 1.5;
      vx = -0.3 + rand.nextDouble() * 0.6;
      fadeSpeed = 0.01 + rand.nextDouble() * 0.01;
      rotationSpeed = -0.05 + rand.nextDouble() * 0.1;
      color = Colors.orangeAccent;
    } else if (id.contains('star') || id.contains('spark')) {
      iconData = rand.nextBool() ? Icons.auto_awesome_rounded : Icons.star_rounded;
      size = 12 + rand.nextDouble() * 14;
      vy = -0.3 - rand.nextDouble() * 0.5;
      vx = -0.4 + rand.nextDouble() * 0.8;
      fadeSpeed = 0.008 + rand.nextDouble() * 0.01;
      rotationSpeed = 0.05 + rand.nextDouble() * 0.05;
      color = Colors.yellowAccent;
    } else if (id.contains('bubble') || id.contains('aqua')) {
      iconData = Icons.circle_outlined;
      size = 16 + rand.nextDouble() * 24;
      vy = -0.6 - rand.nextDouble() * 1.0;
      vx = -0.4 + rand.nextDouble() * 0.8;
      fadeSpeed = 0.004 + rand.nextDouble() * 0.006;
      color = Colors.white.withValues(alpha: 0.3);
    } else if (id.contains('sakura') || id.contains('breeze')) {
      iconData = Icons.filter_vintage_rounded;
      size = 12 + rand.nextDouble() * 14;
      vy = 0.8 + rand.nextDouble() * 1.0;
      vx = -0.6 + rand.nextDouble() * 0.6;
      fadeSpeed = 0.006 + rand.nextDouble() * 0.008;
      rotationSpeed = -0.03 + rand.nextDouble() * 0.06;
      color = const Color(0xFFFFC1CC);
    } else if (id.contains('matrix') || id.contains('digital')) {
      char = rand.nextBool() ? '0' : '1';
      size = 10 + rand.nextDouble() * 10;
      vy = 2.0 + rand.nextDouble() * 2.0;
      vx = 0;
      fadeSpeed = 0.015 + rand.nextDouble() * 0.01;
      color = const Color(0xFF00FF00);
    } else if (id.contains('thunder') || id.contains('blade')) {
      iconData = Icons.bolt_rounded;
      size = 14 + rand.nextDouble() * 14;
      vy = -0.8 - rand.nextDouble() * 1.0;
      vx = -0.6 + rand.nextDouble() * 1.2;
      fadeSpeed = 0.01 + rand.nextDouble() * 0.01;
      rotationSpeed = -0.1 + rand.nextDouble() * 0.2;
      color = const Color(0xFF00E5FF);
    }
  }

  void setBounds(double width, double height) {
    if (_initialized) return;
    _height = height;
    _initialized = true;

    x = rand.nextDouble() * width;
    final id = effectId.toLowerCase();
    if (id.contains('sakura') || id.contains('breeze') || id.contains('matrix') || id.contains('digital')) {
      y = -20;
    } else {
      y = height + 10;
    }
  }

  void update() {
    x += vx;
    y += vy;
    angle += rotationSpeed;
    opacity = max(0, opacity - fadeSpeed);
    
    final id = effectId.toLowerCase();
    if (id.contains('bubble') || id.contains('aqua')) {
      vx += sin(y / 20) * 0.08;
    }
  }

  bool get isDead => opacity <= 0.01 || y < -30 || y > _height + 30;
}

class AnimatedGradientWrapper extends StatefulWidget {
  final List<Color> colors;
  final Widget child;
  const AnimatedGradientWrapper({super.key, required this.colors, required this.child});

  @override
  State<AnimatedGradientWrapper> createState() => _AnimatedGradientWrapperState();
}

class _AnimatedGradientWrapperState extends State<AnimatedGradientWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _topAlignmentAnimation;
  late Animation<Alignment> _bottomAlignmentAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);

    _topAlignmentAnimation = TweenSequence<Alignment>([
      TweenSequenceItem(
        tween: Tween<Alignment>(begin: Alignment.topLeft, end: Alignment.topRight),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<Alignment>(begin: Alignment.topRight, end: Alignment.bottomRight),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<Alignment>(begin: Alignment.bottomRight, end: Alignment.bottomLeft),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<Alignment>(begin: Alignment.bottomLeft, end: Alignment.topLeft),
        weight: 1,
      ),
    ]).animate(_controller);

    _bottomAlignmentAnimation = TweenSequence<Alignment>([
      TweenSequenceItem(
        tween: Tween<Alignment>(begin: Alignment.bottomRight, end: Alignment.bottomLeft),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<Alignment>(begin: Alignment.bottomLeft, end: Alignment.topLeft),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<Alignment>(begin: Alignment.topLeft, end: Alignment.topRight),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<Alignment>(begin: Alignment.topRight, end: Alignment.bottomRight),
        weight: 1,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.colors,
              begin: _topAlignmentAnimation.value,
              end: _bottomAlignmentAnimation.value,
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
