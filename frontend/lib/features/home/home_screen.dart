import 'package:flutter/material.dart';
import 'data/home_repository.dart';
import '../../shared/models/home_data.dart';
import 'widgets/anime_section.dart';
import 'widgets/home_app_bar.dart';
import 'widgets/floating_pill_nav.dart';
import 'widgets/fast_filters_matrix.dart';
import '../settings/widgets/profile_action_sheet.dart';
import 'widgets/hero_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeRepository repository = HomeRepository();
  late final Future<HomeData> homeDataFuture;

  MediaContext _currentContext = MediaContext.anime;

  @override
  void initState() {
    super.initState();
    homeDataFuture = repository.getHomeData();
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (context) => const ProfileActionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      // Removed SafeArea here so the glass App Bar can blur into the status bar area
      body: Stack(
        children: [
          // 1. The Scrollable Content
          FutureBuilder<HomeData>(
            future: homeDataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE50914)),
                );
              }
              if (snapshot.hasError) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 120, left: 20, right: 20),
                  child: SelectableText(
                    snapshot.error.toString(),
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: Text(
                    'No media data available',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              final home = snapshot.data!;

              return SingleChildScrollView(
                // Added top padding for the pinned App Bar and bottom padding for the Pill Nav
                padding: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top + 80,
                  bottom: 100,
                ),
                child: Column(
                  children: [
                    if (home.mostPopularAnime.isNotEmpty)
                      HeroBanner(anime: home.mostPopularAnime.first),

                    const SizedBox(height: 16),
                    const FastFiltersMatrix(),
                    const SizedBox(height: 24),

                    if (_currentContext == MediaContext.anime) ...[
                      if (home.mostPopularAnime.isNotEmpty)
                        AnimeSection(
                          title: 'Most Popular',
                          animeList: home.mostPopularAnime,
                        ),
                      if (home.mostPopularAnime.isNotEmpty)
                        const SizedBox(height: 24),
                      if (home.topRatedAnime.isNotEmpty)
                        AnimeSection(
                          title: 'Top Rated',
                          animeList: home.topRatedAnime,
                        ),
                    ] else ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            "No Manga collections available in local registry.",
                            style: TextStyle(color: Colors.white38),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),

          // 2. The Glassy Pinned App Bar (Top)
          const Positioned(top: 0, left: 0, right: 0, child: HomeAppBar()),

          // 3. The Floating Pill Nav (Bottom)
          FloatingPillNav(
            currentContext: _currentContext,
            onContextChanged: (newContext) {
              setState(() {
                _currentContext = newContext;
              });
            },
            onProfilePressed: _showProfileMenu,
          ),
        ],
      ),
    );
  }
}
