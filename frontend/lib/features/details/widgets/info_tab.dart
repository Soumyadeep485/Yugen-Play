import 'package:flutter/material.dart';
import 'package:frontend/shared/models/anime_details.dart';
import '../../../core/colors/app_colors.dart';
import '../../../core/radius/app_radius.dart';
import '../../../shared/widgets/premium_network_image.dart';
import '../data/details_repository.dart';

class InfoTab extends StatefulWidget {
  final int animeId;
  final ScrollController scrollController;

  const InfoTab({
    super.key,
    required this.animeId,
    required this.scrollController,
  });

  @override
  State<InfoTab> createState() => _InfoTabState();
}

class _InfoTabState extends State<InfoTab> {
  final DetailsRepository _repository = DetailsRepository();
  late Future<AnimeDetails> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _repository.fetchAnimeDetails(widget.animeId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AnimeDetails>(
      future: _detailsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error loading data:\n${snapshot.error}",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54),
            ),
          );
        }

        if (!snapshot.hasData) return const SizedBox.shrink();

        final details = snapshot.data!;

        return ListView(
          controller: widget.scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Dynamic Cover Art
                Hero(
                  tag: 'Card_${details.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: PremiumNetworkImage(
                      imageUrl: details.imageUrl,
                      width: 120,
                      height: 175,
                      memCacheHeight: 400,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Right Column: Live Data Grid
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMetaRow(
                        "Mean Score",
                        details.meanScore > 0
                            ? "⭐ ${details.meanScore}"
                            : "N/A",
                      ),
                      _buildMetaRow("Status", details.status),
                      _buildMetaRow("Format", details.format),
                      _buildMetaRow(
                        "Episodes",
                        details.episodes?.toString() ?? "?",
                      ),
                      _buildMetaRow(
                        "Duration",
                        details.duration != null
                            ? "${details.duration} min"
                            : "?",
                      ),
                      _buildMetaRow("Source", details.source),
                      _buildMetaRow(
                        "Season",
                        "${details.season} ${details.seasonYear ?? ''}".trim(),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              "Synopsis",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              details.description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "Genres",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: details.genres
                  .map((genre) => _buildGenrePill(genre))
                  .toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenrePill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
