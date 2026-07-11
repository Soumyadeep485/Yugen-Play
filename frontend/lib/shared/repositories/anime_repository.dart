import 'dart:convert';

import '../models/anime.dart';
import '../models/home_data.dart';
import '../services/api_service.dart';
import '../models/anime_details.dart';

class AnimeRepository {
  final ApiService apiService;

  AnimeRepository(this.apiService);

  Future<HomeData> getHomeData() async {
    // Critical request:
    // The hero banner and Top Rated section depend on this.
    final topRatedResponse = await apiService
        .get('/top/anime')
        .timeout(const Duration(seconds: 10));

    if (topRatedResponse.statusCode != 200) {
      throw Exception(
        'Failed to load Top Rated anime: '
        'HTTP ${topRatedResponse.statusCode}',
      );
    }

    final topRated = _parseAnimeList(topRatedResponse.body);

    if (topRated.isEmpty) {
      throw Exception('No Top Rated anime data received');
    }

    // Avoid sending requests to Jikan in one simultaneous burst.
    await Future.delayed(const Duration(milliseconds: 500));

    final mostPopular = await _fetchOptionalSection(
      '/anime?order_by=popularity&sort=asc&limit=15',
    );

    await Future.delayed(const Duration(milliseconds: 500));

    final currentlyAiring = await _fetchOptionalSection(
      '/top/anime?filter=airing',
    );

    await Future.delayed(const Duration(milliseconds: 500));

    final upcoming = await _fetchOptionalSection('/top/anime?filter=upcoming');

    return HomeData(
      featuredAnime: topRated.first,
      mostPopularAnime: mostPopular.take(15).toList(),
      topRatedAnime: topRated.take(15).toList(),
      currentlyAiringAnime: currentlyAiring.take(15).toList(),
      upcomingAnime: upcoming.take(15).toList(),
    );
  }

  Future<AnimeDetails> getAnimeDetails(int animeId) async {
    if (animeId <= 0) {
      throw ArgumentError('Invalid anime ID: $animeId');
    }

    final response = await apiService
        .get('/anime/$animeId/full')
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load anime details: '
        'HTTP ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid anime details response');
    }

    final data = decoded['data'];

    if (data is! Map<String, dynamic>) {
      throw const FormatException('Anime details data is missing or invalid');
    }

    return AnimeDetails.fromJson(data);
  }

  Future<List<Anime>> searchAnime(String query) async {
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      return [];
    }

    final response = await apiService
        .get('/anime?q=${Uri.encodeQueryComponent(trimmedQuery)}&limit=20')
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Failed to search anime: HTTP ${response.statusCode}');
    }

    return _parseAnimeList(response.body);
  }

  Future<List<Anime>> _fetchOptionalSection(String endpoint) async {
    try {
      final response = await apiService
          .get(endpoint)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return _parseAnimeList(response.body);
      }

      if (response.statusCode == 429) {
        await Future.delayed(const Duration(seconds: 2));

        final retryResponse = await apiService
            .get(endpoint)
            .timeout(const Duration(seconds: 10));

        if (retryResponse.statusCode == 200) {
          return _parseAnimeList(retryResponse.body);
        }
      }

      return [];
    } catch (_) {
      return [];
    }
  }

  List<Anime> _parseAnimeList(String responseBody) {
    final decoded = jsonDecode(responseBody);

    final List<dynamic> data = decoded['data'] ?? [];

    return data.whereType<Map<String, dynamic>>().map(Anime.fromJson).toList();
  }
}
