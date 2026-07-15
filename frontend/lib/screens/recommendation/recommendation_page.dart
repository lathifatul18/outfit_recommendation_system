import 'package:flutter/material.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/app_color.dart';
import '../../core/constants/app_text_style.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/network_image_widget.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../navigation/main_navigation.dart';
import '../detail/detail_page.dart';
import '../auth/login_page.dart';
import '../auth/register_page.dart';

class RecommendationPage extends StatefulWidget {
  final Map<String, dynamic> outfit;

  const RecommendationPage({
    super.key,
    required this.outfit,
  });

  @override
  State<RecommendationPage> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  final ApiService _api = ApiService();
  UserModel? _user;

  final Set<int> _favoritedItemIds = {};
  bool _isSavingGlobal = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    _user = await AuthService.getUser();
    if (_user != null) {
      try {
        final favorites = await _api.getFavorites(_user!.idUser);
        if (mounted) {
          setState(() {
            _favoritedItemIds.clear();
            for (var fav in favorites) {
              _favoritedItemIds.add(fav["id_item"] as int);
            }
          });
        }
      } catch (e) {
        debugPrint("Error loading favorites list in recommendation: $e");
      }
    } else {
      if (mounted) {
        setState(() {
          _favoritedItemIds.clear();
        });
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
                  ).then((_) => _loadUser());
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
                  ).then((_) => _loadUser());
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

  Future<void> _toggleFavorite(int itemId, String itemName) async {
    if (_user == null) {
      _showLoginRequiredBottomSheet();
      return;
    }

    final isFavorited = _favoritedItemIds.contains(itemId);

    try {
      if (isFavorited) {
        final success = await _api.deleteFavorite(_user!.idUser, itemId);
        if (success) {
          setState(() => _favoritedItemIds.remove(itemId));
          _showSnackBar("$itemName dihapus dari favorit", AppColor.success);
        }
      } else {
        final success = await _api.addFavorite(_user!.idUser, itemId);
        if (success) {
          setState(() => _favoritedItemIds.add(itemId));
          _showSnackBar("$itemName disimpan ke favorit", AppColor.success);
        } else {
          _showSnackBar("Item sudah ada di favorit", AppColor.warning);
        }
      }
    } catch (e) {
      _showSnackBar("Gagal memproses favorit", AppColor.error);
    }
  }

  Future<void> _saveAllToFavorites() async {
    if (_user == null) {
      _showLoginRequiredBottomSheet();
      return;
    }

    setState(() => _isSavingGlobal = true);

    final matched = widget.outfit["matched_item"];
    final upperwear = widget.outfit["upperwear"];
    final bottomwear = widget.outfit["bottomwear"];
    final footwear = widget.outfit["footwear"];
    final accessories = widget.outfit["accessories"];

    final itemsToFavorite = <Map<String, dynamic>>[];
    if (matched != null) itemsToFavorite.add(matched);
    if (upperwear != null) itemsToFavorite.add(upperwear);
    if (bottomwear != null) itemsToFavorite.add(bottomwear);
    if (footwear != null) itemsToFavorite.add(footwear);
    if (accessories != null) itemsToFavorite.add(accessories);

    int savedCount = 0;

    for (var item in itemsToFavorite) {
      final id = item["id_item"] as int;
      if (!_favoritedItemIds.contains(id)) {
        try {
          await _api.addFavorite(_user!.idUser, id);
          setState(() => _favoritedItemIds.add(id));
          savedCount++;
        } catch (_) {}
      }
    }

    setState(() => _isSavingGlobal = false);

    if (savedCount > 0) {
      _showSnackBar(
          "$savedCount item berhasil disimpan ke favorit!", AppColor.success);
    } else {
      _showSnackBar("Semua item sudah disimpan ke favorit", AppColor.warning);
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

  void _navigateToDetail(
      Map<String, dynamic> tappedItem, String type, int score) {
    final matched = widget.outfit["matched_item"];
    final upperwear = widget.outfit["upperwear"];
    final bottomwear = widget.outfit["bottomwear"];
    final footwear = widget.outfit["footwear"];
    final accessories = widget.outfit["accessories"];

    final allItems = <Map<String, dynamic>>[];
    if (matched != null) allItems.add(matched);
    if (upperwear != null) allItems.add(upperwear);
    if (bottomwear != null) allItems.add(bottomwear);
    if (footwear != null) allItems.add(footwear);
    if (accessories != null) allItems.add(accessories);

    // Filter out the tapped item from otherItems
    final otherItems = allItems
        .where((item) => item["id_item"] != tappedItem["id_item"])
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailPage(
          mainItem: tappedItem,
          mainItemType: type,
          mainItemScore: score,
          otherItems: otherItems,
        ),
      ),
    ).then((_) => _loadUser()); // refresh favorite states when returning!
  }

  @override
  Widget build(BuildContext context) {
    final uploaded = widget.outfit["uploaded_item"];
    final matched = widget.outfit["matched_item"];
    final upperwear = widget.outfit["upperwear"];
    final bottomwear = widget.outfit["bottomwear"];
    final footwear = widget.outfit["footwear"];
    final accessories = widget.outfit["accessories"];

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: const Text("Rekomendasi Outfit"),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MainNavigation()),
              (route) => false,
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hasil Analisis AI", style: AppTextStyle.heading2),
            const SizedBox(height: 6),
            Text(
              "Berikut kombinasi outfit terbaik yang disesuaikan dengan item pilihanmu.",
              style: AppTextStyle.bodySmall,
            ),
            const SizedBox(height: 28),

