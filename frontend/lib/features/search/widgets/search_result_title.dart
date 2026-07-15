import 'package:flutter/material.dart';
import '../../../core/colors/app_colors.dart';
import '../../../core/radius/app_radius.dart';
import '../../../shared/models/anime.dart';
import '../../../shared/widgets/premium_network_image.dart';
import '../../details/anime_details_screen.dart';

class SearchResultTile extends StatelessWidget {
  final Anime anime;

  const SearchResultTile({super.key, required this.anime});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnimeDetailsScreen(
              animeId: anime.id,
              heroTag: 'Search_${anime.id}',
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Hero(
              tag: 'anime-${anime.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: PremiumNetworkImage(
                  imageUrl: anime.imageUrl,
                  width: 70,
                  height: 100,
                  memCacheHeight:
                      250, // Memory optimized specifically for list tiles
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    anime.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    anime.type,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Episodes: ${anime.episodes ?? "Unknown"}",
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "⭐ ${anime.rating.toStringAsFixed(1)}",
                    style: const TextStyle(color: Colors.amber),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
