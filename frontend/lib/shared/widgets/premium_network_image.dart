import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/colors/app_colors.dart';

class PremiumNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int? memCacheHeight;

  const PremiumNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    // By default, limit decoding to 400 pixels high to save massive amounts of RAM
    this.memCacheHeight = 400,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      // This is the magic property that prevents scroll jank:
      memCacheHeight: memCacheHeight,
      fadeInDuration: const Duration(milliseconds: 300),
      placeholder: (context, url) => Container(
        color: AppColors.card,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: AppColors.card,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_outlined, color: Colors.white38, size: 32),
            SizedBox(height: 4),
            Text(
              "No Image",
              style: TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
