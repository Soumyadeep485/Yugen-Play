import 'package:flutter/material.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../shared/models/anime.dart';
import '../../../details/presentation/screens/anime_details_screen.dart';
import '../widgets/anime_card.dart';

class SeeAllScreen extends StatelessWidget {
  final String title;
  final List<Anime> animeList;

  const SeeAllScreen({
    super.key,
    required this.title,
    required this.animeList,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Purged Color(0xFF0D0D0F)
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.55,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
        ),
        itemCount: animeList.length,
        itemBuilder: (context, index) {
          final anime = animeList[index];

          return AnimeCard(
            anime: anime,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AnimeDetailsScreen(anime: anime),
                ),
              );
            },
          );
        },
      ),
    );
  }
}