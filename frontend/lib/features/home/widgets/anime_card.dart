import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../shared/models/anime.dart';

class AnimeCard extends StatelessWidget {
  final Anime anime;

  const AnimeCard({super.key, required this.anime});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),

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
    );
  }
}
