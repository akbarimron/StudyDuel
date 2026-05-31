import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class StreakChip extends StatelessWidget {
  final int streak;
  const StreakChip({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accentSurface,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.accent, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.whatshot_rounded, color: Colors.orange, size: 16),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: AppTextStyles.label.copyWith(
              color: AppColors.accentDark,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class GemsChip extends StatelessWidget {
  final int gems;
  const GemsChip({super.key, required this.gems});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.primaryLight, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/diamond.png',
            width: 16,
            height: 16,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 4),
          Text(
            '$gems',
            style: AppTextStyles.label.copyWith(
              color: AppColors.primary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
