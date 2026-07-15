import 'package:flutter/material.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/app_color.dart';
import '../../core/constants/app_text_style.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/network_image_widget.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_page.dart';
import '../auth/register_page.dart';

class DetailPage extends StatefulWidget {
  final Map<String, dynamic> mainItem;
  final String
      mainItemType; // e.g. "Uploaded", "Matched", "Bottomwear", "Footwear", "Accessories"
  final int mainItemScore; // similarity score percent (e.g. 98)
  final List<Map<String, dynamic>>
      otherItems; // other items in this outfit combo

  const DetailPage({
    super.key,
    required this.mainItem,
    required this.mainItemType,
    required this.mainItemScore,
    required this.otherItems,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final ApiService _api = ApiService();
  UserModel? _user;
  bool _isSaving = false;
  bool _isFavorited = false;

  @override
  void initState() {
    super.initState();
    _checkLoginAndFavoriteState();
  }

  Future<void> _checkLoginAndFavoriteState() async {
    _user = await AuthService.getUser();
    if (_user != null) {
      // Check if the current item is already in favorites
      try {
        final favorites = await _api.getFavorites(_user!.idUser);
        final itemId = widget.mainItem["id_item"] as int;
        final alreadyFavorited =
            favorites.any((fav) => fav["id_item"] == itemId);
        if (mounted) {
          setState(() {
            _isFavorited = alreadyFavorited;
          });
        }
      } catch (e) {
        debugPrint("Error checking favorite state: $e");
      }
    }
  }

  void _showLoginRequiredBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColor.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: AppColor.primary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                "Login Diperlukan",
                style: AppTextStyle.heading3,
              ),
              const SizedBox(height: 12),
              Text(
                "Untuk menyimpan outfit ke favorit, silakan login terlebih dahulu.",
                style: AppTextStyle.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              CustomButton(
                text: "Login",
                onPressed: () {
                  Navigator.pop(context); // close bottom sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  ).then((_) => _checkLoginAndFavoriteState());
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  side: const BorderSide(color: AppColor.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context); // close bottom sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  ).then((_) => _checkLoginAndFavoriteState());
                },
                child: Text(
                  "Daftar",
                  style: AppTextStyle.button.copyWith(color: AppColor.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    if (_user == null) {
      _showLoginRequiredBottomSheet();
      return;
    }

    final itemId = widget.mainItem["id_item"] as int;
    final itemName = widget.mainItem["nama_item"] as String;

    setState(() => _isSaving = true);
    try {
      if (_isFavorited) {
        final success = await _api.deleteFavorite(_user!.idUser, itemId);
        if (success) {
          setState(() => _isFavorited = false);
          _showSnackBar("$itemName dihapus dari favorit", AppColor.success);
        }
      } else {
        final success = await _api.addFavorite(_user!.idUser, itemId);
        if (success) {
          setState(() => _isFavorited = true);
          _showSnackBar("$itemName disimpan ke favorit", AppColor.success);
        }
      }
    } catch (e) {
      _showSnackBar("Gagal menyimpan ke favorit", AppColor.error);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = widget.mainItem["gambar"] as String;
    final cleanImageUrl = ApiConstants.imageUrl(imagePath);
    final itemName = widget.mainItem["nama_item"] as String;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("OutfitKu"),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 11,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: AppColor.cardBorder, width: 1.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: AppNetworkImage(
                            imageUrl: cleanImageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Main Item Title
                          Text(
                            itemName,
                            style: AppTextStyle.heading3.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),

                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColor.primary,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              "Kecocokan ${widget.mainItemScore}%",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          Text(
                            "Item lainnya",
                            style: AppTextStyle.body.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColor.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),

                          Expanded(
                            child: widget.otherItems.isEmpty
                                ? const Center(
                                    child: Text(
                                      "Tidak ada item lainnya",
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 12),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: widget.otherItems.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final item = widget.otherItems[index];
                                      final otherName =
                                          item["nama_item"] as String;
                                      final otherImage =
                                          item["gambar"] as String;
                                      final otherScore = item["score"] != null
                                          ? ((item["score"] as num) * 100)
                                              .round()
                                          : 100;
                                      final cleanOtherUrl =
                                          ApiConstants.imageUrl(otherImage);

                                      return _buildMiniItemCard(
                                        cleanOtherUrl,
                                        otherName,
                                        otherScore,
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Bottom Button: Simpan ke Favorit
              CustomButton(
                text: _isFavorited ? "Hapus dari Favorit" : "Simpan ke Favorit",
                isLoading: _isSaving,
                icon: _isFavorited
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                onPressed: _toggleFavorite,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniItemCard(String imageUrl, String title, int score) {
    return Row(
      children: [
        Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColor.cardBorder, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: AppNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                "Kecocokan $score%",
                style: const TextStyle(
                  color: AppColor.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
