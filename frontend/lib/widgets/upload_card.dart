import 'package:flutter/material.dart';

import '../../core/constants/app_color.dart';
import '../../core/constants/app_text_style.dart';
import '../../screens/upload/upload_page.dart';

class UploadCard extends StatelessWidget {
  const UploadCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UploadPage()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: AppColor.cardGradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColor.primary.withOpacity(0.15),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            // Upload Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: AppColor.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColor.primary.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_photo_alternate_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              "Upload foto outfit kamu",
              style: AppTextStyle.heading3.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              "Format: JPG, PNG, WEBP • Maks 16MB",
              style: AppTextStyle.caption,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                gradient: AppColor.primaryGradient,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColor.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                "Pilih Gambar",
                style: AppTextStyle.button.copyWith(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
