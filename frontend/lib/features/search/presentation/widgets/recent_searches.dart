import 'package:flutter/material.dart';

import '../../../../core/colors/app_colors.dart';

class RecentSearches extends StatelessWidget {
  const RecentSearches({super.key});

  @override
  Widget build(BuildContext context) {
    final recent = ["Naruto", "One Piece", "Attack on Titan"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recent Searches",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary, // Fixed hardcoded white
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: recent.map((anime) {
            return Chip(
              label: Text(
                anime,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              backgroundColor: AppColors.card,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
