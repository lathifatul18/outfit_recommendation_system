import 'package:flutter/material.dart';

import '../core/constants/api_constants.dart';
import '../core/constants/app_color.dart';
import '../core/constants/app_text_style.dart';
import '../core/widgets/network_image_widget.dart';
import '../services/api_service.dart';

/// InspirationGrid menampilkan random dataset fashion items dari backend.
class InspirationGrid extends StatefulWidget {
  const InspirationGrid({super.key});

  @override
  State<InspirationGrid> createState() => _InspirationGridState();
}

class _InspirationGridState extends State<InspirationGrid> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInspirations();
  }

  Future<void> _loadInspirations() async {
    try {
      final data = await _api.getInspirations(limit: 6);
      if (mounted) {
        setState(() {
          _items = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[InspirationGrid] Error loading inspirations: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildShimmerGrid();
    }

    if (_items.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (_, index) {
        final item = _items[index];
        final imageUrl = ApiConstants.imageUrl(item['gambar'] as String? ?? '');
        final subCategory =
            (item['sub_category'] as String? ?? '').toUpperCase();

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColor.cardBorder,
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Gambar dari network
                AppNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                ),

                // Label sub_category di bagian bawah
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.65),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Text(
                      subCategory,
                      style: AppTextStyle.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shimmer loading grid
  Widget _buildShimmerGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            color: AppColor.card,
            borderRadius: BorderRadius.circular(16),
          ),
          child: _ShimmerBox(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  /// Empty state jika tidak ada data
  Widget _buildEmptyState() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            color: AppColor.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColor.cardBorder),
          ),
          child: const Center(
            child: Icon(
              Icons.image_outlined,
              color: AppColor.textHint,
              size: 28,
            ),
          ),
        );
      },
    );
  }
}

/// Animasi shimmer sederhana
class _ShimmerBox extends StatefulWidget {
  final BorderRadius borderRadius;
  const _ShimmerBox({required this.borderRadius});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            color: Colors.grey.withOpacity(_animation.value),
          ),
        );
      },
    );
  }
}
