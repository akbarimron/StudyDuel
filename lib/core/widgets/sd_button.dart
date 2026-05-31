import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum SdButtonVariant { primary, secondary, success, outline, ghost }

class SdButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final SdButtonVariant variant;
  final Widget? prefixIcon;
  final bool isLoading;
  final bool fullWidth;
  final double height;

  const SdButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = SdButtonVariant.primary,
    this.prefixIcon,
    this.isLoading = false,
    this.fullWidth = true,
    this.height = 56,
  });

  @override
  State<SdButton> createState() => _SdButtonState();
}

class _SdButtonState extends State<SdButton> {
  bool _pressed = false;

  Color get _bgColor => switch (widget.variant) {
        SdButtonVariant.primary => AppColors.primary,
        SdButtonVariant.secondary => AppColors.secondary,
        SdButtonVariant.success => AppColors.success,
        SdButtonVariant.outline => Colors.transparent,
        SdButtonVariant.ghost => Colors.transparent,
      };

  Color get _shadowColor => switch (widget.variant) {
        SdButtonVariant.primary => AppColors.primaryDark,
        SdButtonVariant.secondary => AppColors.secondaryDark,
        SdButtonVariant.success => AppColors.successDark,
        SdButtonVariant.outline => const Color.fromARGB(255, 255, 255, 255),
        SdButtonVariant.ghost => Colors.transparent,
      };

  Color get _textColor => switch (widget.variant) {
        SdButtonVariant.outline => AppColors.primary,
        SdButtonVariant.ghost => AppColors.textSecondary,
        _ => Colors.white,
      };

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!isDisabled && !widget.isLoading) widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: widget.fullWidth ? double.infinity : null,
        height: widget.height,
        transform: Matrix4.translationValues(0, _pressed ? 3 : 0, 0),
        decoration: BoxDecoration(
          color: isDisabled
              ? AppColors.border
              : (_pressed ? _shadowColor : _bgColor),
          borderRadius: BorderRadius.circular(16),
          border: widget.variant == SdButtonVariant.outline
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
          boxShadow: (widget.variant == SdButtonVariant.ghost || _pressed)
              ? null
              : [
                  BoxShadow(
                    color: isDisabled ? Colors.transparent : _shadowColor,
                    offset: const Offset(0, 4),
                    blurRadius: 0,
                    spreadRadius: 0,
                  ),
                ],
        ),
        child: Center(
          child: widget.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.prefixIcon != null) ...[
                      widget.prefixIcon!,
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: AppTextStyles.button.copyWith(
                        color: isDisabled ? AppColors.textHint : _textColor,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
