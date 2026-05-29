import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProfileEffectWidget extends StatelessWidget {
  final String? effectId;
  const ProfileEffectWidget({super.key, this.effectId});

  @override
  Widget build(BuildContext context) {
    if (effectId == null || effectId == 'classic' || effectId!.isEmpty) {
      return const SizedBox.shrink();
    }

    final rand = Random(effectId.hashCode);

    if (effectId == 'star_spark') {
      return Stack(
        clipBehavior: Clip.none,
        children: List.generate(12, (index) {
          final left = rand.nextDouble() * 320;
          final topStart = 200 + rand.nextDouble() * 300;
          final size = 12.0 + rand.nextDouble() * 16.0;
          final duration = 2000 + rand.nextInt(2500); // 2s to 4.5s
          final delay = rand.nextInt(1500); // Up to 1.5s delay
          final emoji = rand.nextBool() ? '✨' : '⭐';

          return Positioned(
            left: left,
            top: topStart,
            child: Text(
              emoji,
              style: TextStyle(fontSize: size),
            )
                .animate(
                  onPlay: (controller) => controller.repeat(),
                  delay: delay.ms,
                )
                .fadeIn(duration: 600.ms)
                .moveY(
                  begin: 100,
                  end: -250,
                  duration: duration.ms,
                  curve: Curves.easeOut,
                )
                .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1.2, 1.2),
                  duration: duration.ms,
                )
                .fadeOut(
                  delay: (duration - 600).ms,
                  duration: 600.ms,
                ),
          );
        }),
      );
    } else if (effectId == 'sun_blaster') {
      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Ambient warm solar glow in the center
          Center(
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFB703).withValues(alpha: 0.16),
                    blurRadius: 45,
                    spreadRadius: 25,
                  ),
                ],
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(0.85, 0.85),
                  end: const Offset(1.15, 1.15),
                  duration: 2500.ms,
                  curve: Curves.easeInOut,
                ),
          ),
          // Drifting sun embers
          ...List.generate(10, (index) {
            final left = rand.nextDouble() * 320;
            final topStart = 250 + rand.nextDouble() * 250;
            final size = 8.0 + rand.nextDouble() * 12.0;
            final duration = 2500 + rand.nextInt(2000);
            final delay = rand.nextInt(1200);

            return Positioned(
              left: left,
              top: topStart,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFB703).withValues(
                    alpha: 0.25 + rand.nextDouble() * 0.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF8F00).withValues(alpha: 0.3),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              )
                  .animate(
                    onPlay: (controller) => controller.repeat(),
                    delay: delay.ms,
                  )
                  .fadeIn(duration: 500.ms)
                  .moveY(
                    begin: 120,
                    end: -280,
                    duration: duration.ms,
                    curve: Curves.easeIn,
                  )
                  .fadeOut(
                    delay: (duration - 600).ms,
                    duration: 600.ms,
                  ),
            );
          }),
        ],
      );
    } else if (effectId == 'thunder_blade') {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          // Subtle electric sparks and neon lightning bolts around the card
          ...List.generate(8, (index) {
            final left = rand.nextDouble() * 320;
            final top = 80 + rand.nextDouble() * 450;
            final size = 16.0 + rand.nextDouble() * 14.0;
            final duration = 1200 + rand.nextInt(1000); // Fast flashing
            final delay = rand.nextInt(2000);

            return Positioned(
              left: left,
              top: top,
              child: Icon(
                Icons.flash_on_rounded,
                color: const Color(0xFF00E5FF),
                size: size,
              )
                  .animate(
                    onPlay: (controller) => controller.repeat(),
                    delay: delay.ms,
                  )
                  .fadeIn(duration: 80.ms)
                  .scale(
                    begin: const Offset(0.3, 0.3),
                    end: const Offset(1.1, 1.1),
                    duration: (duration * 0.15).toInt().ms,
                    curve: Curves.elasticOut,
                  )
                  .shake(
                    hz: 7,
                    duration: (duration * 0.3).toInt().ms,
                    curve: Curves.easeInOut,
                  )
                  .fadeOut(
                    delay: (duration * 0.4).toInt().ms,
                    duration: (duration * 0.25).toInt().ms,
                  ),
            );
          }),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
