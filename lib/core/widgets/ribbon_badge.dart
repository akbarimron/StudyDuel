import 'dart:math';
import 'package:flutter/material.dart';

class RibbonBadge extends StatelessWidget {
  final String type;
  final bool earned;
  final double size;

  const RibbonBadge({
    super.key,
    required this.type,
    required this.earned,
    this.size = 68,
  });

  @override
  Widget build(BuildContext context) {
    Color mainColor;
    Color darkColor;
    Widget iconWidget;

    // Define colors and icons for each badge ID
    switch (type) {
      case 'top10':
        mainColor = const Color(0xFF906CD4); // Purple
        darkColor = const Color(0xFF6F4EA8); // Dark purple
        iconWidget = Text(
          '#10',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.28,
            fontFamily: 'Nunito',
          ),
        );
        break;
      case 'win100':
        mainColor = const Color(0xFFEAA62B); // Gold/Yellow
        darkColor = const Color(0xFFC28213); // Dark gold
        iconWidget = Icon(
          Icons.emoji_events_rounded,
          color: Colors.white,
          size: size * 0.45,
        );
        break;
      case 'ipa_expert':
        mainColor = const Color(0xFF5A87DE); // Blue
        darkColor = const Color(0xFF3F63A8); // Dark blue
        iconWidget = Icon(
          Icons.science_rounded,
          color: Colors.white,
          size: size * 0.45,
        );
        break;
      case 'math_master':
        mainColor = const Color(0xFFDE5B5B); // Red
        darkColor = const Color(0xFFB53E3E); // Dark red
        iconWidget = Icon(
          Icons.calculate_rounded,
          color: Colors.white,
          size: size * 0.45,
        );
        break;
      case 'social_star':
        mainColor = const Color(0xFF4FA84F); // Green
        darkColor = const Color(0xFF387E38); // Dark green
        iconWidget = Icon(
          Icons.public_rounded,
          color: Colors.white,
          size: size * 0.45,
        );
        break;
      case 'bahasa_boss':
        mainColor = const Color(0xFF7B1FA2); // Purple-violet
        darkColor = const Color(0xFF5E137D);
        iconWidget = Icon(
          Icons.menu_book_rounded,
          color: Colors.white,
          size: size * 0.45,
        );
        break;
      case 'pioneer':
        mainColor = const Color(0xFF2EA2C2); // Cyan
        darkColor = const Color(0xFF1B7791);
        iconWidget = Icon(
          Icons.military_tech_rounded,
          color: Colors.white,
          size: size * 0.48,
        );
        break;
      case 'first_duel':
        mainColor = const Color(0xFFE65100); // Orange
        darkColor = const Color(0xFFB33E00);
        iconWidget = Icon(
          Icons.flash_on_rounded,
          color: Colors.white,
          size: size * 0.45,
        );
        break;
      case 'first_gacha':
        mainColor = const Color(0xFFD81B60); // Pink
        darkColor = const Color(0xFFA00F43);
        iconWidget = Icon(
          Icons.casino_rounded,
          color: Colors.white,
          size: size * 0.45,
        );
        break;
      case 'collector':
        mainColor = const Color(0xFF8D6E63); // Brown
        darkColor = const Color(0xFF5D4037);
        iconWidget = Icon(
          Icons.backpack_rounded,
          color: Colors.white,
          size: size * 0.45,
        );
        break;
      default:
        mainColor = const Color(0xFF8A9BB8); // Blue-grey
        darkColor = const Color(0xFF6E809D);
        iconWidget = Icon(
          Icons.stars_rounded,
          color: Colors.white,
          size: size * 0.45,
        );
        break;
    }

    // Apply grayscale if locked
    if (!earned) {
      mainColor = const Color(0xFFB0BEC5); // Blue-grey light (locked look)
      darkColor = const Color(0xFF78909C); // Blue-grey dark
      iconWidget = Opacity(
        opacity: 0.6,
        child: ColorFiltered(
          colorFilter: const ColorFilter.mode(
            Color(0xFF78909C),
            BlendMode.srcIn,
          ),
          child: iconWidget,
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size * 1.25,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Ribbon Tails
          Positioned(
            bottom: 0,
            child: CustomPaint(
              size: Size(size * 0.72, size * 0.55),
              painter: RibbonTailsPainter(color: darkColor),
            ),
          ),
          // Decagon Shield Body
          Positioned(
            top: 0,
            child: CustomPaint(
              size: Size(size, size),
              painter: BadgeShieldPainter(color: mainColor),
              child: SizedBox(
                width: size,
                height: size,
                child: Center(
                  child: iconWidget,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BadgeShieldPainter extends CustomPainter {
  final Color color;
  BadgeShieldPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double r = w / 2;

    // Draw decagon path (10 sides)
    final path = Path();
    const int sides = 10;
    for (int i = 0; i < sides; i++) {
      final double angle = (i * 2 * pi) / sides - pi / 2;
      final double x = cx + r * 0.98 * cos(angle);
      final double y = cy + r * 0.98 * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Draw shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawPath(path.shift(const Offset(0, 2.5)), shadowPaint);

    // Draw main decagon body
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    // Draw outer golden-yellow/white highlights or border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = w * 0.04
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(cx, cy), r * 0.8, borderPaint);

    // Add extra inner decagon border line
    final innerPath = Path();
    const double innerR = 0.72;
    for (int i = 0; i < sides; i++) {
      final double angle = (i * 2 * pi) / sides - pi / 2;
      final double x = cx + r * innerR * cos(angle);
      final double y = cy + r * innerR * sin(angle);
      if (i == 0) {
        innerPath.moveTo(x, y);
      } else {
        innerPath.lineTo(x, y);
      }
    }
    innerPath.close();

    final innerBorderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = w * 0.02
      ..style = PaintingStyle.stroke;
    canvas.drawPath(innerPath, innerBorderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RibbonTailsPainter extends CustomPainter {
  final Color color;
  RibbonTailsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Draw left tail
    final leftPath = Path()
      ..moveTo(w * 0.28, 0)
      ..lineTo(w * 0.44, 0)
      ..lineTo(w * 0.38, h)
      ..lineTo(w * 0.22, h * 0.78) // Notch
      ..lineTo(w * 0.08, h)
      ..close();

    // Draw right tail
    final rightPath = Path()
      ..moveTo(w * 0.56, 0)
      ..lineTo(w * 0.72, 0)
      ..lineTo(w * 0.92, h)
      ..lineTo(w * 0.78, h * 0.78) // Notch
      ..lineTo(w * 0.62, h)
      ..close();

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawPath(leftPath.shift(const Offset(0, 1.5)), shadowPaint);
    canvas.drawPath(rightPath.shift(const Offset(0, 1.5)), shadowPaint);

    // Fill
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(leftPath, paint);
    canvas.drawPath(rightPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
