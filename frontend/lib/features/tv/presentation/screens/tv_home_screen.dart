import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../core/storage/hive_boxes.dart';
import '../../../../service_locator.dart';
import '../../../../shared/models/anime.dart';
import '../../../history/services/watch_history_service.dart';
import '../../../home/controllers/home_provider.dart';
import '../../../player/controllers/player_controller.dart';
import '../../../player/models/episode.dart';
import '../../../player/models/stream_link.dart';
import '../../../player/presentation/widgets/stream_quality_bottom_sheet.dart';
import '../widgets/tv_update_dialog.dart';
import 'tv_anime_details_screen.dart';
import 'tv_player_screen.dart';

class TvHomeScreen extends ConsumerStatefulWidget {
  const TvHomeScreen({super.key});

  @override
  ConsumerState<TvHomeScreen> createState() => _TvHomeScreenState();
}

class _TvHomeScreenState extends ConsumerState<TvHomeScreen> {
  
  @override
  void initState() {
    super.initState();
    // 🚀 Fire the update check immediately when the TV home screen loads
    _checkForUpdates(); 
  }

  // ============================================================================
  // UPDATE CHECKER LOGIC
  // ============================================================================
  Future<void> _checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version.replaceAll(RegExp(r'[^0-9.]'), '');

      final dio = Dio();
      final response = await dio.get('https://api.github.com/repos/Soumyadeep485/Yugen-Play/releases/latest');

      if (response.statusCode == 200) {
        final data = response.data;
        
        final String latestVersion = data['tag_name'].toString().replaceAll(RegExp(r'[^0-9.]'), '');
        final String releaseNotes = data['body'] ?? "Minor bug fixes and performance improvements.";
        
        String? downloadUrl;
        if (data['assets'] != null && (data['assets'] as List).isNotEmpty) {
          final assets = data['assets'] as List;
          final apkAsset = assets.firstWhere(
            (asset) => asset['name'].toString().endsWith('.apk'), 
            orElse: () => null,
          );
          if (apkAsset != null) {
            downloadUrl = apkAsset['browser_download_url'];
          }
        }

        if (downloadUrl != null && _isNewerVersion(currentVersion, latestVersion)) {
          if (!mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false, 
            builder: (context) => TvUpdateDialog(
              version: latestVersion, 
              releaseNotes: releaseNotes,
              downloadUrl: downloadUrl!,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Update check failed: $e");
    }
  }

  bool _isNewerVersion(String current, String latest) {
    final currParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      final c = currParts.length > i ? currParts[i] : 0;
      final l = latestParts.length > i ? latestParts[i] : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false; 
  }

  // ============================================================================
  // UI BUILDER
  // ============================================================================
  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);

    return Scaffold(
      backgroundColor: Colors.black, 
      body: SafeArea(
        child: homeState.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 32.0),
                children: [
                  // HERO BANNER
                  if (homeState.data.popular.isNotEmpty)
                    _TvHeroBanner(animeList: homeState.data.popular.take(5).toList()),

                  const SizedBox(height: 48),

                  // CONTINUE WATCHING
                  const _TvContinueWatchingSection(),

                  // POPULAR ANIMES
                  _TvAnimeSection(
                    title: "Trending Now",
                    animeList: homeState.data.popular,
                  ),

                  const SizedBox(height: 24),

                  // NEW RELEASES
                  _TvAnimeSection(
                    title: "New Releases",
                    animeList: homeState.data.seasonal,
                  ),

                  const SizedBox(height: 60),
                ],
              ),
      ),
    );
  }
}

// ============================================================================
// 1. SLEEK LOW-RESOURCE HERO BANNER
// ============================================================================
class _TvHeroBanner extends StatefulWidget {
  final List<Anime> animeList;

  const _TvHeroBanner({required this.animeList});

  @override
  State<_TvHeroBanner> createState() => _TvHeroBannerState();
}

