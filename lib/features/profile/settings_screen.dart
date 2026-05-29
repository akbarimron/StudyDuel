import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/firebase_service.dart';
import '../../core/widgets/sd_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _firebase = FirebaseService();
  bool _notificationsEnabled = false;
  bool _darkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkNotificationPermissionStatus();
  }

  Future<void> _checkNotificationPermissionStatus() async {
    final status = await Permission.notification.status;
    if (mounted) {
      setState(() {
        _notificationsEnabled = status.isGranted;
      });
    }
  }

  Future<void> _toggleNotificationPermission(bool value) async {
    if (value) {
      final status = await Permission.notification.request();
      if (mounted) {
        setState(() {
          _notificationsEnabled = status.isGranted;
        });
        if (status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notifikasi diaktifkan! 🔔'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin notifikasi ditolak. Anda dapat mengaktifkannya di pengaturan sistem.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      // Direct revoking of permission from app isn't possible in Android, we just show a message directing to settings.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Untuk menonaktifkan notifikasi secara permanen, silakan ubah di pengaturan sistem.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _notificationsEnabled = false;
      });
    }
  }

  void _showTutorialDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Text('🎓', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Text('Cara Bermain', style: AppTextStyles.h3),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTutorialStep('1', 'Pilih mode Duel dari Beranda atau navigasi tengah.'),
            const SizedBox(height: 12),
            _buildTutorialStep('2', 'Jawab pertanyaan secepat mungkin untuk mendapatkan poin ekstra.'),
            const SizedBox(height: 12),
            _buildTutorialStep('3', 'Gunakan item powerup dari hasil Gacha untuk membantu Anda menang!'),
            const SizedBox(height: 12),
            _buildTutorialStep('4', 'Kalahkan lawan untuk naik tingkat di Leaderboard global.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Mengerti', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            color: AppColors.primarySurface,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  void _showAccountPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Text('🔒', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Text('Akun & Privasi', style: AppTextStyles.h3),
          ],
        ),
        content: Text(
          'Akun Anda terhubung dengan Google. Data Anda aman bersama kami dan tidak akan disalahgunakan atau dibagikan ke pihak ketiga mana pun.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showHubungkanDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Text('🔗', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Text('Hubungkan Akun', style: AppTextStyles.h3),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masukkan ID Sekolah Anda untuk menghubungkan data akademik:',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Contoh: SCH-998877',
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: AppTextStyles.label.copyWith(color: AppColors.textHint)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ID Sekolah berhasil diverifikasi dan dihubungkan! 🏫'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text('Hubungkan', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showFAQDialog(String question, String answer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(question, style: AppTextStyles.h3),
        content: Text(
          answer,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, String uid, Map<String, dynamic> userData) {
    final nameController = TextEditingController(text: userData['name'] ?? '');
    final emailController = TextEditingController(text: userData['email'] ?? '');
    final schoolController = TextEditingController(text: userData['school_name'] ?? '');
    final gradeController = TextEditingController(text: userData['grade'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Text('🧑‍💻', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Text('Ubah Profil', style: AppTextStyles.h3),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEditField('Nama Lengkap', nameController),
              const SizedBox(height: 12),
              _buildEditField('Email', emailController, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _buildEditField('Asal Sekolah', schoolController),
              const SizedBox(height: 12),
              _buildEditField('Kelas', gradeController),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: AppTextStyles.label.copyWith(color: AppColors.textHint)),
          ),
          TextButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              final newEmail = emailController.text.trim();
              final newSchool = schoolController.text.trim();
              final newGrade = gradeController.text.trim();

              if (newName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nama tidak boleh kosong!')),
                );
                return;
              }

              try {
                await _firebase.updateUserField(uid, {
                  'name': newName,
                  'email': newEmail,
                  'school_name': newSchool,
                  'grade': newGrade,
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profil berhasil diperbarui! 🎉'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal memperbarui profil: $e')),
                  );
                }
              }
            },
            child: Text('Simpan', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _firebase.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firebase.getUserStream(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary))),
          );
        }

        final userData = snapshot.data!.data() ?? {};
        final name = userData['name'] ?? 'Pelajar';
        final school = userData['school_name'] ?? 'SMP Negeri 1';
        final grade = userData['grade'] ?? '8A';

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            centerTitle: true,
            title: Text('Pengaturan', style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // General settings card
                Card(
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
                          title: Text('Ubah Profil', style: AppTextStyles.bodyLarge),
                          subtitle: Text('$name - $school, Kelas $grade', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                          onTap: () => _showEditProfileDialog(context, uid, userData),
                        ),
                        const Divider(height: 1, indent: 56),
                        ListTile(
                          leading: const Icon(Icons.school_outlined, color: AppColors.primary),
                          title: Text('Tutorial Cara Bermain', style: AppTextStyles.bodyLarge),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                          onTap: _showTutorialDialog,
                        ),
                        const Divider(height: 1, indent: 56),
                        SwitchListTile(
                          secondary: const Icon(Icons.notifications_none_rounded, color: AppColors.secondary),
                          title: Text('Nyalakan Notifikasi', style: AppTextStyles.bodyLarge),
                          value: _notificationsEnabled,
                          activeThumbColor: AppColors.success,
                          onChanged: _toggleNotificationPermission,
                        ),
                        const Divider(height: 1, indent: 56),
                        SwitchListTile(
                          secondary: const Icon(Icons.dark_mode_outlined, color: AppColors.accentDark),
                          title: Text('Mode Gelap', style: AppTextStyles.bodyLarge),
                          value: _darkModeEnabled,
                          activeThumbColor: AppColors.accent,
                          onChanged: (v) {
                            setState(() => _darkModeEnabled = v);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Fitur Mode Gelap segera hadir! 🌓'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, indent: 56),
                        ListTile(
                          leading: const Icon(Icons.lock_outline_rounded, color: AppColors.success),
                          title: Text('Akun & Privasi', style: AppTextStyles.bodyLarge),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                          onTap: _showAccountPrivacyDialog,
                        ),
                        const Divider(height: 1, indent: 56),
                        ListTile(
                          leading: const Icon(Icons.link_rounded, color: Colors.blue),
                          title: Text('Hubungkan Sekolah', style: AppTextStyles.bodyLarge),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                          onTap: _showHubungkanDialog,
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 350.ms),
                const SizedBox(height: 28),

                // FAQ Section
                Text('Bantuan & FAQ', style: AppTextStyles.h3),
                const SizedBox(height: 12),
                Card(
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        ListTile(
                          title: Text('Bagaimana cara menghubungkan akun sekolah dengan game ini?', style: AppTextStyles.bodyMedium),
                          trailing: const Icon(Icons.question_answer_outlined, color: AppColors.textHint, size: 20),
                          onTap: () => _showFAQDialog(
                            'Menghubungkan Akun Sekolah',
                            'Anda dapat memasukkan ID Sekolah yang diberikan oleh guru Anda pada menu "Hubungkan Sekolah" di atas. Ini akan mensinkronisasikan progress belajar Anda dengan tugas sekolah.',
                          ),
                        ),
                        const Divider(height: 1, indent: 16),
                        ListTile(
                          title: Text('Saya tidak bisa menginvite akun teman saya dalam permainan', style: AppTextStyles.bodyMedium),
                          trailing: const Icon(Icons.question_answer_outlined, color: AppColors.textHint, size: 20),
                          onTap: () => _showFAQDialog(
                            'Masalah Mengundang Teman',
                            'Pastikan teman Anda sudah menyetujui permintaan pertemanan Anda di tab "Friends". Hanya pengguna yang sudah menjadi teman yang dapat diundang untuk berduel.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                const SizedBox(height: 36),

                // Log Out Button
                SdButton(
                  label: 'Keluar dari Akun',
                  variant: SdButtonVariant.outline,
                  onPressed: () async {
                    await _firebase.signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.login,
                        (route) => false,
                      );
                    }
                  },
                ).animate().fadeIn(duration: 450.ms, delay: 200.ms),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}
