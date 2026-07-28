import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/radius/app_radius.dart';
import '../../../../service_locator.dart';
import '../../../../shared/models/anime.dart';
import '../../../../shared/models/episode_metadata.dart';
import '../../../anime/presentation/widgets/m3_episode_card.dart';
import '../../../anime/presentation/widgets/release_countdown_card.dart';
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
  final String _selectedSource = 'Yugen Play (HLS)';
  Future<List<EpisodeMetadata>>? _episodesFuture;

  //  Chunking State Variables
  int _selectedChunkIndex = 0;
  final int _chunkSize = 24;

  int? _nextEpisodeNumber;
  DateTime? _nextEpisodeAirDate;

  @override
  void initState() {
    super.initState();
    _episodesFuture = _fetchEpisodeMetadata();
  }

  // Helper method to split the giant list into manageable chunks
  List<List<EpisodeMetadata>> _getChunks(List<EpisodeMetadata> episodes) {
    List<List<EpisodeMetadata>> chunks = [];
    for (var i = 0; i < episodes.length; i += _chunkSize) {
      int end = (i + _chunkSize < episodes.length)
          ? i + _chunkSize
          : episodes.length;
      chunks.add(episodes.sublist(i, end));
    }
    return chunks;
  }

  Future<List<EpisodeMetadata>> _fetchEpisodeMetadata() async {
    final fallbackThumbnail = widget.anime.bannerImage ?? widget.anime.coverImage ?? '';
    List<EpisodeMetadata> metadataList = [];

    try {
      final dio = Dio();
      final response = await dio.get(
        'https://api.ani.zip/mappings?anilist_id=${widget.anime.id}',
      );

      if (response.statusCode == 200 && response.data['episodes'] != null) {
        final episodesMap = response.data['episodes'] as Map<String, dynamic>;
        final epKeys = episodesMap.keys.map((k) => int.tryParse(k)).whereType<int>().toList();

        int maxAiredEp = 0;
        int? upcomingEpNum;
        DateTime? upcomingEpDate;

        for (final epNum in epKeys) {
          final epData = episodesMap[epNum.toString()];
          if (epData != null) {
            bool isAired = true;

            if (epData['airdate'] != null) {
              final airDate = DateTime.tryParse(epData['airdate'].toString());
              
              if (airDate != null && airDate.isAfter(DateTime.now())) {
                isAired = false; 
                
                // Catch the absolute closest future episode for the countdown
                // ignore: unnecessary_non_null_assertion
                if (upcomingEpDate == null || airDate.isBefore(upcomingEpDate!)) {
                  upcomingEpDate = airDate;
                  upcomingEpNum = epNum;
                }
              }
            }

            if (isAired && epNum > maxAiredEp) {
              maxAiredEp = epNum;
            }
          }
        }

        // Safely update the UI state with the upcoming episode info
        if (mounted) {
          setState(() {
            _nextEpisodeNumber = upcomingEpNum;
            _nextEpisodeAirDate = upcomingEpDate;
          });
        }

        if (maxAiredEp == 0 && widget.anime.episodes != null) {
          maxAiredEp = widget.anime.episodes!;
        }

        for (int i = 1; i <= maxAiredEp; i++) {
          final epData = episodesMap[i.toString()];
          if (epData != null) {
            metadataList.add(EpisodeMetadata.fromJson(epData, i, fallbackThumbnail));
          } else {
            metadataList.add(
              EpisodeMetadata(
                number: i,
                title: 'Episode $i',
                description: 'Tap to fetch extension streams and start playing.',
                thumbnail: fallbackThumbnail,
              ),
            );
          }
        }
        
        if (metadataList.isNotEmpty) {
          return metadataList;
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch AniZip metadata: $e');
    }

    final fallbackCount = widget.anime.episodes ?? 1; 
    for (int i = 1; i <= fallbackCount; i++) {
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
    int totalEpisodes,
  ) async {
    final playerController = locator<PlayerController>();
    bool isCancelled = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF14141B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                  ),
                  SizedBox(width: 16),
                  Text(
                    "Preparing stream",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Text(
                "Fetching fresh stream URLs from source...",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    ).then((_) => isCancelled = true); // 👇 2. Catch manual swipe-backs!

    final safeAnilistId = int.tryParse(widget.anime.id) ?? 0;

    await playerController.fetchStreamsForEpisode(
      episode: Episode(
        id: '${widget.anime.title}-ep-${metadata.number}',
        number: metadata.number,
        title: metadata.title,
        providerId: 'anikoto',
        anilistId: safeAnilistId,
      ),
      animeId: widget.anime.id.toString(),
      animeTitle: widget.anime.title,
      posterUrl: widget.anime.coverImage ?? widget.anime.bannerImage ?? '',
      totalEpisodes: widget.anime.episodes,
    );

    if (!context.mounted) return;

    // 👇 3. If they swiped back, stop everything and don't pop again!
    if (isCancelled) {
      debugPrint("User aborted stream fetch.");
      return; 
    }

    Navigator.pop(context);

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

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StreamQualityBottomSheet(
        streamLinks: playerController.streamLinks,
        selectedStream: playerController.selectedStream,
        onStreamSelected: (StreamLink stream) {
          playerController.selectStream(stream);

          Future.delayed(const Duration(milliseconds: 250), () {
            if (!context.mounted) return;

            final String currentEpisodeId = '${widget.anime.title}-ep-${metadata.number}';

            // REMOVE the WatchHistoryService().getHistory(...) logic entirely!

            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (_) => GlassyPlayerScreen(
                  title: '${widget.anime.title} - ${metadata.title}',
                  quality: stream.quality,
                  streamUrl: stream.url,
                  playerController: playerController,
                  animeId: widget.anime.id.toString(),
                  episodeId: currentEpisodeId,
                  episodeNumber: metadata.number,
                  posterUrl: widget.anime.coverImage ?? widget.anime.bannerImage ?? '',
                  
                  // 1. Pass the state exactly as it is when the button is pressed!
                  onNextEpisode: metadata.number >= totalEpisodes 
                      ? null 
                      : () {
                          final currentStream = playerController.selectedStream;
                          return _handleAutoPlayNext(
                            context, 
                            metadata.number + 1, 
                            'Episode ${metadata.number + 1}', 
                            totalEpisodes,
                            currentStream?.quality ?? '',      // 👈 Capturing Quality
                            currentStream?.sourceName ?? '',   // 👈 Capturing Server
                          );
                        },
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
              final chunks = _getChunks(episodes);

              if (_selectedChunkIndex >= chunks.length) {
                _selectedChunkIndex = 0;
              }

              final currentChunk = chunks[_selectedChunkIndex];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // 🛑 THE ACTUAL INJECTED COUNTDOWN CARD
                  if (_nextEpisodeNumber != null && _nextEpisodeAirDate != null)
                    ReleaseCountdownCard(
                      episodeNumber: _nextEpisodeNumber!,
                      targetDate: _nextEpisodeAirDate!,
                    ),

                  // Title and Episode Count
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
                        "${currentChunk.first.number} - ${currentChunk.last.number} / ${episodes.length}",
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // The Chunk Selector (Horizontal Scroll)
                  if (chunks.length > 1)
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: chunks.length,
                        itemBuilder: (context, index) {
                          final chunk = chunks[index];
                          final start = chunk.first.number;
                          final end = chunk.last.number;
                          final isSelected = _selectedChunkIndex == index;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(
                                '$start - $end',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: AppColors.primary,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.05,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedChunkIndex = index);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),

                  if (chunks.length > 1) const SizedBox(height: AppSpacing.md),

                  // The Episode List (Only renders the current chunk)
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: currentChunk.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final meta = currentChunk[index];
                      return M3EpisodeCard(
                        episodeNumber: meta.number,
                        title: meta.title,
                        description: meta.description,
                        thumbnailUrl: meta.thumbnail,
                        onTap: () => _openEpisodeStreams(context, meta, episodes.length),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
  Future<bool> _handleAutoPlayNext(
    BuildContext context, 
    int nextEpNum, 
    String nextEpTitle, 
    int totalEpisodes,
    String previousQuality, // 👈 New Parameter
    String previousSource,  // 👈 New Parameter
  ) async {
    final playerController = locator<PlayerController>();
    
    // We already know exactly what they were watching because we passed it in!
    final prevWasDub = previousQuality.toLowerCase().contains('dub');

    bool isCancelled = false;

    // 1. Show the Loading Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF14141B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text(
                "Loading next episode...",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    ).then((_) => isCancelled = true);

    // 2. Fetch Streams silently for the NEXT episode
    final nextEpisodeId = '${widget.anime.title}-ep-$nextEpNum';
    await playerController.fetchStreamsForEpisode(
      episode: Episode(
        id: nextEpisodeId,
        number: nextEpNum,
        title: nextEpTitle,
        providerId: 'anikoto', 
        anilistId: int.tryParse(widget.anime.id) ?? 0,
      ),
      animeId: widget.anime.id.toString(),
      animeTitle: widget.anime.title,
      posterUrl: widget.anime.coverImage ?? widget.anime.bannerImage ?? '',
      totalEpisodes: widget.anime.episodes,
    );

    if (!context.mounted) return false;
    if (isCancelled) return false;
    
    Navigator.pop(context); // Close dialog

    if (playerController.streamLinks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to find streams for Episode $nextEpNum."), backgroundColor: Colors.redAccent),
      );
      return false;
    }

    // 3. The Stream Picker (Simplified & Bulletproof)
    StreamLink? selectedStream;

    if (previousQuality.isNotEmpty) {
      // Step A: Filter to strictly Sub or strictly Dub
      List<StreamLink> candidateStreams = playerController.streamLinks.where((link) {
        final isDub = link.quality.toLowerCase().contains('dub'); 
        return prevWasDub ? isDub : !isDub; 
      }).toList();

      if (candidateStreams.isEmpty) {
        candidateStreams = playerController.streamLinks;
      }

      // Step B: Lock onto the EXACT server name (e.g. "VidPlay-1")
      try {
        selectedStream = candidateStreams.firstWhere(
          (link) => link.sourceName.toLowerCase().trim() == previousSource.toLowerCase().trim()
        );
      } catch (_) {
        // If that specific server is down, grab the first available in the correct Sub/Dub category
        selectedStream = candidateStreams.first;
      }
    }

    selectedStream ??= playerController.streamLinks.first;
    
    // 🛑 ONLY FIRED ONCE. NO RACE CONDITIONS. 🛑
    playerController.selectStream(selectedStream);

    // 4. Swap the player screen
    Navigator.of(context, rootNavigator: true).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GlassyPlayerScreen(
          title: '${widget.anime.title} - $nextEpTitle',
          quality: selectedStream!.quality,
          streamUrl: selectedStream.url,
          playerController: playerController,
          animeId: widget.anime.id.toString(),
          episodeId: nextEpisodeId,
          episodeNumber: nextEpNum,
          posterUrl: widget.anime.coverImage ?? widget.anime.bannerImage ?? '',
          startPosition: null, 
          // 5. Pass the exact state AGAIN for the next episode in the chain
          onNextEpisode: nextEpNum >= totalEpisodes 
              ? null 
              : () {
                  final currentStream = playerController.selectedStream;
                  return _handleAutoPlayNext(
                    context, 
                    nextEpNum + 1, 
                    'Episode ${nextEpNum + 1}', 
                    totalEpisodes,
                    currentStream?.quality ?? '',
                    currentStream?.sourceName ?? '',
                  );
                },
        ),
      ),
    );
    return true;
  }
}