class _TvHeroBannerState extends State<_TvHeroBanner> {
  int _currentIndex = 0;
  Timer? _timer;
  bool _isPaused = false; // 🚀 Pauses banner rotation when focused

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted && widget.animeList.isNotEmpty && !_isPaused) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.animeList.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.animeList.isEmpty) return const SizedBox.shrink();
    final anime = widget.animeList[_currentIndex];
    final imageUrl = anime.bannerImage ?? anime.coverImage ?? '';
    
    final ratingText = anime.rating != null ? "⭐ ${anime.rating!.toStringAsFixed(1)}" : "⭐ N/A";
    final episodesText = anime.episodes != null ? "${anime.episodes} Episodes" : "ANIME";
    final statusText = anime.status?.toUpperCase() ?? "RELEASING";

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Container(
        key: ValueKey<int>(_currentIndex),
        height: 340, 
        decoration: BoxDecoration(
          color: const Color(0xFF14141B), 
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5), 
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25), 
              blurRadius: 40, 
              spreadRadius: -10,
              offset: const Offset(0, 20),
            )
          ],
        ),
        child: Stack(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          color: Colors.white,
                          child: Text(
                            statusText,
                            style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          anime.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, height: 1.2),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "$ratingText  •  $episodesText",
                          style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 24),
                        _TvWatchNowButton(
                          anime: anime,
                          onFocusChange: (focused) {
                            setState(() => _isPaused = focused);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(15)),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          cacheWidth: 800, 
                          errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[900]),
                        ),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [Color(0xFF14141B), Colors.transparent],
                            stops: [0.0, 0.5],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.animeList.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 24 : 8,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _currentIndex == index ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TvWatchNowButton extends StatefulWidget {
  final Anime anime;
  final ValueChanged<bool>? onFocusChange;

  const _TvWatchNowButton({required this.anime, this.onFocusChange});

  @override
  State<_TvWatchNowButton> createState() => _TvWatchNowButtonState();
}

class _TvWatchNowButtonState extends State<_TvWatchNowButton> {
  bool _isFocused = false;

