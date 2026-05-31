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
        const SnackBar(content: Text('Username atau email dan password wajib diisi!')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      String emailInput = _usernameCtrl.text.trim();
      String resolvedEmail = emailInput;

      if (!emailInput.contains('@')) {
        // Query user collection for username
        var querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: emailInput)
            .limit(1)
            .get();

        if (querySnapshot.docs.isEmpty) {
          // Try lowercase query
          querySnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('username', isEqualTo: emailInput.toLowerCase())
              .limit(1)
              .get();
        }

        if (querySnapshot.docs.isNotEmpty) {
          resolvedEmail = querySnapshot.docs.first.data()['email'] ?? emailInput;
        } else {
          // Fallback to legacy format
          resolvedEmail = "${emailInput.toLowerCase()}@studyduel.com";
        }
      }

      await FirebaseService().signIn(resolvedEmail, _passCtrl.text);
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
              'Gagal masuk: Username/Email atau Password salah!',
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
      backgroundColor: const Color.fromARGB(255, 87, 121, 233),
      body: Stack(
        children: [
          // Header banner dengan background image
          Positioned( 
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 370,
              child: Stack(
                children: [
                  // Background Image
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/bg_Login_screen.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Overlay gradien untuk memastikan teks terbaca namun gambar tetap tajam
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.1),
                            Colors.black.withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),

          // Form card
          Positioned.fill(
            top: 300,
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

                    // Username atau Email
                    TextField(
                      controller: _usernameCtrl,
                      style: AppTextStyles.bodyLarge,
                      decoration: const InputDecoration(
                        labelText: 'Username atau Email',
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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Image.asset(
                            'assets/images/logo_google.png',
                            fit: BoxFit.cover,
                          ),
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
                                  color: const Color.fromARGB(255, 31, 117, 216),
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
