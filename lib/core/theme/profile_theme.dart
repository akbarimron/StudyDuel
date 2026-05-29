import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class ProfileThemeConfig {
  final String id;
  final Color screenBgColorStart;
  final Color screenBgColorEnd;
  final bool hasGradientBg;
  final Color cardColor;
  final Color statsBoxColor;
  final Color statsBoxBorderColor;
  final Color nameColor;
  final TextStyle nameStyle;
  final Color progressBarColor;
  final bool showMascot;
  final bool showStars;
  final Color labelTextColor;
  final Color bodyTextColor;

  ProfileThemeConfig({
    required this.id,
    required this.screenBgColorStart,
    required this.screenBgColorEnd,
    required this.hasGradientBg,
    required this.cardColor,
    required this.statsBoxColor,
    required this.statsBoxBorderColor,
    required this.nameColor,
    required this.nameStyle,
    required this.progressBarColor,
    required this.showMascot,
    required this.showStars,
    required this.labelTextColor,
    required this.bodyTextColor,
  });

  factory ProfileThemeConfig.fromId(String? id, String name) {
    if (id == 'crimson_spark') {
      return ProfileThemeConfig(
        id: 'crimson_spark',
        screenBgColorStart: const Color(0xFF2E1916), // Rich reddish brown
        screenBgColorEnd: const Color(0xFF1E0E0B),
        hasGradientBg: true,
        cardColor: const Color(0xFF502722), // Semi-dark reddish card
        statsBoxColor: Colors.white,
        statsBoxBorderColor: const Color(0xFFE2E2E2),
        nameColor: const Color(0xFFFFD600), // Cursive yellow
        nameStyle: GoogleFonts.caveat(
          color: const Color(0xFFFFD600),
          fontSize: 32,
          fontWeight: FontWeight.w900,
        ),
        progressBarColor: const Color(0xFFFFB703), // Orange-yellow progress bar
        showMascot: true,
        showStars: true,
        labelTextColor: Colors.white,
        bodyTextColor: Colors.white70,
      );
    } else if (id == 'galaxy_requiem') {
      return ProfileThemeConfig(
        id: 'galaxy_requiem',
        screenBgColorStart: const Color(0xFF0F0C1B), // Deep space gradient
        screenBgColorEnd: const Color(0xFF241635),
        hasGradientBg: true,
        cardColor: const Color(0xFF271A3F), // Deep purple card
        statsBoxColor: Colors.white.withValues(alpha: 0.12),
        statsBoxBorderColor: Colors.white24,
        nameColor: Colors.white,
        nameStyle: GoogleFonts.orbitron(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
        progressBarColor: const Color(0xFF906CD4), // Purple progress bar
        showMascot: false,
        showStars: false,
        labelTextColor: Colors.white,
        bodyTextColor: Colors.white70,
      );
    } else if (id == 'neon_cyberpunk') {
      return ProfileThemeConfig(
        id: 'neon_cyberpunk',
        screenBgColorStart: const Color(0xFF05050A),
        screenBgColorEnd: const Color(0xFF120E2E),
        hasGradientBg: true,
        cardColor: const Color(0xFF1D1B2E),
        statsBoxColor: Colors.black26,
        statsBoxBorderColor: const Color(0xFF00F0FF),
        nameColor: const Color(0xFFFF007F),
        nameStyle: GoogleFonts.orbitron(
          color: const Color(0xFFFF007F),
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
        progressBarColor: const Color(0xFF00F0FF),
        showMascot: false,
        showStars: true,
        labelTextColor: Colors.white,
        bodyTextColor: Colors.white70,
      );
    } else if (id == 'forest_serenade') {
      return ProfileThemeConfig(
        id: 'forest_serenade',
        screenBgColorStart: const Color(0xFF1B2E1E),
        screenBgColorEnd: const Color(0xFF0A140C),
        hasGradientBg: true,
        cardColor: const Color(0xFF253B28),
        statsBoxColor: Colors.white.withValues(alpha: 0.08),
        statsBoxBorderColor: const Color(0xFF8EF39F),
        nameColor: const Color(0xFF8EF39F),
        nameStyle: GoogleFonts.outfit(
          color: const Color(0xFF8EF39F),
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
        progressBarColor: const Color(0xFF52B788),
        showMascot: false,
        showStars: false,
        labelTextColor: Colors.white,
        bodyTextColor: Colors.white70,
      );
    } else if (id == 'sunset_breeze') {
      return ProfileThemeConfig(
        id: 'sunset_breeze',
        screenBgColorStart: const Color(0xFF3B1A2E),
        screenBgColorEnd: const Color(0xFF5E2B38),
        hasGradientBg: true,
        cardColor: const Color(0xFF7E3547),
        statsBoxColor: Colors.white.withValues(alpha: 0.1),
        statsBoxBorderColor: const Color(0xFFFFC107),
        nameColor: const Color(0xFFFFC107),
        nameStyle: GoogleFonts.outfit(
          color: const Color(0xFFFFC107),
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
        progressBarColor: const Color(0xFFFFC107),
        showMascot: true,
        showStars: true,
        labelTextColor: Colors.white,
        bodyTextColor: Colors.white70,
      );
    } else {
      // Default / Classic theme
      return ProfileThemeConfig(
        id: 'classic',
        screenBgColorStart: AppColors.background,
        screenBgColorEnd: AppColors.background,
        hasGradientBg: false,
        cardColor: AppColors.surface,
        statsBoxColor: AppColors.surface,
        statsBoxBorderColor: const Color(0xFFEAEAEA),
        nameColor: AppColors.textPrimary,
        nameStyle: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w900),
        progressBarColor: const Color(0xFF52B788), // Green progress bar
        showMascot: false,
        showStars: false,
        labelTextColor: AppColors.textPrimary,
        bodyTextColor: AppColors.textSecondary,
      );
    }
  }
}
