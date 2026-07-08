import 'package:flutter/material.dart';
import 'widgets/home_app_bar.dart';
import 'widgets/hero_banner.dart';
import 'widgets/anime_section.dart';
import 'widgets/custom_bottom_nav.dart';
import '../../shared/models/anime.dart';
import '../../shared/repositories/anime_repository.dart';
import '../../shared/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final repository = AnimeRepository(ApiService());

  late final Future<Anime> featuredAnimeFuture;
  late final Future<List<Anime>> topAnimeFuture;

  @override
  void initState() {
    super.initState();
    featuredAnimeFuture = repository.getFeaturedAnime();
    topAnimeFuture = repository.getTopAnime();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const HomeAppBar(),

              const SizedBox(height: 20),

              FutureBuilder<Anime>(
                future: featuredAnimeFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(
                      height: 260,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  return HeroBanner(anime: snapshot.data!);
                },
              ),

              const SizedBox(height: 24),

              FutureBuilder<List<Anime>>(
                future: topAnimeFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        snapshot.error.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        "No Anime Found",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  return AnimeSection(
                    title: "🔥 Trending Now",
                    animeList: snapshot.data!,
                  );
                },
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: const CustomBottomNav(),
    );
  }
}
