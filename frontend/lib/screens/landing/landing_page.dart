import 'package:flutter/material.dart';

import '../../core/constants/app_color.dart';
import '../../core/constants/app_text_style.dart';
import '../navigation/main_navigation.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient circle
            Positioned(
              left: -200,
              bottom: -200,
              child: Container(
                width: 600,
                height: 600,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColor.primary.withOpacity(0.15),
                      AppColor.primary.withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Top right accent circle
            Positioned(
              right: -80,
              top: -80,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColor.primaryLight.withOpacity(0.1),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: height * 0.02),

                  // Landing Image
                  Center(
                    child: SizedBox(
                      height: height * 0.45,
                      child: Image.asset(
                        "assets/images/landing.jpeg",
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Title
                  Text(
                    "Find Your\nPerfect Outfit",
                    style: AppTextStyle.heading1.copyWith(
                      fontSize: 34,
                      height: 1.15,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Subtitle
                  Text(
                    "Upload pakaianmu dan dapatkan rekomendasi outfit terbaik dengan AI!",
                    style: AppTextStyle.subtitle.copyWith(
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Get Started Button
                  Align(
                    alignment: Alignment.bottomRight,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MainNavigation(),
                          ),
                        );
                      },
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: AppColor.primaryGradient,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: AppColor.primary.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
