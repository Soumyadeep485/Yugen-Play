import 'package:flutter/material.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../shared/models/anime.dart';
import 'anime_card.dart';

class AnimeSection extends StatelessWidget {
  final String title;
  final List<Anime> animeList;
  final Function(Anime) onAnimeTap;
  final VoidCallback? onSeeAllPressed;

  const AnimeSection({
    super.key,
    required this.title,
    required this.animeList,
    required this.onAnimeTap,
    this.onSeeAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              GestureDetector(
                onTap: onSeeAllPressed,
                child: const Text(
                  "See All",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 265,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: animeList.length,
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            itemBuilder: (context, index) {
              final anime = animeList[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: AnimeCard(anime: anime, onTap: () => onAnimeTap(anime)),
              );
            },
          ),
        ),
      ],
    );
  }
}