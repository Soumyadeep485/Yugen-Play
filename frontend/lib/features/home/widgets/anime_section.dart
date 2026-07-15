import 'package:flutter/material.dart';
import 'package:frontend/features/home/screens/see_all_screen.dart';

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
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SeeAllScreen(title: title, animeList: animeList),
                    ),
                  );
                },
                child: const Text(
                  "See All",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Slashed the height from 310 down to 230 to remove the dead space.
        // If your text still clips at the bottom, bump this up to 240.
        SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemBuilder: (context, index) {
              return AnimeCard(
                anime: animeList[index],
                heroTag: '${title}_${animeList[index].id}',
              );
            },
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemCount: animeList.length,
          ),
        ),
      ],
    );
  }
}
