import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/features/player/services/extension_manager.dart';
import 'package:frontend/features/player/services/extension_provider.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/radius/app_radius.dart';
import '../../../../core/utils/device_type.dart';
import '../../../../service_locator.dart';
import '../../../../shared/models/anime.dart';
import '../../../../shared/models/episode_metadata.dart';
import '../../../../database/kv_helper.dart';

import '../../../anime/presentation/widgets/m3_episode_card.dart';
import '../../../anime/presentation/widgets/release_countdown_card.dart';
import '../../../history/services/watch_history_service.dart';
import '../../../player/controllers/player_controller.dart';
import '../../../player/models/episode.dart';
import '../../../player/presentation/screens/glassy_player_screen.dart';
import '../../../player/presentation/widgets/stream_loading_dialog.dart';
import '../../../tv/presentation/screens/tv_player_screen.dart';
import '../../../anime/presentation/widgets/wrong_title_modal.dart';

class WatchTab extends StatefulWidget {
  final Anime anime;

  const WatchTab({super.key, required this.anime});

  @override
  State<WatchTab> createState() => _WatchTabState();
}

class _WatchTabState extends State<WatchTab> {
  Future<List<EpisodeMetadata>>? _episodesFuture;

  int _selectedChunkIndex = 0;
  final int _chunkSize = 24;

  int? _nextEpisodeNumber;
  DateTime? _nextEpisodeAirDate;
  
  String? _activeCustomSlug;
  String? _activeCustomAnilistId; 

  // 🚀 TV UI Focus State Tracking
  bool _isHeaderActionFocused = false;
  int? _focusedChunkIndex;

  ExtensionProvider? get _ext => locator<ExtensionManager>().activeExtensions.values.firstOrNull;

  @override
  void initState() {
    super.initState();
    _loadStickyCache();
    _episodesFuture = _fetchEpisodeMetadata();
  }

  void _loadStickyCache() {
    final raw = DynamicKeys.stickySource.get<String?>(widget.anime.id.toString());
    if (raw != null && raw.contains('|||')) {
      _activeCustomSlug = raw.split('|||')[0];
    } else {
      _activeCustomSlug = raw;
    }
  }

