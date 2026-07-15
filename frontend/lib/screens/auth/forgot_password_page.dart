import 'package:flutter/material.dart';

import '../../core/constants/app_color.dart';
import '../../core/constants/app_text_style.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/custom_button.dart';
import '../../services/api_service.dart';

/// Halaman Lupa Password — menggunakan endpoint resend-verification
/// sebagai mekanisme bantu karena backend belum punya endpoint reset password.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _api = ApiService();

  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _api.resendVerification(
        _emailController.text.trim(),
      );

      if (!mounted) return;

      final success = result['status'] == true;

      if (success) {
        setState(() => _emailSent = true);
      } else {
        _showSnackBar(
          result['message'] ?? 'Gagal mengirim email. Coba lagi.',
          AppColor.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Terjadi kesalahan. Periksa koneksi Anda.', AppColor.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

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

              const SizedBox(height: 40),

              if (!_emailSent) ...[
                // ── Form State ────────────────────────────────────────────
                Text("Lupa Password?", style: AppTextStyle.heading1),
                const SizedBox(height: 8),
                Text(
                  "Masukkan email yang terdaftar. Kami akan mengirimkan email verifikasi untuk mengaktifkan kembali akun Anda.",
                  style: AppTextStyle.subtitle.copyWith(height: 1.6),
                ),

                const SizedBox(height: 48),

                Form(
                  key: _formKey,
                  child: CustomTextField(
                    hint: "Email terdaftar",
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
                ),

                const SizedBox(height: 32),

                // Info banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColor.primary.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColor.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Setelah email terkirim, klik link di email untuk memverifikasi akun Anda, lalu login kembali dengan password lama.",
                          style: AppTextStyle.caption.copyWith(
                            color: AppColor.primary,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                CustomButton(
                  text: "Kirim Email Verifikasi",
                  isLoading: _isLoading,
                  icon: Icons.send_rounded,
                  onPressed: _sendEmail,
                ),
              ] else ...[
                // ── Success State ─────────────────────────────────────────
                const SizedBox(height: 60),
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: AppColor.success.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mark_email_read_outlined,
                          color: AppColor.success,
                          size: 64,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        "Email Terkirim!",
                        style: AppTextStyle.heading2,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          "Kami telah mengirimkan email verifikasi ke:\n${_emailController.text.trim()}\n\nSilakan cek inbox (dan folder spam) Anda, lalu klik link verifikasi untuk mengaktifkan akun.",
                          style: AppTextStyle.bodySmall.copyWith(height: 1.7),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Kirim Ulang
                      TextButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () async {
                                setState(() {
                                  _isLoading = true;
                                  _emailSent = false;
                                });
                                await _sendEmail();
                              },
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text("Kirim Ulang Email"),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColor.primary,
                        ),
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                            side: const BorderSide(
                                color: AppColor.primary, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "Kembali ke Login",
                            style: AppTextStyle.button
                                .copyWith(color: AppColor.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
