import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:io';

import '../../core/constants/app_color.dart';
import '../../core/constants/app_text_style.dart';
import '../../core/widgets/custom_button.dart';
import '../../services/api_service.dart';
import '../recommendation/recommendation_page.dart';

class LoadingPage extends StatefulWidget {
  final File image;

  const LoadingPage({
    super.key,
    required this.image,
  });

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final ApiService _api = ApiService();

  String _currentStepText = "Mempersiapkan analisis...";
  double _progressValue = 0.05;
  bool _hasError = false;
  String _errorTitle = "Proses Gagal";
  String _errorMessage = "";
  bool _canRetry = true;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _startRecommendationFlow();
  }

  Future<void> _startRecommendationFlow() async {
    setState(() {
      _hasError = false;
      _errorMessage = "";
      _progressValue = 0.1;
      _currentStepText = "Mempersiapkan analisis...";
    });

    try {
      _updateStep("Mengunggah gambar ke server...", 0.25);
      debugPrint('[LoadingPage] Step 1: Upload gambar');

      late int itemId;
      try {
        itemId = await _api.uploadImage(image: widget.image);
        debugPrint('[LoadingPage] Upload berhasil, item_id=$itemId');
      } on Exception catch (e) {
        _setError(
          title: "Upload Gambar Gagal",
          message: e.toString().replaceFirst('Exception: ', ''),
        );
        return;
      }

      _updateStep("Mengekstrak fitur gambar dengan ResNet50...", 0.5);
      debugPrint('[LoadingPage] Step 2: Embedding (sudah dilakukan di upload)');

      await Future.delayed(const Duration(milliseconds: 600));

      _updateStep(
          "Mencari outfit paling cocok dengan Cosine Similarity...", 0.7);
      debugPrint('[LoadingPage] Step 3: Generate outfit item_id=$itemId');

      late Map<String, dynamic> outfitMap;
      try {
        outfitMap = await _api.generateOutfit(itemId);
        debugPrint('[LoadingPage] Outfit diterima: ${outfitMap.keys.toList()}');
      } on Exception catch (e) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        _setError(
          title: "Rekomendasi Gagal",
          message: msg,
        );
        return;
      }
      _updateStep("Menyiapkan hasil rekomendasi...", 0.95);
      await Future.delayed(const Duration(milliseconds: 400));

      _updateStep("Rekomendasi siap! 🎉", 1.0);
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      debugPrint('[LoadingPage] Navigasi ke RecommendationPage');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RecommendationPage(outfit: outfitMap),
        ),
      );
    } on DioException catch (e) {
      debugPrint('[LoadingPage] DioException: ${e.type} ${e.message}');
      String msg;
      if (e.type == DioExceptionType.connectionError) {
        msg =
            'Tidak dapat terhubung ke server backend.\n\nPastikan:\n1. Backend Flask berjalan\n2. Backend dapat diakses di http://10.0.2.2:5000\n3. Android Emulator terhubung ke jaringan';
      } else if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        msg =
            'Koneksi timeout. Server membutuhkan waktu lebih lama dari yang diharapkan.\nCoba lagi atau restart backend.';
      } else {
        msg = e.response?.data?['message']?.toString() ??
            e.message ??
            'Koneksi ke server bermasalah';
      }
      _setError(title: "Koneksi Bermasalah", message: msg);
    } catch (e) {
      debugPrint('[LoadingPage] Unexpected error: $e');
      _setError(
        title: "Error Tidak Terduga",
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void _updateStep(String text, double progress) {
    if (!mounted) return;
    setState(() {
      _currentStepText = text;
      _progressValue = progress;
    });
  }

  void _setError({required String title, required String message}) {
    debugPrint('[LoadingPage] ERROR — $title: $message');
    if (!mounted) return;
    setState(() {
      _hasError = true;
      _errorTitle = title;
      _errorMessage = message;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: _hasError ? _buildErrorState() : _buildLoadingState(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pulsing AI Icon
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              gradient: AppColor.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColor.primary.withOpacity(0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
        ),

        const SizedBox(height: 48),

        Text(
          "Menganalisis Pakaian...",
          style: AppTextStyle.heading2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          _currentStepText,
          style: AppTextStyle.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 260,
            height: 8,
            child: LinearProgressIndicator(
              value: _progressValue,
              color: AppColor.primary,
              backgroundColor: AppColor.divider,
            ),
          ),
        ),

        const SizedBox(height: 16),
        Text(
          "${(_progressValue * 100).toInt()}%",
          style: AppTextStyle.caption.copyWith(
            color: AppColor.primary,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 48),

        // Info steps
        _buildStepIndicator(
          icon: Icons.cloud_upload_outlined,
          label: "Upload Gambar",
          isDone: _progressValue >= 0.3,
          isActive: _progressValue > 0.1 && _progressValue < 0.3,
        ),
        const SizedBox(height: 12),
        _buildStepIndicator(
          icon: Icons.memory_rounded,
          label: "Ekstraksi Fitur ResNet50",
          isDone: _progressValue >= 0.55,
          isActive: _progressValue >= 0.3 && _progressValue < 0.55,
        ),
        const SizedBox(height: 12),
        _buildStepIndicator(
          icon: Icons.style_rounded,
          label: "Matching & Rule-Based Outfit",
          isDone: _progressValue >= 0.95,
          isActive: _progressValue >= 0.55 && _progressValue < 0.95,
        ),
      ],
    );
  }

  Widget _buildStepIndicator({
    required IconData icon,
    required String label,
    required bool isDone,
    required bool isActive,
  }) {
    final Color color = isDone
        ? AppColor.success
        : isActive
            ? AppColor.primary
            : AppColor.textHint;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isDone ? Icons.check_circle_rounded : icon,
          color: color,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyle.caption.copyWith(
            color: color,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColor.error.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline_rounded,
            color: AppColor.error,
            size: 56,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _errorTitle,
          style: AppTextStyle.heading3.copyWith(color: AppColor.error),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColor.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColor.cardBorder),
          ),
          child: Text(
            _errorMessage,
            style: AppTextStyle.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),
        if (_canRetry)
          CustomButton(
            text: "Coba Lagi",
            icon: Icons.refresh_rounded,
            onPressed: _startRecommendationFlow,
          ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Kembali",
            style: AppTextStyle.body.copyWith(color: AppColor.textSecondary),
          ),
        ),
      ],
    );
  }
}
