import 'dart:ui';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/storage/hive_boxes.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../../../core/colors/app_colors.dart';
import '../widgets/glassy_update_dialog.dart';
import '../../../details/presentation/screens/anime_details_screen.dart';
import '../../../history/services/watch_history_service.dart';
import '../../../search/controllers/search_provider.dart';
import '../../../search/presentation/screens/search_screen.dart';
import '../../controllers/home_provider.dart';
import '../widgets/anime_section.dart';
import '../widgets/hero_banner.dart';
import '../widgets/home_app_bar.dart';
import '../../../../service_locator.dart';
import '../../../player/controllers/player_controller.dart';
import '../../../player/models/episode.dart';
import '../../../player/models/stream_link.dart';
import '../../../player/presentation/screens/glassy_player_screen.dart';
import '../../../player/presentation/widgets/stream_quality_bottom_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _ambientImageUrl;

@override
void initState() {
  super.initState();
  // FIX: Wait for the initial frame to draw BEFORE checking for updates
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      _checkForUpdates();
    }
  });
}
  // Method 1: The API Fetcher
  Future<void> _checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      
      // 1. Sanitize the app's current version just in case
      final currentVersion = packageInfo.version.replaceAll(RegExp(r'[^0-9.]'), '');

      final dio = Dio();
      final response = await dio.get('https://api.github.com/repos/Soumyadeep485/Yugen-Play/releases/latest');

      if (response.statusCode == 200) {
        final data = response.data;
        
        // 2. BULLETPROOF PARSING: Strips all letters, dashes, and spaces.
        // Transforms "v1.2.0-beta" or "Release 1.2.0" into a cleanly parsed "1.2.0"
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

        // 3. Compare the sanitized versions
        if (downloadUrl != null && _isNewerVersion(currentVersion, latestVersion)) {
          if (!mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false, 
            builder: (context) => GlassyUpdateDialog(
              version: latestVersion, // Shows the clean version number in the UI
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

  // Method 2: The Version Comparator (Checks if 1.0.1 is bigger than 1.0.0)
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

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);

    return Scaffold(
      backgroundColor: Colors.black, // True black foundation
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: HomeAppBar(
        onSearchPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SearchScreen(autofocus: true),
            ),
          );
        },
      ),
      body: Stack(
        children: [
          // ==========================================
          // 1. DYNAMIC IMAGE (Pre-Blurred)
          // ==========================================
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 1000),
              child: _ambientImageUrl != null && _ambientImageUrl!.isNotEmpty
                  ? ImageFiltered(
                      key: ValueKey<String>(_ambientImageUrl!),
                      // Lowered blur slightly so the rendering engine doesn't choke
                      imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25), 
                      child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(_ambientImageUrl!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      key: const ValueKey("fallback"), 
                      color: Colors.black,
                    ),
            ),
          ),

          // ==========================================
          // 2. THE SHADOW GRADIENT OVERLAY
          // ==========================================
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    // 🛑 40% black at the top lets the bright colors shine through
                    Colors.black.withValues(alpha: 0.4), 
                    // 🛑 80% black in the middle to start hiding the image behind the lists
                    Colors.black.withValues(alpha: 0.8), 
                    // 🛑 Pure black at the bottom for maximum readability
                    Colors.black, 
                  ],
                  stops: const [0.0, 0.4, 0.8],
                ),
              ),
            ),
          ),

          // ==========================================
          // 3. FOREGROUND CONTENT
          // ==========================================
          SafeArea(
            bottom: false,
            child: homeState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async =>
                        await ref.read(homeProvider.notifier).fetchHomeData(),
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // WELCOME TEXT
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 16.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              RichText(
                                textAlign: TextAlign.center,
                                text: const TextSpan(
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    height: 1.2,
                                  ),
                                  children: [
                                    TextSpan(text: "Hey "),
                                    TextSpan(
                                      text: "Guest",
                                      style: TextStyle(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ", what are we doing\ntoday?",
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // AUTO-SCROLLING BLURRED BANNER
                        HeroBanner(
                          animeList: homeState.data.popular.take(6).toList(),
                          onImageChanged: (newImageUrl) {
                            if (mounted && _ambientImageUrl != newImageUrl) {
                              // 🛑 Wrapped in microtask so it doesn't crash the build phase
                              Future.microtask(() {
                                if (mounted) {
                                  setState(() {
                                    _ambientImageUrl = newImageUrl;
                                  });
                                }
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 24),

                        const ContinueWatchingSection(),

                        // POPULAR ANIMES SECTION
                        AnimeSection(
                          title: "Popular Animes",
                          animeList: homeState.data.popular,
                          onSeeAllPressed: () {
                            ref
                                .read(searchProvider.notifier)
                                .setCategoryMode(
                                  "POPULARITY_DESC",
                                  null,
                                  "Popular Animes",
                                );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SearchScreen(),
                              ),
                            );
                          },
                          onAnimeTap: (anime) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AnimeDetailsScreen(anime: anime),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // NEW RELEASES SECTION
                        AnimeSection(
                          title: "New Releases",
                          animeList: homeState.data.seasonal,
                          onSeeAllPressed: () {
                            ref
                                .read(searchProvider.notifier)
                                .setCategoryMode(
                                  "TRENDING_DESC",
                                  "RELEASING",
                                  "New Releases",
                                );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SearchScreen(),
                              ),
                            );
                          },
                          onAnimeTap: (anime) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AnimeDetailsScreen(anime: anime),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 140),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CONTINUE WATCHING WIDGET (REPAIRED TO BE REACTIVE)
// ============================================================================
class ContinueWatchingSection extends StatefulWidget {
  const ContinueWatchingSection({super.key});

  @override
  State<ContinueWatchingSection> createState() => _ContinueWatchingSectionState();
}

class _ContinueWatchingSectionState extends State<ContinueWatchingSection> {
  final WatchHistoryService _historyService = WatchHistoryService();

  void _clearSingleItem(String animeId) async {
    await _historyService.clearHistory(animeId);
  }

  void _clearAllItems() async {
    await _historyService.clearAllHistory();
  }

  Future<void> _resumeEpisode(BuildContext context, Map<String, dynamic> item) async {
    final playerController = locator<PlayerController>();

    // Safely extract all required database fields
    final animeId = item['animeId'].toString();
    final title = item['animeTitle']?.toString() ?? 'Unknown';
    final epNum = item['episodeNumber'] as int? ?? 1;
    final poster = item['posterUrl']?.toString() ?? '';
    final episodeId = item['episodeId']?.toString() ?? '$title-ep-$epNum';
    final savedPosition = Duration(milliseconds: int.tryParse(item['positionMs'].toString()) ?? 0);
    // 👇 1. Kill switch
    bool isCancelled = false;

    // 1. Show the Glassy "Preparing Stream" Dialog
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
    ).then((_) => isCancelled = true); // 👇 2. Catch swipe-backs

    // 2. Fetch Streams in the background
    await playerController.fetchStreamsForEpisode(
      episode: Episode(
        id: episodeId,
        number: epNum,
        title: 'Episode $epNum',
        providerId: 'anikoto', 
        anilistId: int.tryParse(animeId) ?? 0,
      ),
      animeId: animeId,
      animeTitle: title,
      posterUrl: poster,
      totalEpisodes: null,
    );

    if (!context.mounted) return;
    // 👇 3. Abort if swiped back
    if (isCancelled) return;
    Navigator.pop(context); // Close the loading dialog

    if (playerController.streamLinks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(playerController.errorMessage ?? "No active streams found."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // 3. Show Quality Selector and Launch
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
                builder: (_) => GlassyPlayerScreen(
                  title: '$title - Episode $epNum',
                  quality: stream.quality,
                  streamUrl: stream.url,
                  playerController: playerController,
                  animeId: animeId,
                  episodeId: episodeId,
                  episodeNumber: epNum,
                  posterUrl: poster,
                  startPosition: savedPosition,

                  // 👇 1. Pass the exact state when the user hits Next!
                  onNextEpisode: () {
                    final currentStream = playerController.selectedStream;
                    return _handleAutoPlayNext(
                      context,
                      animeId,
                      title,
                      poster,
                      epNum + 1,
                      currentStream?.quality ?? '',
                      currentStream?.sourceName ?? '',
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
  Future<bool> _handleAutoPlayNext(
    BuildContext context, 
    String animeId, 
    String animeTitle, 
    String posterUrl, 
    int nextEpNum,
    String previousQuality, // 👈 New Parameter
    String previousSource,  // 👈 New Parameter
  ) async {
    final playerController = locator<PlayerController>();

    // We already know exactly what they were watching because we passed it in!
    final prevWasDub = previousQuality.toLowerCase().contains('dub');

    bool isCancelled = false;

    // 1. Show Loading Dialog
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
                child: CircularProgressIndicator(color: Color(0xFF7C3AED), strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text(
                "Loading next episode...",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    ).then((_) => isCancelled = true);

    // 2. FETCH for the next episode
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
      posterUrl: posterUrl,
      totalEpisodes: null, // Continue Watching doesn't strictly need totalEpisodes here
    );

    if (!context.mounted) return false;
    if (isCancelled) return false; 
    
    Navigator.pop(context); // Close dialog

    if (playerController.streamLinks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No more episodes available."), backgroundColor: Colors.redAccent),
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

      // Step B: Lock onto the EXACT server name
      try {
        selectedStream = candidateStreams.firstWhere(
          (link) => link.sourceName.toLowerCase().trim() == previousSource.toLowerCase().trim()
        );
      } catch (_) {
        selectedStream = candidateStreams.first;
      }
    }

    selectedStream ??= playerController.streamLinks.first;
    playerController.selectStream(selectedStream);

    // 4. Launch the player
    Navigator.of(context, rootNavigator: true).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GlassyPlayerScreen(
          title: '$animeTitle - Episode $nextEpNum',
          quality: selectedStream!.quality,
          streamUrl: selectedStream.url,
          playerController: playerController,
          animeId: animeId,
          episodeId: nextEpisodeId,
          episodeNumber: nextEpNum,
          posterUrl: posterUrl,
          startPosition: null,
          // 5. Pass the exact state AGAIN for the next episode in the chain
          onNextEpisode: () {
            final currentStream = playerController.selectedStream;
            return _handleAutoPlayNext(
              context, 
              animeId, 
              animeTitle, 
              posterUrl, 
              nextEpNum + 1,
              currentStream?.quality ?? '',
              currentStream?.sourceName ?? '',
            );
          },
        ),
      ),
    );
    return true;
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Continue Watching",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: _clearAllItems,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text("Clear All", style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: historyItems.length,
                itemBuilder: (context, index) {
                  final item = historyItems[index];
                  final animeId = item['animeId'].toString();
                  final title = item['animeTitle'] ?? 'Unknown';
                  final epNum = item['episodeNumber'] ?? '?';
                  final poster = item['posterUrl'] ?? '';
                  
                  final int pos = item['positionMs'] ?? 0;
                  final int dur = item['durationMs'] ?? 1;
                  final double progress = (pos / dur).clamp(0.0, 1.0);

                  return GestureDetector(
                    onTap: () => _resumeEpisode(context, item),
                    child: Container(
                      width: 240,
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            poster,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey[900],
                              child: const Icon(Icons.broken_image, color: Colors.white24),
                            ),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.8),
                                  Colors.black,
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                          const Center(
                            child: Icon(Icons.play_circle_fill_rounded, color: Colors.white54, size: 48),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _clearSingleItem(animeId),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 2),
                                      Text("Episode $epNum", style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
                                      const SizedBox(height: 8),
                                    ],
                                  ),
                                ),
                                LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.white24,
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                  minHeight: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}