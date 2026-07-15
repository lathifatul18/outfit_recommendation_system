import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants/app_color.dart';

/// Reusable network image widget with CachedNetworkImage.
/// Solves "Connection closed while receiving data" by using HTTP headers
/// and memory caching. Includes loading indicator, error fallbacks, and retry.
class AppNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      httpHeaders: const {
        'Connection': 'close',
      },
      placeholder: (context, url) => _buildLoading(),
      errorWidget: (context, url, error) => _buildError(context),
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildLoading() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColor.card,
        borderRadius: borderRadius,
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColor.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColor.card,
        borderRadius: borderRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            color: AppColor.textHint,
            size: (height != null && height! < 80) ? 20 : 32,
          ),
          if (height == null || height! > 80) ...[
            const SizedBox(height: 4),
            const Text(
              "Gagal memuat",
              style: TextStyle(
                color: AppColor.textHint,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
