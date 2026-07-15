import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../core/constants/app_color.dart';
import '../../core/constants/app_text_style.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/custom_button.dart';
import '../../services/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _api = ApiService();

  bool _isLoading = false;
  bool _isResending = false;
  String? _registeredEmail;

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await _api.register(
        nama: _namaController.text.trim(),
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (response['status'] == true) {
        _registeredEmail = _emailController.text.trim();

        // Tampilkan dialog sukses dengan opsi kirim ulang verifikasi
        _showRegistrationSuccessDialog(
          response['message'] ??
              'Registrasi berhasil! Silakan cek email untuk verifikasi.',
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final message = e.response?.data?['message'] ?? 'Register gagal';
      _showSnackBar(message, AppColor.error);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Terjadi kesalahan. Periksa koneksi Anda.', AppColor.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Tampilkan dialog sukses registrasi
  void _showRegistrationSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColor.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_read_outlined,
                color: AppColor.success,
                size: 44,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Registrasi Berhasil!',
              style: AppTextStyle.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTextStyle.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Email: $_registeredEmail',
              style: AppTextStyle.caption.copyWith(
                color: AppColor.primary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          // Kirim ulang verifikasi
          StatefulBuilder(
            builder: (ctx, setStateDialog) {
              return Column(
                children: [
                  TextButton(
                    onPressed: _isResending
                        ? null
                        : () async {
                            setStateDialog(() => _isResending = true);
                            await _resendVerification();
                            setStateDialog(() => _isResending = false);
                          },
                    child: _isResending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColor.primary,
                            ),
                          )
                        : Text(
                            'Kirim Ulang Email Verifikasi',
                            style: AppTextStyle.bodySmall.copyWith(
                              color: AppColor.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          Navigator.pop(dialogContext); // close dialog
                          Navigator.pop(context); // kembali ke login
                        },
                        child: const Text('Ke Halaman Login'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Kirim ulang email verifikasi
  Future<void> _resendVerification() async {
    if (_registeredEmail == null) return;
    try {
      final result = await _api.resendVerification(_registeredEmail!);
      if (!mounted) return;
      final success = result['status'] == true;
      _showSnackBar(
        result['message'] ?? (success ? 'Email terkirim!' : 'Gagal mengirim'),
        success ? AppColor.success : AppColor.error,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal mengirim ulang email', AppColor.error);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Back Button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColor.card,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: AppColor.textPrimary,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Title
                Text("Buat Akun Baru", style: AppTextStyle.heading2),
                const SizedBox(height: 8),
                Text(
                  "Yuk, daftar untuk menyimpan outfit favoritmu!",
                  style: AppTextStyle.subtitle,
                ),

                const SizedBox(height: 36),

                // Nama
                CustomTextField(
                  hint: "Nama Lengkap",
                  controller: _namaController,
                  icon: Icons.badge_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama harus diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                CustomTextField(
                  hint: "Email",
                  controller: _emailController,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email harus diisi';
                    }
                    if (!value.contains('@')) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Username
                CustomTextField(
                  hint: "Username",
                  controller: _usernameController,
                  icon: Icons.person_outline_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Username harus diisi';
                    }
                    if (value.length < 3) {
                      return 'Minimal 3 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                CustomTextField(
                  hint: "Password",
                  controller: _passwordController,
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password harus diisi';
                    }
                    if (value.length < 6) {
                      return 'Minimal 6 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password
                CustomTextField(
                  hint: "Konfirmasi Password",
                  controller: _confirmPasswordController,
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Konfirmasi password harus diisi';
                    }
                    if (value != _passwordController.text) {
                      return 'Password tidak sama';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 36),

                // Register Button
                CustomButton(
                  text: "Daftar Sekarang",
                  isLoading: _isLoading,
                  onPressed: _register,
                ),

                const SizedBox(height: 24),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Sudah punya akun? ",
                      style: AppTextStyle.bodySmall,
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        "Login disini",
                        style: AppTextStyle.bodySmall.copyWith(
                          color: AppColor.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
