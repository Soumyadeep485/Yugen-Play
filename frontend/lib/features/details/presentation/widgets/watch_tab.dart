import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/radius/app_radius.dart';
import '../../../../service_locator.dart';
import '../../../../shared/models/anime.dart';
import '../../../../shared/models/episode_metadata.dart'; // Add this import
import '../../../anime/presentation/widgets/m3_episode_card.dart';
import '../../../player/controllers/player_controller.dart';
import '../../../player/models/episode.dart';
import '../../../player/models/stream_link.dart';
import '../../../player/presentation/screens/glassy_player_screen.dart';
import '../../../player/presentation/widgets/stream_quality_bottom_sheet.dart';

class WatchTab extends StatefulWidget {
  final Anime anime;

  const WatchTab({super.key, required this.anime});

  @override
  State<WatchTab> createState() => _WatchTabState();
}

class _WatchTabState extends State<WatchTab> {
  final String _selectedSource = 'Anikoto (HLS)';
  Future<List<EpisodeMetadata>>? _episodesFuture;

  @override
  void initState() {
    super.initState();
    // Start fetching metadata immediately when the tab opens
    _episodesFuture = _fetchEpisodeMetadata();
  }

  Future<List<EpisodeMetadata>> _fetchEpisodeMetadata() async {
    final totalEpisodes = widget.anime.episodes ?? 12;
    final fallbackThumbnail =
        widget.anime.bannerImage ?? widget.anime.coverImage ?? '';
    List<EpisodeMetadata> metadataList = [];

    try {
      final dio = Dio();
      // AniZip is the standard for mapping AniList IDs to episode metadata
      final response = await dio.get(
        'https://api.ani.zip/mappings?anilist_id=${widget.anime.id}',
      );

      if (response.statusCode == 200 && response.data['episodes'] != null) {
        final episodesMap = response.data['episodes'] as Map<String, dynamic>;

        for (int i = 1; i <= totalEpisodes; i++) {
          final epData = episodesMap[i.toString()];
          if (epData != null) {
            metadataList.add(
              EpisodeMetadata.fromJson(epData, i, fallbackThumbnail),
            );
          } else {
            // If AniZip is missing an episode, fallback to generic data
            metadataList.add(
              EpisodeMetadata(
                number: i,
                title: 'Episode $i',
                description:
                    'Tap to fetch extension streams and start playing.',
                thumbnail: fallbackThumbnail,
              ),
            );
          }
        }
        return metadataList;
      }
    } catch (e) {
      debugPrint('Failed to fetch AniZip metadata: $e');
    }

    // Fallback: If API fails, generate generic cards so the user can still watch
    for (int i = 1; i <= totalEpisodes; i++) {
      metadataList.add(
        EpisodeMetadata(
          number: i,
          title: 'Episode $i',
          description: 'Tap to fetch extension streams and start playing.',
          thumbnail: fallbackThumbnail,
        ),
      );
    }
    return metadataList;
  }

  Future<void> _openEpisodeStreams(
    BuildContext context,
    EpisodeMetadata metadata,
  ) async {
    final playerController = locator<PlayerController>();

    // 1. Show Loading Sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StreamQualityBottomSheet(
        streamLinks: const [],
        selectedStream: null,
        onStreamSelected: (_) {},
        isLoading: true,
      ),
    );

    final safeAnilistId = int.tryParse(widget.anime.id) ?? 0;

    // 2. Fetch Streams
    await playerController.fetchStreamsForEpisode(
      Episode(
        id: '${widget.anime.title}-ep-${metadata.number}',
        number: metadata.number,
        title: metadata.title,
        providerId: 'anikoto',
        anilistId: safeAnilistId,
      ),
    );

    // 3. Close Loading Sheet
    if (!context.mounted) return;
    Navigator.pop(context);

    // 4. Handle Empty Streams
    if (playerController.streamLinks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            playerController.errorMessage ??
                "No active streams found for this episode.",
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!context.mounted) return;

    // 5. Show Stream Selection Sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StreamQualityBottomSheet(
        streamLinks: playerController.streamLinks,
        selectedStream: playerController.selectedStream,
        onStreamSelected: (StreamLink stream) {
          // 1. Update the controller
          playerController.selectStream(stream);

          // 🛑 THE FIX: Wait 250ms for the bottom sheet to finish closing,
          // then push the player on the ROOT navigator to break out of the tabs.
          Future.delayed(const Duration(milliseconds: 250), () {
            if (!context.mounted) return;

            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (_) => GlassyPlayerScreen(
                  title: '${widget.anime.title} - ${metadata.title}',
                  quality: stream.quality,
                  streamUrl: stream.url,
                  playerController: playerController,
                ),
              ),
            );
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Provider Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.extension_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  _selectedSource,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Text(
                    'HLS EXTENSION',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Episodes",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "1 - ${widget.anime.episodes ?? '?'}",
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Dynamic Episode List via FutureBuilder
          FutureBuilder<List<EpisodeMetadata>>(
            future: _episodesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }

              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data!.isEmpty) {
                return const Center(child: Text('Failed to load episodes.'));
              }

              final episodes = snapshot.data!;

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: episodes.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final meta = episodes[index];
                  return M3EpisodeCard(
                    episodeNumber: meta.number,
                    title: meta.title,
                    description: meta.description,
                    thumbnailUrl: meta.thumbnail,
                    onTap: () => _openEpisodeStreams(context, meta),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
