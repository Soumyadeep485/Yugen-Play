import 'package:flutter/material.dart';

import '../../../shared/models/anime.dart';
import 'anime_card.dart';

class AnimeSection extends StatelessWidget {
  final String title;

  final List<Anime> animeList;

  const AnimeSection({super.key, required this.title, required this.animeList});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),

          child: Row(
            children: [
              Text(
                title,

                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),

              const Spacer(),

              TextButton(onPressed: () {}, child: const Text("See All")),
            ],
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          height: 310,

          child: ListView.separated(
            scrollDirection: Axis.horizontal,

            padding: const EdgeInsets.symmetric(horizontal: 20),

            itemBuilder: (context, index) {
              return AnimeCard(anime: animeList[index]);
            },

            separatorBuilder: (context, index) => const SizedBox(width: 14),

            itemCount: animeList.length,
          ),
        ),
      ],
    );
  }
}
