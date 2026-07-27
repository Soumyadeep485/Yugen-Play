import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../shared/models/anime.dart';
import '../../../details/presentation/screens/anime_details_screen.dart';
import '../../../history/services/watch_history_service.dart';
import '../../../search/controllers/search_provider.dart';
import '../../../search/presentation/screens/search_screen.dart';
import '../../controllers/home_provider.dart';
import '../widgets/anime_section.dart';
import '../widgets/hero_banner.dart';
import '../widgets/home_app_bar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _ambientImageUrl;

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
                      // 🛑 Lowered blur slightly so the rendering engine doesn't choke
                      imageFilter: ImageFilter.blur(sigmaX: 45, sigmaY: 45), 
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<String>('watch_history').listenable(),
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
                    onTap: () {
                      final reconstructedAnime = Anime(
                        id: animeId,
                        title: title,
                        coverImage: poster,
                        bannerImage: poster, 
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AnimeDetailsScreen(anime: reconstructedAnime),
                        ),
                      );
                    },
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