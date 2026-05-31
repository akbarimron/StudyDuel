import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class StudyDuelLogo extends StatelessWidget {
  final double size;
  final bool isDark;

  const StudyDuelLogo({
    super.key,
    this.size = 32,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(size * 0.2),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(size * 0.3),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: size * 0.5,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            Icons.menu_book_rounded,
            color: Colors.white,
            size: size,
          ),
        ),
        SizedBox(height: size * 0.25),
        RichText(
          text: TextSpan(
            style: AppTextStyles.h1.copyWith(
              fontSize: size * 0.8,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : AppColors.darkNavy,
            ),
            children: [
              const TextSpan(text: 'Study'),
              TextSpan(
                text: 'DUell',
                style: TextStyle(
                  color: AppColors.primary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
