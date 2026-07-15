import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../core/constants/app_color.dart';
import '../../core/constants/app_text_style.dart';
import '../../core/widgets/custom_button.dart';
import '../loading/loading_page.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool _isPickingImage = false;

  Future<void> _pickFromGallery() async {
    if (_isPickingImage) return;

    setState(() => _isPickingImage = true);

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (picked == null) {
        debugPrint('[UploadPage] User membatalkan pilihan gambar');
        return;
      }

      final file = File(picked.path);
      final fileSize = await file.length();

      if (fileSize > 16 * 1024 * 1024) {
        if (mounted) {
          _showError(
              'Ukuran gambar terlalu besar. Pilih gambar yang lebih kecil (maks 16MB).');
        }
        return;
      }

      setState(() {
        _image = file;
      });

      debugPrint('[UploadPage] Gambar dipilih: ${picked.path}');
    } catch (e) {
      debugPrint('[UploadPage] Error picking image: $e');
      if (mounted) {
        final errorMsg = e.toString().toLowerCase();
        if (errorMsg.contains('permission') || errorMsg.contains('denied')) {
          _showError(
              'Izin akses galeri ditolak. Buka Pengaturan → Aplikasi → OutfitKu → Izinkan akses Galeri.');
        } else {
          _showError('Gagal memilih gambar: ${e.toString()}');
        }
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColor.error,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _startAnalysis() {
    if (_image == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoadingPage(image: _image!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: const Text("Analisis Pakaian AI"),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),

            // Header
            Text(
              "Unggah Foto Pakaian",
              style: AppTextStyle.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "AI akan mendeteksi jenis pakaian dan secara otomatis mencarikan kombinasi outfit terbaik untukmu.",
              style: AppTextStyle.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Tips banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColor.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColor.primary.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: AppColor.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Tips: Gunakan foto 1 item pakaian dengan latar belakang polos untuk hasil terbaik.",
                      style: AppTextStyle.caption.copyWith(
                        color: AppColor.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Image Dropzone / Preview
            Expanded(
              child: GestureDetector(
                onTap: _pickFromGallery,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: _image != null
                          ? AppColor.primary.withOpacity(0.4)
                          : AppColor.primary.withOpacity(0.2),
                      width: _image != null ? 2 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColor.primary.withOpacity(0.04),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _image == null
                      ? _buildEmptyDropzone()
                      : _buildImagePreview(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Gallery button (secondary)
            if (_image == null)
              OutlinedButton.icon(
                onPressed: _isPickingImage ? null : _pickFromGallery,
                icon: _isPickingImage
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColor.primary,
                        ),
                      )
                    : const Icon(Icons.photo_library_outlined, size: 20),
                label: Text(
                  _isPickingImage ? "Membuka Galeri..." : "Pilih dari Galeri",
                  style: AppTextStyle.body.copyWith(
                    color: AppColor.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  side: const BorderSide(color: AppColor.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Analyze button (primary)
            CustomButton(
              text: "Mulai Analisis",
              icon: Icons.auto_awesome_rounded,
              onPressed: _image == null ? null : _startAnalysis,
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDropzone() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        color: AppColor.card,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColor.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.photo_library_rounded,
                size: 52,
                color: AppColor.primary,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              "Ketuk untuk Pilih Foto",
              style: AppTextStyle.body.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColor.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Pilih dari Galeri\nFormat: JPG, PNG, WEBP",
              style: AppTextStyle.caption.copyWith(
                color: AppColor.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            _image!,
            fit: BoxFit.cover,
          ),
          // Gradient overlay di bagian bawah
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Text(
                "Ketuk untuk ganti gambar",
                style: AppTextStyle.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Remove button
          Positioned(
            top: 14,
            right: 14,
            child: GestureDetector(
              onTap: () => setState(() => _image = null),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          // Selected badge
          Positioned(
            top: 14,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColor.success.withOpacity(0.9),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    "Gambar Dipilih",
                    style: AppTextStyle.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
