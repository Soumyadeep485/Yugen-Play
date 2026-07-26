import 'package:flutter/material.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/radius/app_radius.dart';

class GenresScreen extends StatelessWidget {
  const GenresScreen({super.key});

  // Dummy data to match the UI. We will link this to the API later.
  static const List<String> _genres = [
    'ACTION',
    'ADVENTURE',
    'COMEDY',
    'DRAMA',
    'ECCHI',
    'FANTASY',
    'HENTAI',
    'HORROR',
    'MAHOU SHOUJO',
    'MECHA',
    'MUSIC',
    'MYSTERY',
    'PSYCHOLOGICAL',
    'ROMANCE',
    'SCI-FI',
    'SLICE OF LIFE',
    'SPORTS',
    'SUPERNATURAL',
    'THRILLER',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Fixed hardcoded 0xFF0D0D0F
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary), // Fixed
        title: const Text(
          "Genres",
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, 
          childAspectRatio: 1.8, 
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _genres.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Placeholder background color until we add real images
                Container(
                  color: Colors.primaries[index % Colors.primaries.length]
                      .withValues(alpha: 0.3),
                ),
                // Dark overlay to make text pop
                Container(color: Colors.black.withValues(alpha: 0.6)),
                Center(
                  child: Text(
                    _genres[index],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary, // Fixed
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}