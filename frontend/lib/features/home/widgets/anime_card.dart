import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/radius/app_radius.dart';
import '../../../shared/models/anime.dart';
import '../../../shared/widgets/premium_network_image.dart';
import '../../details/anime_details_screen.dart';

class AnimeCard extends StatelessWidget {
  final Anime anime;
  final String heroTag;

  const AnimeCard({super.key, required this.anime, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () {
          // FIXED: Now routes to your sleek, full-screen details page!
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (_) =>
                  AnimeDetailsScreen(animeId: anime.id, heroTag: heroTag),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Stack(
                children: [
                  Hero(
                    tag: heroTag,
                    child: PremiumNetworkImage(
                      imageUrl: anime.imageUrl,
                      height: 160,
                      width: 110,
                      memCacheHeight: 350,
                    ),
                  ),

                  // The Frosted Glass Score Badge Overlay
                  if (anime.rating > 0)
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Colors.amber,
                                  size: 12,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  anime.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              anime.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
