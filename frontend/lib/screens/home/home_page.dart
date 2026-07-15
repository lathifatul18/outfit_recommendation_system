import 'package:flutter/material.dart';

import '../../core/constants/app_color.dart';
import '../../core/constants/app_text_style.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_header.dart';
import '../../widgets/upload_card.dart';
import '../../widgets/inspiration_grid.dart';
import '../upload/upload_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  UserModel? _user;
  int _inspirationKey = 0; // gunakan key untuk re-render InspirationGrid

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    if (mounted) {
      setState(() => _user = user);
    }
  }

  /// Refresh grid inspirasi dengan memperbarui key-nya
  void _refreshInspirations() {
    setState(() => _inspirationKey++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const AppHeader(),
              const SizedBox(height: 28),

              // Greeting
              Text(
                "Hai, ${_user?.nama ?? 'Fashion Lover'}! 👋",
                style: AppTextStyle.heading2,
              ),
              const SizedBox(height: 6),
              Text(
                "Yuk temukan outfit terbaik untuk hari ini",
                style: AppTextStyle.bodySmall,
              ),
              const SizedBox(height: 28),

              // Upload Card
              const UploadCard(),
              const SizedBox(height: 32),

              // Inspiration Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Inspirasi Untukmu",
                    style: AppTextStyle.heading3,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UploadPage(),
                        ),
                      ).then((_) {
                        // Refresh user dan inspirasi setelah kembali
                        _loadUser();
                        _refreshInspirations();
                      });
                    },
                    child: Text(
                      "Coba Sekarang",
                      style: AppTextStyle.bodySmall.copyWith(
                        color: AppColor.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InspirationGrid(key: ValueKey(_inspirationKey)),
            ],
          ),
        ),
      ),
    );
  }
}
