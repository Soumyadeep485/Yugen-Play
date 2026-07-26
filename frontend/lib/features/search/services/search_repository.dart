import '../../../core/network/anilist_client.dart';
import '../../../shared/models/anime.dart';
import 'search_queries.dart';

class SearchRepository {
  final AniListClient _client;

  SearchRepository(this._client);

  Future<List<Anime>> searchAnime(String query, {int page = 1}) async {
    try {
      final data = await _client.query(
        queryString: SearchQueries.searchAnime,
        variables: {'search': query, 'page': page, 'perPage': 20},
      );

      if (data != null &&
          data['Page'] != null &&
          data['Page']['media'] != null) {
        final list = data['Page']['media'] as List;
        return list.map((json) => Anime.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Search failed: $e');
    }
  }
}
