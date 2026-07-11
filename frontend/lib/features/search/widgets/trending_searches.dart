import 'package:flutter/material.dart';

class TrendingSearches extends StatelessWidget {
  const TrendingSearches({super.key});

  @override
  Widget build(BuildContext context) {
    final trending = [
      "Dandadan",
      "Solo Leveling",
      "Chainsaw Man",
      "Blue Lock",
      "Jujutsu Kaisen",
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Trending",
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: Colors.white),
        ),

        const SizedBox(height: 14),

        ...trending.map(
          (anime) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.trending_up, color: Colors.redAccent),
            title: Text(anime, style: const TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }
}
