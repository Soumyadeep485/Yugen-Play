import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/radius/app_radius.dart';
import '../../../shared/models/anime.dart';
import '../../details/anime_details_screen.dart';

class AnimeCard extends StatelessWidget {
  final Anime anime;
  final String heroTag;

  const AnimeCard({super.key, required this.anime, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,

      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),

        onTap: () {
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (_) => AnimeDetailsScreen(
                animeId: anime.id,
                heroTag:
                    'AnimeCard_${anime.id}', // Make sure the tag matches the Hero widget in the card
              ),
            ),
          );
        },

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),

              child: Hero(
                tag: heroTag,

                child: CachedNetworkImage(
                  imageUrl: anime.imageUrl,

                  height: 200,

                  width: 140,

                  fit: BoxFit.cover,

                  placeholder: (context, url) =>
                      Container(color: Colors.grey.shade900),

                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              anime.title,

              maxLines: 2,

              overflow: TextOverflow.ellipsis,

              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
