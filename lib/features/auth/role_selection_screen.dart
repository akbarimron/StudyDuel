import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/firebase_service.dart';

enum UserRole { siswa, orangTua, guru }

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  void _confirmRole(BuildContext context, UserRole role) {
    final labels = {
      UserRole.siswa: 'Siswa',
      UserRole.orangTua: 'Orang Tua',
      UserRole.guru: 'Guru',
    };
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ConfirmDialog(
        roleLabel: labels[role]!,
        onConfirm: () async {
          Navigator.of(context).pop();
          final uid = FirebaseService().currentUser?.uid;
          if (uid != null) {
            final roleString = {
              UserRole.siswa: 'siswa',
              UserRole.orangTua: 'orang_tua',
              UserRole.guru: 'guru',
            }[role]!;
            
            try {
              await FirebaseService().updateUserField(uid, {'role': roleString});
              if (context.mounted) {
                if (role == UserRole.siswa) {
                  Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
                } else {
                  Navigator.pushReplacementNamed(context, AppRoutes.home);
                }
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal menyimpan role: $e')),
                );
              }
            }
          } else {
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          }
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Dekorasi bintang
          const Positioned(top: 140, right: 24, child: Text('⭐', style: TextStyle(fontSize: 28))),
          const Positioned(top: 220, left: 16, child: Text('⭐', style: TextStyle(fontSize: 18))),
          const Positioned(bottom: 200, right: 32, child: Text('⭐', style: TextStyle(fontSize: 22))),
          const Positioned(bottom: 280, left: 24, child: Text('⭐', style: TextStyle(fontSize: 16))),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Karakter mascot
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('🧒', style: TextStyle(fontSize: 80))
                        .animate()
                        .slideX(begin: -0.3, duration: 500.ms, curve: Curves.easeOut),
                    const SizedBox(width: 16),
                    const Text('👧', style: TextStyle(fontSize: 80))
                        .animate()
                        .slideX(begin: 0.3, duration: 500.ms, curve: Curves.easeOut),
                  ],
                ),

                const SizedBox(height: 32),

                Text(
                  'Kamu Adalah?',
                  style: AppTextStyles.h1.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 30,
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 40),

                // Role buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Column(
                    children: [
                      _RoleButton(
                        label: 'Siswa',
                        color: AppColors.primary,
                        delay: 300,
                        onTap: () => _confirmRole(context, UserRole.siswa),
                      ),
                      const SizedBox(height: 14),
                      _RoleButton(
                        label: 'Orang tua',
                        color: AppColors.primary,
                        delay: 400,
                        onTap: () => _confirmRole(context, UserRole.orangTua),
                      ),
                      const SizedBox(height: 14),
                      _RoleButton(
                        label: 'Guru',
                        color: AppColors.primary,
                        delay: 500,
                        onTap: () => _confirmRole(context, UserRole.guru),
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
}

// ── Role Button ──────────────────────────────────────────────────────────────

class _RoleButton extends StatefulWidget {
  final String label;
  final Color color;
  final int delay;
  final VoidCallback onTap;

  const _RoleButton({
    required this.label,
    required this.color,
    required this.delay,
    required this.onTap,
  });

  @override
  State<_RoleButton> createState() => _RoleButtonState();
}

class _RoleButtonState extends State<_RoleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: double.infinity,
        height: 56,
        transform: Matrix4.translationValues(0, _pressed ? 4 : 0, 0),
        decoration: BoxDecoration(
          color: _pressed ? widget.color.withValues(alpha: 0.85) : widget.color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: _pressed
              ? null
              : [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.5),
                    offset: const Offset(0, 5),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Center(
          child: Text(
            widget.label,
            style: AppTextStyles.button.copyWith(color: Colors.white, fontSize: 18),
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: widget.delay)).slideY(
          begin: 0.2,
          delay: Duration(milliseconds: widget.delay),
          duration: 400.ms,
        );
  }
}

// ── Confirm Dialog ───────────────────────────────────────────────────────────

class _ConfirmDialog extends StatelessWidget {
  final String roleLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _ConfirmDialog({
    required this.roleLabel,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: onCancel,
                child: const Icon(Icons.close, color: AppColors.textHint),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kamu adalah\nseorang $roleLabel',
              style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: _DialogBtn(
                    label: 'Tidak',
                    color: AppColors.error,
                    onTap: onCancel,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DialogBtn(
                    label: 'Ya',
                    color: AppColors.success,
                    onTap: onConfirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().scale(duration: 300.ms, curve: Curves.elasticOut);
  }
}

class _DialogBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _DialogBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              offset: const Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Text(label,
              style: AppTextStyles.button.copyWith(color: Colors.white)),
        ),
      ),
    );
  }
}
