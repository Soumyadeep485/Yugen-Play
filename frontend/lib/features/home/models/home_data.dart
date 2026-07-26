import '../../../shared/models/anime.dart';

class HomeData {
  final List<Anime> trending;
  final List<Anime> popular;
  final List<Anime> topRated;
  final List<Anime> seasonal;

  const HomeData({
    required this.trending,
    required this.popular,
    required this.topRated,
    required this.seasonal,
  });

  factory HomeData.empty() {
    return const HomeData(
      trending: [],
      popular: [],
      topRated: [],
      seasonal: [],
    );
  }
}
