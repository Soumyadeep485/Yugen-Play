import 'package:flutter/material.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../shared/models/anime.dart';

class InfoTab extends StatelessWidget {
  final Anime anime;

  const InfoTab({super.key, required this.anime});

  @override
  Widget build(BuildContext context) {
    final ratingText = anime.rating != null
        ? "${anime.rating!.toStringAsFixed(1)}/10"
        : "N/A";
    final statusText = anime.status ?? "N/A";
    final episodesText = anime.episodes != null ? "${anime.episodes}" : "N/A";
    final synopsisText =
        (anime.description != null && anime.description!.isNotEmpty)
        ? anime.description!
        : "No synopsis available.";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: () => debugPrint("Add to Library tapped"),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.surfaceVariant,
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.bookmark_add_outlined, size: 20),
              label: const Text(
                "Add to Library",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                "Statistics",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              _buildStatCard("Status", statusText),
              _buildStatCard("Rating", ratingText),
              _buildStatCard("Episodes", episodesText),
              _buildStatCard("ID", anime.id),
            ],
          ),
          const SizedBox(height: 24),
          const Row(
            children: [
              Icon(
                Icons.description_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                "Synopsis",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              synopsisText,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
