import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_routes.dart';
import '../../core/widgets/sd_button.dart';
import '../../core/services/firebase_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _loading = false;

  void _loginWithGoogle() async {
    setState(() => _loading = true);
    try {
      final cred = await FirebaseService().signInWithGoogle();
      if (cred.user != null && mounted) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).get();
        if (mounted) {
          setState(() => _loading = false);
          final data = doc.data();
          if (data == null || data['role'] == null || data['role'].toString().isEmpty) {
            Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
          } else {
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal masuk Google: ${e.toString().replaceAll(RegExp(r'\[.*\]\s*'), '')}',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Dekorasi bintang
          const Positioned(top: 100, right: 30, child: _Star(size: 28)),
          const Positioned(top: 200, left: 20, child: _Star(size: 18)),
          const Positioned(bottom: 260, right: 50, child: _Star(size: 22)),
          const Positioned(bottom: 320, left: 40, child: _Star(size: 16)),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  // Karakter mascot area
                  SizedBox(
                    height: 240,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Karakter kiri
                        Positioned(
                          left: 0,
                          bottom: 0,
                          child: _MascotLeft()
                              .animate()
                              .slideX(begin: -0.3, duration: 600.ms, curve: Curves.easeOut),
                        ),
                        // Karakter kanan
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: _MascotRight()
                              .animate()
                              .slideX(begin: 0.3, duration: 600.ms, curve: Curves.easeOut),
                        ),
                        // Logo tengah
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.secondary.withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  )
                                ],
                              ),
                              child: Text(
                                'STUDY\nDUEL',
                                style: AppTextStyles.display.copyWith(
                                  color: Colors.white,
                                  fontSize: 30,
                                  height: 1.0,
                                  letterSpacing: 1,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ).animate().scale(duration: 500.ms, delay: 200.ms, curve: Curves.elasticOut),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Teks sambutan
                  Text(
                    'Welcome!',
                    style: AppTextStyles.h1.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 32,
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 6),
                  Text(
                    'Selamat Datang Calon-Calon Pejuang!',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: 36),

                  // Tombol
                  SdButton(
                    label: 'Create Account',
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.register),
                  ).animate().fadeIn(delay: 600.ms),
                  const SizedBox(height: 12),
                  SdButton(
                    label: 'Log In',
                    variant: SdButtonVariant.outline,
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.login),
                  ).animate().fadeIn(delay: 700.ms),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('Or Sign in with',
                            style: AppTextStyles.bodySmall),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ).animate().fadeIn(delay: 800.ms),
                  const SizedBox(height: 16),
                  SdButton(
                    label: 'Masuk melalui Google',
                    variant: SdButtonVariant.ghost,
                    isLoading: _loading,
                    prefixIcon: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Text('G',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Colors.red)),
                      ),
                    ),
                    onPressed: _loginWithGoogle,
                  ).animate().fadeIn(delay: 850.ms),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.login),
                    child: RichText(
                      text: TextSpan(
                        text: 'Lupa Password? ',
                        style: AppTextStyles.bodySmall,
                        children: [
                          TextSpan(
                            text: 'Masuk',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 900.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mascot widgets (placeholder artis karakter) ──────────────────────────────

class _MascotLeft extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 90,
          height: 110,
          decoration: BoxDecoration(
            color: AppColors.accentSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.accent, width: 2),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🧒', style: TextStyle(fontSize: 52)),
              Text('⚔️', style: TextStyle(fontSize: 22)),
            ],
          ),
        ),
        Container(
          width: 70,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
        ),
      ],
    );
  }
}

class _MascotRight extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 90,
          height: 110,
          decoration: BoxDecoration(
            color: AppColors.secondarySurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.secondary, width: 2),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('👧', style: TextStyle(fontSize: 52)),
              Text('📚', style: TextStyle(fontSize: 22)),
            ],
          ),
        ),
        Container(
          width: 70,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
        ),
      ],
    );
  }
}

class _Star extends StatelessWidget {
  final double size;
  const _Star({required this.size});

  @override
  Widget build(BuildContext context) {
    return Text('⭐', style: TextStyle(fontSize: size))
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(duration: 1500.ms, begin: const Offset(0.8, 0.8), end: const Offset(1.1, 1.1));
  }
}
