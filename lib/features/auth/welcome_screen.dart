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
          // Background Image yang baru
          Positioned.fill(
            child: Image.asset(
              'assets/images/welcome_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),

                  // Area Logo
                  Image.asset(
                    'assets/images/studyDuel_logo.png',
                    width: 70,
                    height: 70,
                    fit: BoxFit.contain,
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2),
            
                
                  const SizedBox(height: 140),

                  const SizedBox(height: 32),

                  // Teks sambutan
                  Text(
                    'Welcome!',
                    style: AppTextStyles.h1.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 32,
                    ),
                    textAlign: TextAlign.left,
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 6),
                  Text(
                    'Selamat Datang Calon-Calon Pejuang!!',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.left,
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
                     
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: Image.asset(
                          'assets/images/logo_google.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    onPressed: _loginWithGoogle,
                  ).animate().fadeIn(delay: 850.ms),
                  const SizedBox(height: 12),
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, AppRoutes.login),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          text: 'Lupa Password? ',
                          style: AppTextStyles.bodySmall,
                          children: [
                            TextSpan(
                              text: 'Masuk',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: const Color.fromARGB(255, 28, 141, 247),
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
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


