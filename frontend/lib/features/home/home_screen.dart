import 'package:flutter/material.dart';
import 'data/home_repository.dart';
import '../../shared/models/home_data.dart';

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
  final HomeRepository repository = HomeRepository();

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
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: SelectableText(
                  snapshot.error.toString(),
                  style: const TextStyle(color: Colors.red, fontSize: 14),
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
