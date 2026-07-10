import 'package:flutter/material.dart';

import '../../shared/models/home_data.dart';
import '../../shared/repositories/anime_repository.dart';
import '../../shared/services/api_service.dart';

import 'widgets/anime_section.dart';
import 'widgets/custom_bottom_nav.dart';
import 'widgets/hero_banner.dart';
import 'widgets/home_app_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AnimeRepository repository = AnimeRepository(ApiService());

  late final Future<HomeData> homeDataFuture;

  @override
  void initState() {
    super.initState();
    homeDataFuture = repository.getHomeData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),

      body: SafeArea(
        child: FutureBuilder<HomeData>(
          future: homeDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        color: Colors.white54,
                        size: 48,
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'Unable to load Yugen Play',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Check your connection and try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white60, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                child: Text(
                  'No anime data available',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            final home = snapshot.data!;

            return SingleChildScrollView(
              child: Column(
                children: [
                  const HomeAppBar(),

                  const SizedBox(height: 20),

                  HeroBanner(anime: home.featuredAnime),

                  const SizedBox(height: 24),

                  if (home.mostPopularAnime.isNotEmpty)
                    AnimeSection(
                      title: '🔥 Most Popular',
                      animeList: home.mostPopularAnime,
                    ),

                  if (home.mostPopularAnime.isNotEmpty)
                    const SizedBox(height: 24),

                  if (home.topRatedAnime.isNotEmpty)
                    AnimeSection(
                      title: '⭐ Top Rated',
                      animeList: home.topRatedAnime,
                    ),

                  if (home.topRatedAnime.isNotEmpty) const SizedBox(height: 24),

                  if (home.currentlyAiringAnime.isNotEmpty)
                    AnimeSection(
                      title: '📺 Currently Airing',
                      animeList: home.currentlyAiringAnime,
                    ),

                  if (home.currentlyAiringAnime.isNotEmpty)
                    const SizedBox(height: 24),

                  if (home.upcomingAnime.isNotEmpty)
                    AnimeSection(
                      title: '🔮 Upcoming',
                      animeList: home.upcomingAnime,
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),

      bottomNavigationBar: const CustomBottomNav(),
    );
  }
}