  void _openWrongTitleModal() {
    final activeExtension = _ext;
    
    if (activeExtension == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please install an extension first."),
          backgroundColor: AppColors.card,
        ),
      );
      return;
    }

    showWrongTitleModal<Map<String, String>>(
      context: context,
      initialText: widget.anime.title,
      mediaId: widget.anime.id,
      sourceName: activeExtension.name, 
      searchExtension: (query) async {
        return await activeExtension.search(query); 
      },
      getTitle: (item) => item['title'] ?? 'Unknown',
      getPoster: (item) => item['poster'] ?? '',
      getUrl: (item) => item['url'] ?? '',
      onBind: (selectedItem) async {
        if (!mounted) return;

        final selectedSlug = selectedItem['url'];

        if (selectedSlug != null && selectedSlug.isNotEmpty) {
          DynamicKeys.stickySource.set(widget.anime.id.toString(), selectedSlug);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Bound to: ${selectedItem['title']}"),
              backgroundColor: AppColors.card,
            ),
          );

          setState(() {
            _activeCustomSlug = selectedSlug;
            _episodesFuture = _fetchEpisodeMetadata(); 
          });
        }
      },
    );
  }

  Future<List<EpisodeMetadata>> _fetchEpisodeMetadata() async {
    final fallbackThumbnail = widget.anime.bannerImage ?? widget.anime.coverImage ?? '';
    List<EpisodeMetadata> metadataList = [];
    final activeExtension = _ext;

    if (_activeCustomSlug != null && activeExtension != null) {
      try {
        final epList = await (activeExtension as dynamic).getEpisodes(_activeCustomSlug!);

        if (epList.isNotEmpty) {
          for (var ep in epList) {
            metadataList.add(
              EpisodeMetadata(
                number: (ep['number'] as num?)?.toInt() ?? 1,
                title: ep['title']?.toString() ?? 'Episode ${ep['number']}',
                description: 'Stream directly mapped from ${activeExtension.name}.',
                thumbnail: ep['thumbnail']?.toString() ?? fallbackThumbnail,
              ),
            );
          }
        } else {
          final epCount = await activeExtension.getEpisodeCount(_activeCustomSlug!);
          for (int i = 1; i <= epCount; i++) {
            metadataList.add(
              EpisodeMetadata(
                number: i,
                title: 'Episode $i',
                description: 'Stream directly mapped from ${activeExtension.name}.',
                thumbnail: fallbackThumbnail,
              ),
            );
          }
        }
        
        if (mounted) {
          setState(() {
            _nextEpisodeNumber = null;
            _nextEpisodeAirDate = null;
          });
        }
        return metadataList;
      } catch (e) {
        debugPrint('Failed to load extension episodes: $e');
      }
    }

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
                if (upcomingEpDate == null || airDate.isBefore(upcomingEpDate)) {
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

        if (mounted) {
          setState(() {
            _nextEpisodeNumber = upcomingEpNum;
            _nextEpisodeAirDate = upcomingEpDate;
          });
        }

        final fallbackCount = maxAiredEp > 0 ? maxAiredEp : (widget.anime.episodes ?? 1);

        for (int i = 1; i <= fallbackCount; i++) {
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
        if (metadataList.isNotEmpty) return metadataList;
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

  void _clearMapping() {
    DynamicKeys.stickySource.delete(widget.anime.id.toString());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Custom mapping removed. Reset to default."),
        backgroundColor: AppColors.card,
      ),
    );
    setState(() {
      _activeCustomSlug = null;
      _activeCustomAnilistId = null;
      _episodesFuture = _fetchEpisodeMetadata();
    });
  }

  Future<void> _openEpisodeStreams(
    BuildContext context,
    EpisodeMetadata metadata,
    int totalEpisodes,
  ) async {
    final safeAnilistId = int.tryParse(_activeCustomAnilistId ?? widget.anime.id) ?? 0;
    final targetTitle = _activeCustomSlug ?? widget.anime.title;
    final activeExtension = _ext; 

    final cleanTarget = targetTitle.replaceAll(RegExp(r'(/ep-\d+|-ep-\d+)+$'), '');
    final episodeId = '$cleanTarget/ep-${metadata.number}';

    final historyService = WatchHistoryService();
    Duration? savedPosition;
    final savedData = historyService.getHistory(widget.anime.id.toString());
    if (savedData != null &&
        (savedData['episodeNumber'] == metadata.number || savedData['episodeId'] == episodeId)) {
      final int posMs = savedData['positionMs'] ?? 0;
      if (posMs > 0) savedPosition = Duration(milliseconds: posMs);
    }

    final playerController = locator<PlayerController>();

    if (!context.mounted) return;

    StreamLoadingDialog.show(
      context,
      playerController: playerController,
      episode: Episode(
        id: episodeId,
        number: metadata.number,
        title: metadata.title,
        providerId: activeExtension?.pkgName ?? 'unknown',
        anilistId: safeAnilistId,
      ),
      animeId: widget.anime.id.toString(),
      animeTitle: targetTitle,
      posterUrl: widget.anime.coverImage ?? widget.anime.bannerImage ?? '',
      totalEpisodes: totalEpisodes, 
      startPosition: savedPosition,
      onStreamReady: (stream) {
        Widget playerScreen = DeviceType.isTv
            ? TvPlayerScreen(
                title: '${widget.anime.title} - ${metadata.title}',
                quality: stream.quality,
                streamUrl: stream.url,
                playerController: playerController,
                animeId: widget.anime.id.toString(),
                episodeId: episodeId,
                episodeNumber: metadata.number,
                posterUrl: widget.anime.coverImage ?? widget.anime.bannerImage ?? '',
                onNextEpisode: metadata.number >= totalEpisodes ? null : () {
                  final currentStream = playerController.selectedStream;
                  return _handleAutoPlayNext(
                    context, metadata.number + 1, 'Episode ${metadata.number + 1}',
                    totalEpisodes, currentStream?.quality ?? '', currentStream?.sourceName ?? '',
                    targetTitle, safeAnilistId,
                  );
                },
              )
            : GlassyPlayerScreen(
                title: '${widget.anime.title} - ${metadata.title}',
                quality: stream.quality,
                streamUrl: stream.url,
                playerController: playerController,
                animeId: widget.anime.id.toString(),
                episodeId: episodeId,
                episodeNumber: metadata.number,
                posterUrl: widget.anime.coverImage ?? widget.anime.bannerImage ?? '',
                onNextEpisode: metadata.number >= totalEpisodes ? null : () {
                  final currentStream = playerController.selectedStream;
                  return _handleAutoPlayNext(
                    context, metadata.number + 1, 'Episode ${metadata.number + 1}',
                    totalEpisodes, currentStream?.quality ?? '', currentStream?.sourceName ?? '',
                    targetTitle, safeAnilistId,
                  );
                },
              );

        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(builder: (_) => playerScreen),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: _activeCustomSlug != null ? Colors.orange.withValues(alpha: 0.3) : Colors.white10,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.extension_rounded,
                  color: _activeCustomSlug != null ? Colors.orange : AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  _ext?.name ?? 'No Extension', 
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),

                if (_activeCustomSlug != null)
                  // 🚀 THE FIX: Native InkWell Focus handling
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _clearMapping,
                      onFocusChange: (focused) => setState(() => _isHeaderActionFocused = focused),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isHeaderActionFocused ? Colors.orange.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                            color: _isHeaderActionFocused ? Colors.white : Colors.orange.withValues(alpha: 0.3),
                            width: _isHeaderActionFocused ? 1.5 : 1.0,
                          ),
                          boxShadow: _isHeaderActionFocused ? [BoxShadow(color: Colors.orange.withValues(alpha: 0.5), blurRadius: 8)] : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.refresh_rounded, color: _isHeaderActionFocused ? Colors.white : Colors.orange, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Reset Mapping',
                              style: TextStyle(
                                color: _isHeaderActionFocused ? Colors.white : Colors.orange,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _openWrongTitleModal, 
                      onFocusChange: (focused) => setState(() => _isHeaderActionFocused = focused),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isHeaderActionFocused ? AppColors.primary.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                            color: _isHeaderActionFocused ? Colors.white : Colors.white12,
                            width: _isHeaderActionFocused ? 1.5 : 1.0,
                          ),
                          boxShadow: _isHeaderActionFocused ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 8)] : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_note_rounded, color: _isHeaderActionFocused ? Colors.white : AppColors.primary, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Wrong Title?',
                              style: TextStyle(
                                color: _isHeaderActionFocused ? Colors.white : AppColors.textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(width: 8),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

          FutureBuilder<List<EpisodeMetadata>>(
            future: _episodesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                );
              }

              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
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
                  if (_nextEpisodeNumber != null && _nextEpisodeAirDate != null)
                    ReleaseCountdownCard(
                      episodeNumber: _nextEpisodeNumber!,
                      targetDate: _nextEpisodeAirDate!,
                    ),

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
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  if (chunks.length > 1)
                    SizedBox(
                      height: 44, 
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: chunks.length,
                        itemBuilder: (context, index) {
                          final chunk = chunks[index];
                          final start = chunk.first.number;
                          final end = chunk.last.number;
                          final isSelected = _selectedChunkIndex == index;
                          final isFocused = _focusedChunkIndex == index;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0, top: 2, bottom: 2),
                            // 🚀 THE FIX: Use standard Focus widget with onFocusChange
                            child: Focus(
                              onFocusChange: (focused) {
                                setState(() {
                                  if (focused) _focusedChunkIndex = index;
                                  else if (_focusedChunkIndex == index) _focusedChunkIndex = null;
                                });
                              },
                              child: Transform.scale(
                                scale: isFocused ? 1.05 : 1.0,
                                child: ChoiceChip(
                                  label: Text(
                                    '$start - $end',
                                    style: TextStyle(
                                      color: isSelected || isFocused ? Colors.white : AppColors.textSecondary,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: AppColors.primary,
                                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: isFocused 
                                          ? Colors.white 
                                          : (isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.1)),
                                      width: isFocused ? 2.0 : 1.0,
                                    ),
                                  ),
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() => _selectedChunkIndex = index);
                                    }
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  if (chunks.length > 1) const SizedBox(height: AppSpacing.md),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: currentChunk.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
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
    String previousQuality,
    String previousSource,
    String mappedTitle,
    int mappedAnilistId,
  ) async {
    final prevWasDub = previousQuality.toLowerCase().contains('dub');
    final nextEpisodeId = '$mappedTitle-ep-$nextEpNum';
    final activeExtension = _ext;

    final playerController = locator<PlayerController>();

    if (!context.mounted) return false;

    StreamLoadingDialog.show(
      context,
      playerController: playerController,
      episode: Episode(
        id: nextEpisodeId,
        number: nextEpNum,
        title: nextEpTitle,
        providerId: activeExtension?.pkgName ?? 'unknown',
        anilistId: mappedAnilistId,
      ),
      animeId: widget.anime.id.toString(),
      animeTitle: mappedTitle,
      posterUrl: widget.anime.coverImage ?? widget.anime.bannerImage ?? '',
      totalEpisodes: totalEpisodes,
      autoSelectDub: prevWasDub,
      onStreamReady: (stream) {
        Widget nextPlayerScreen = DeviceType.isTv
            ? TvPlayerScreen(
                title: '${widget.anime.title} - $nextEpTitle',
                quality: stream.quality,
                streamUrl: stream.url,
                playerController: playerController,
                animeId: widget.anime.id.toString(),
                episodeId: nextEpisodeId,
                episodeNumber: nextEpNum,
                posterUrl: widget.anime.coverImage ?? widget.anime.bannerImage ?? '',
                onNextEpisode: nextEpNum >= totalEpisodes ? null : () {
                  final currentStream = playerController.selectedStream;
                  return _handleAutoPlayNext(
                    context, nextEpNum + 1, 'Episode ${nextEpNum + 1}',
                    totalEpisodes, currentStream?.quality ?? '', currentStream?.sourceName ?? '',
                    mappedTitle, mappedAnilistId,
                  );
                },
              )
            : GlassyPlayerScreen(
                title: '${widget.anime.title} - $nextEpTitle',
                quality: stream.quality,
                streamUrl: stream.url,
                playerController: playerController,
                animeId: widget.anime.id.toString(),
                episodeId: nextEpisodeId,
                episodeNumber: nextEpNum,
                posterUrl: widget.anime.coverImage ?? widget.anime.bannerImage ?? '',
                onNextEpisode: nextEpNum >= totalEpisodes ? null : () {
                  final currentStream = playerController.selectedStream;
                  return _handleAutoPlayNext(
                    context, nextEpNum + 1, 'Episode ${nextEpNum + 1}',
                    totalEpisodes, currentStream?.quality ?? '', currentStream?.sourceName ?? '',
                    mappedTitle, mappedAnilistId,
                  );
                },
              );
        Navigator.of(context, rootNavigator: true).pushReplacement(
          MaterialPageRoute(builder: (_) => nextPlayerScreen),
        );
      },
    );
    return true;
  }
}