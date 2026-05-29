import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_routes.dart';
import '../../core/widgets/sd_button.dart';
import '../../core/services/firebase_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _register() async {
    final username = _usernameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (username.isEmpty || email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua kolom wajib diisi!')),
      );
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Format email tidak valid!')),
      );
      return;
    }
    if (pass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi password tidak cocok!')),
      );
      return;
    }
    if (pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password minimal 6 karakter!')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await FirebaseService().signUp(
        email: email,
        password: pass,
        username: username,
        name: username,
        role: 'siswa', // default
      );
      if (mounted) {
        setState(() => _loading = false);
        Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Registrasi gagal: ${e.toString().replaceAll(RegExp(r'\[.*\]'), '')}',
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
          // Header banner kuning/gold
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 220,
              color: AppColors.accentDark,
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.12),
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
                    Text('Sign Up',
                        style: AppTextStyles.h1.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 28,
                        )).animate().fadeIn(),
                    const SizedBox(height: 4),
                    Text('Mulai Berkompetisi dengan kawanmu!',
                        style: AppTextStyles.bodyMedium)
                        .animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 28),

                    TextField(
                      controller: _usernameCtrl,
                      style: AppTextStyles.bodyLarge,
                      decoration: const InputDecoration(labelText: 'Username',
                          labelStyle: TextStyle(color: AppColors.textHint, fontSize: 14)),
                    ).animate().fadeIn(delay: 150.ms),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _emailCtrl,
                      style: AppTextStyles.bodyLarge,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email',
                          labelStyle: TextStyle(color: AppColors.textHint, fontSize: 14)),
                    ).animate().fadeIn(delay: 220.ms),
                    const SizedBox(height: 16),

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
                            color: AppColors.textHint, size: 20,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _confirmCtrl,
                      obscureText: true,
                      style: AppTextStyles.bodyLarge,
                      decoration: const InputDecoration(
                        labelText: 'Confirm Password',
                        labelStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
                      ),
                    ).animate().fadeIn(delay: 400.ms),

                    const SizedBox(height: 28),
                    SdButton(
                      label: 'Daftar',
                      isLoading: _loading,
                      onPressed: _register,
                    ).animate().fadeIn(delay: 500.ms),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Or Sign in with', style: AppTextStyles.bodySmall),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ).animate().fadeIn(delay: 550.ms),
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
                    ).animate().fadeIn(delay: 600.ms),

                    const SizedBox(height: 20),
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(
                            context, AppRoutes.login),
                        child: RichText(
                          text: TextSpan(
                            text: 'Sudah Punya Akun? ',
                            style: AppTextStyles.bodyMedium,
                            children: [
                              TextSpan(
                                text: 'Masuk',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 650.ms),
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