            // 1. Uploaded Item Card
            if (uploaded != null) ...[
              _buildMainItemCard(
                title: "Pakaian Kamu",
                imageUrl: uploaded["gambar"],
                name: uploaded["nama_item"] ?? "Uploaded Item",
                category: uploaded["sub_category"] ?? "Upperwear",
                isUploaded: true,
              ),
              const SizedBox(height: 12),
              const Center(
                child: Icon(
                  Icons.arrow_downward_rounded,
                  color: AppColor.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 2. Matched Item Card (Tappable → navigates to DetailPage)
            if (matched != null) ...[
              GestureDetector(
                onTap: () {
                  final score = matched["score"] != null
                      ? ((matched["score"] as num) * 100).round()
                      : 100;
                  _navigateToDetail(matched, "Matched Item", score);
                },
                child: _buildMainItemCard(
                  title: "Kecocokan Dataset Terdekat",
                  imageUrl: matched["gambar"],
                  name: matched["nama_item"] ?? "Matched Item",
                  category: matched["sub_category"] ?? "Dataset Item",
                  score: matched["score"] != null
                      ? ((matched["score"] as num) * 100).round()
                      : 100,
                  itemId: matched["id_item"],
                ),
              ),
              const SizedBox(height: 36),
            ],

            // 3. Complete Outfit Recommendation Section
            Text("Kombinasi Pelengkap", style: AppTextStyle.heading3),
            const SizedBox(height: 16),

            // Horizontal Outfit Pieces Grid
            _buildOutfitComponentsRow(
              upperwear: upperwear,
              bottomwear: bottomwear,
              footwear: footwear,
              accessories: accessories,
            ),

            const SizedBox(height: 48),

            // Save Favorite Button
            CustomButton(
              text: "Simpan Semua ke Favorit",
              isLoading: _isSavingGlobal,
              icon: Icons.favorite_rounded,
              onPressed: _saveAllToFavorites,
            ),
            const SizedBox(height: 16),

            // Generate Again Button
            OutlinedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainNavigation()),
                  (route) => false,
                );
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                side: const BorderSide(color: AppColor.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text("Coba Lagi",
                  style: AppTextStyle.button.copyWith(color: AppColor.primary)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMainItemCard({
    required String title,
    required String imageUrl,
    required String name,
    required String category,
    int? score,
    bool isUploaded = false,
    int? itemId,
  }) {
    final cleanImageUrl = ApiConstants.imageUrl(imageUrl);
    final isFavorited = itemId != null && _favoritedItemIds.contains(itemId);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColor.cardBorder, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Area
            AppNetworkImage(
              imageUrl: cleanImageUrl,
              width: 110,
              height: 115,
              borderRadius: BorderRadius.circular(18),
            ),
            const SizedBox(width: 18),

            // Content Area
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: AppTextStyle.caption.copyWith(
                      color: AppColor.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: AppTextStyle.body.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category.toUpperCase(),
                    style: AppTextStyle.caption.copyWith(
                      color: AppColor.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Score or action row
                  if (score != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColor.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        "Kecocokan $score%",
                        style: AppTextStyle.caption.copyWith(
                          color: AppColor.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (!isUploaded && itemId != null)
              IconButton(
                onPressed: () => _toggleFavorite(itemId, name),
                icon: Icon(
                  isFavorited
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFavorited ? AppColor.primary : AppColor.textHint,
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutfitComponentsRow({
    required Map<String, dynamic>? upperwear,
    required Map<String, dynamic>? bottomwear,
    required Map<String, dynamic>? footwear,
    required Map<String, dynamic>? accessories,
  }) {
    final list = <Map<String, dynamic>>[];
    if (upperwear != null) {
      upperwear["type"] = "Upperwear";
      list.add(upperwear);
    }
    if (bottomwear != null) {
      bottomwear["type"] = "Bottomwear";
      list.add(bottomwear);
    }
    if (footwear != null) {
      footwear["type"] = "Footwear";
      list.add(footwear);
    }
    if (accessories != null) {
      accessories["type"] = "Accessories";
      list.add(accessories);
    }

    if (list.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColor.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text("Tidak ada item pendukung untuk kategori pakaian ini."),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        itemBuilder: (context, index) {
          final item = list[index];
          final type = item["type"] as String;
          final name = item["nama_item"] as String;
          final image = item["gambar"] as String;
          final itemId = item["id_item"] as int;
          final score = item["score"] != null
              ? ((item["score"] as num) * 100).round()
              : 100;

          final cleanImageUrl = ApiConstants.imageUrl(image);
          final isFavorited = _favoritedItemIds.contains(itemId);

          return GestureDetector(
            onTap: () => _navigateToDetail(item, type, score),
            child: Container(
              width: 145,
              margin: EdgeInsets.only(right: index == list.length - 1 ? 0 : 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColor.cardBorder, width: 1),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Component image
                      Expanded(
                        flex: 6,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(19)),
                          child: AppNetworkImage(
                            imageUrl: cleanImageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Component metadata
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                type.toUpperCase(),
                                style: AppTextStyle.caption.copyWith(
                                  color: AppColor.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                name,
                                style: AppTextStyle.caption.copyWith(
                                  color: AppColor.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Text(
                                "Kecocokan $score%",
                                style: AppTextStyle.caption.copyWith(
                                  color: AppColor.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Favorite Button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _toggleFavorite(itemId, name),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white70,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorited
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFavorited
                              ? AppColor.primary
                              : AppColor.textPrimary,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