  void _handleFocusChange(bool focused) {
    setState(() => _isFocused = focused);
    widget.onFocusChange?.call(focused);
    
    // 🚀 Auto-scroll viewport into view when focused
    if (focused && mounted) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => TvAnimeDetailsScreen(anime: widget.anime)));
        },
        onFocusChange: _handleFocusChange,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutQuart,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          transform: Matrix4.diagonal3Values(_isFocused ? 1.05 : 1.0, _isFocused ? 1.05 : 1.0, 1.0),
          decoration: BoxDecoration(
            color: _isFocused ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: _isFocused ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.6), blurRadius: 16, spreadRadius: 2)] : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_arrow_rounded, color: _isFocused ? Colors.white : Colors.black, size: 22),
              const SizedBox(width: 8),
              Text(
                "Watch Now",
                style: TextStyle(
                  color: _isFocused ? Colors.white : Colors.black, 
                  fontSize: 16, 
                  fontWeight: FontWeight.bold
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 2. TV CONTINUE WATCHING SECTION (WITH AUTO-PLAY LOGIC)
// ============================================================================
class _TvContinueWatchingSection extends StatefulWidget {
  const _TvContinueWatchingSection();

  @override
  State<_TvContinueWatchingSection> createState() => _TvContinueWatchingSectionState();
}

class _TvContinueWatchingSectionState extends State<_TvContinueWatchingSection> {
  final WatchHistoryService _historyService = WatchHistoryService();

  Future<bool> _handleAutoPlayNext(
    BuildContext context, 
    int nextEpNum, 
    String animeTitle, 
    String animeId, 
    String poster, 
    String previousQuality, 
    String previousSource,
  ) async {
    final playerController = locator<PlayerController>();
    final prevWasDub = previousQuality.toLowerCase().contains('dub');
    bool isCancelled = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF14141B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
              const SizedBox(width: 16),
              Text("Loading Episode $nextEpNum...", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    ).then((_) => isCancelled = true);

    final nextEpisodeId = '$animeTitle-ep-$nextEpNum';
    await playerController.fetchStreamsForEpisode(
      episode: Episode(
        id: nextEpisodeId,
        number: nextEpNum,
        title: 'Episode $nextEpNum',
        providerId: 'anikoto', 
        anilistId: int.tryParse(animeId) ?? 0,
      ),
      animeId: animeId,
      animeTitle: animeTitle,
      posterUrl: poster,
      totalEpisodes: null,
    );

    if (!context.mounted) return false;
    if (isCancelled) return false;
    Navigator.pop(context);

    if (playerController.streamLinks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to find streams for next episode."), backgroundColor: Colors.redAccent));
      return false;
    }

    StreamLink? selectedStream;
    if (previousQuality.isNotEmpty) {
      List<StreamLink> candidateStreams = playerController.streamLinks.where((link) {
        final isDub = link.quality.toLowerCase().contains('dub'); 
        return prevWasDub ? isDub : !isDub; 
      }).toList();

      if (candidateStreams.isEmpty) candidateStreams = playerController.streamLinks;

      try {
        selectedStream = candidateStreams.firstWhere((link) => link.sourceName.toLowerCase().trim() == previousSource.toLowerCase().trim());
      } catch (_) {
        selectedStream = candidateStreams.first;
      }
    }
    selectedStream ??= playerController.streamLinks.first;
    playerController.selectStream(selectedStream);

    Navigator.of(context, rootNavigator: true).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TvPlayerScreen(
          title: '$animeTitle - Episode $nextEpNum',
          quality: selectedStream!.quality,
          streamUrl: selectedStream.url, 
          playerController: playerController,
          animeId: animeId,
          episodeId: nextEpisodeId,
          episodeNumber: nextEpNum,
          posterUrl: poster,
          onNextEpisode: () {
            final currentStream = playerController.selectedStream;
            return _handleAutoPlayNext(
              context, nextEpNum + 1, animeTitle, animeId, poster, 
              currentStream?.quality ?? '', currentStream?.sourceName ?? '',
            );
          },
        ),
      ),
    );
    return true;
  }

  Future<void> _resumeEpisode(BuildContext context, Map<String, dynamic> item) async {
    final playerController = locator<PlayerController>();
    final animeId = item['animeId'].toString();
    final title = item['animeTitle']?.toString() ?? 'Unknown';
    final epNum = item['episodeNumber'] as int? ?? 1;
    final poster = item['posterUrl']?.toString() ?? '';
    final episodeId = item['episodeId']?.toString() ?? '$title-ep-$epNum';
    final savedPosition = Duration(milliseconds: int.tryParse(item['positionMs'].toString()) ?? 0);

    bool isCancelled = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF14141B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(width: 16),
              Text("Preparing TV Stream...", style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
        ),
      ),
    ).then((_) => isCancelled = true);

    await playerController.fetchStreamsForEpisode(
      episode: Episode(id: episodeId, number: epNum, title: 'Episode $epNum', providerId: 'anikoto', anilistId: int.tryParse(animeId) ?? 0),
      animeId: animeId, animeTitle: title, posterUrl: poster, totalEpisodes: null,
    );

    if (!context.mounted || isCancelled) return;
    Navigator.pop(context);

    if (playerController.streamLinks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(playerController.errorMessage ?? "No active streams found.")));
      return;
    }

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
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (_) => TvPlayerScreen(
                  title: '$title - Episode $epNum', 
                  quality: stream.quality, 
                  streamUrl: stream.url,
                  playerController: playerController, 
                  animeId: animeId, 
                  episodeId: episodeId,
                  episodeNumber: epNum, 
                  posterUrl: poster, 
                  startPosition: savedPosition,
                  onNextEpisode: () {
                    final currentStream = playerController.selectedStream;
                    return _handleAutoPlayNext(
                      context, epNum + 1, title, animeId, poster,
                      currentStream?.quality ?? '', currentStream?.sourceName ?? '',
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
    return ValueListenableBuilder(
      valueListenable: Hive.box<String>(HiveBoxes.continueWatching).listenable(),
      builder: (context, box, child) {
        final historyItems = _historyService.getAllHistory();
        if (historyItems.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Continue Watching", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => _historyService.clearAllHistory(),
                  child: const Text("Clear All", style: TextStyle(color: Colors.white54, fontSize: 14)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120, 
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: historyItems.length,
                clipBehavior: Clip.none, 
                itemBuilder: (context, index) {
                  return _TvContinueWatchingCard(item: historyItems[index], onTap: () => _resumeEpisode(context, historyItems[index]));
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }
}

class _TvContinueWatchingCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  const _TvContinueWatchingCard({required this.item, required this.onTap});

  @override
  State<_TvContinueWatchingCard> createState() => _TvContinueWatchingCardState();
}

class _TvContinueWatchingCardState extends State<_TvContinueWatchingCard> {
  bool _isFocused = false;

  void _handleFocusChange(bool focused) {
    setState(() => _isFocused = focused);
    // 🚀 Auto-scroll horizontally to keep focused item centered
    if (focused && mounted) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.item['animeTitle'] ?? 'Unknown';
    final epNum = widget.item['episodeNumber'] ?? '?';
    final poster = widget.item['posterUrl'] ?? '';
    final int pos = widget.item['positionMs'] ?? 0;
    final int dur = widget.item['durationMs'] ?? 1;
    final double progress = (pos / dur).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(right: 20.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onFocusChange: _handleFocusChange,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutQuart,
            width: 210,
            transform: Matrix4.diagonal3Values(_isFocused ? 1.06 : 1.0, _isFocused ? 1.06 : 1.0, 1.0),
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _isFocused ? Colors.white : Colors.transparent, width: _isFocused ? 3 : 0),
              boxShadow: _isFocused ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.8), blurRadius: 20, spreadRadius: 4)] : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    poster, 
                    fit: BoxFit.cover, 
                    cacheWidth: 400, 
                    errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[900]),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.9)],
                      ),
                    ),
                  ),
                  Center(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _isFocused ? 1.0 : 0.0, 
                      child: const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 48),
                    ),
                  ),
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                              Text("Episode $epNum", style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        LinearProgressIndicator(value: progress, minHeight: 4, backgroundColor: Colors.white12, valueColor: const AlwaysStoppedAnimation<Color>(Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 3. TV ANIME ROW SECTION
// ============================================================================
class _TvAnimeSection extends StatelessWidget {
  final String title;
  final List<Anime> animeList;

  const _TvAnimeSection({required this.title, required this.animeList});

  @override
  Widget build(BuildContext context) {
    if (animeList.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: animeList.length,
            clipBehavior: Clip.none,
            itemBuilder: (context, index) {
              return _TvAnimeCard(anime: animeList[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _TvAnimeCard extends StatefulWidget {
  final Anime anime;
  const _TvAnimeCard({required this.anime});

  @override
  State<_TvAnimeCard> createState() => _TvAnimeCardState();
}

class _TvAnimeCardState extends State<_TvAnimeCard> {
  bool _isFocused = false;

  void _handleFocusChange(bool focused) {
    setState(() => _isFocused = focused);
    // 🚀 Auto-scroll horizontally to keep focused poster centered
    if (focused && mounted) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = widget.anime.rating != null ? "★ ${widget.anime.rating!.toStringAsFixed(1)}" : null;

    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => TvAnimeDetailsScreen(anime: widget.anime)));
          },
          onFocusChange: _handleFocusChange,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutQuart,
            width: 130,
            transform: Matrix4.diagonal3Values(_isFocused ? 1.08 : 1.0, _isFocused ? 1.08 : 1.0, 1.0),
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _isFocused ? Colors.white : Colors.transparent, width: _isFocused ? 3 : 0),
              boxShadow: _isFocused ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.8), blurRadius: 20, spreadRadius: 4)] : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.anime.coverImage ?? '',
                    fit: BoxFit.cover, 
                    cacheWidth: 260,
                    errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[900]),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.9)],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                  
                  if (score != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: Text(score, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),

                  Positioned(
                    bottom: 10, left: 10, right: 10,
                    child: Text(
                      widget.anime.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _isFocused ? Colors.white : Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}