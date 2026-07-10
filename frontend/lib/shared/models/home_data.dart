import 'anime.dart';

class HomeData {
  final Anime featuredAnime;
  final List<Anime> mostPopularAnime;
  final List<Anime> topRatedAnime;
  final List<Anime> currentlyAiringAnime;
  final List<Anime> upcomingAnime;

  const HomeData({
    required this.featuredAnime,
    required this.mostPopularAnime,
    required this.topRatedAnime,
    required this.currentlyAiringAnime,
    required this.upcomingAnime,
  });
}
