import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_routes.dart';
import '../../core/widgets/sd_button.dart';
import '../../core/services/firebase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  void _login() async {
    if (_usernameCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username dan password wajib diisi!')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final email = "${_usernameCtrl.text.trim().toLowerCase()}@studyduel.com";
      await FirebaseService().signIn(email, _passCtrl.text);
      if (mounted) {
        setState(() => _loading = false);
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal masuk: Username atau Password salah!',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

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
          // Header banner biru
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 220,
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(0),
                  bottomRight: Radius.circular(0),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'STUDY DUEL',
                        style: AppTextStyles.h2.copyWith(
                          color: Colors.white,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🧒', style: TextStyle(fontSize: 50)),
                        SizedBox(width: 8),
                        Text('👧', style: TextStyle(fontSize: 50)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Form card
          Positioned.fill(
            top: 190,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Login',
                        style: AppTextStyles.h1.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 28,
                        )).animate().fadeIn(),
                    const SizedBox(height: 4),
                    Text('Selamat Datang Kembali, Jagoan!',
                        style: AppTextStyles.bodyMedium)
                        .animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 28),

                    // Username
                    TextField(
                      controller: _usernameCtrl,
                      style: AppTextStyles.bodyLarge,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        labelStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 16),

                    // Password
                    TextField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      style: AppTextStyles.bodyLarge,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.textHint,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        child: Text(
                          'Lupa Password?',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 350.ms),

                    const SizedBox(height: 20),
                    SdButton(
                      label: 'Masuk',
                      isLoading: _loading,
                      onPressed: _login,
                    ).animate().fadeIn(delay: 400.ms),

                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Or Sign in with', style: AppTextStyles.bodySmall),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ).animate().fadeIn(delay: 450.ms),
                    const SizedBox(height: 16),

                    SdButton(
                      label: 'Masuk melalui Google',
                      variant: SdButtonVariant.outline,
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
                    ).animate().fadeIn(delay: 500.ms),

                    const SizedBox(height: 20),
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(
                            context, AppRoutes.register),
                        child: RichText(
                          text: TextSpan(
                            text: 'Belum Punya Akun? ',
                            style: AppTextStyles.bodyMedium,
                            children: [
                              TextSpan(
                                text: 'Buat!',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 550.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
