import 'package:flutter/material.dart';
import '../../../shared/models/anime.dart';
import '../widgets/anime_card.dart';

class SeeAllScreen extends StatelessWidget {
  final String title;
  final List<Anime> animeList;

  const SeeAllScreen({super.key, required this.title, required this.animeList});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // 3 cards across
          childAspectRatio: 0.55, // Taller cards to fit images and text
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
        ),
        itemCount: animeList.length,
        itemBuilder: (context, index) {
          return AnimeCard(
            anime: animeList[index],
            heroTag: 'SeeAll_${title}_${animeList[index].id}',
          );
        },
      ),
    );
  }
}
