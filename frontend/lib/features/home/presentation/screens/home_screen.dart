import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../details/presentation/screens/anime_details_screen.dart';
import '../../../search/controllers/search_provider.dart';
import '../../../search/presentation/screens/search_screen.dart';
import '../../controllers/home_provider.dart';
import '../widgets/anime_section.dart';
import '../widgets/hero_banner.dart';
import '../widgets/home_app_bar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: HomeAppBar(
        username: "Otaku Guest",
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
          // 1. AMBIENT MESH GRADIENT ORBS
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            top: 250,
            right: -100,
            child: Container(
              width: 250,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -150,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.teal.withValues(alpha: 0.10),
              ),
            ),
          ),

          // 2. THE FROSTED GLASS LAYER
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),

          // 3. FOREGROUND CONTENT
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
                        ),

                        const SizedBox(height: 24),

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
