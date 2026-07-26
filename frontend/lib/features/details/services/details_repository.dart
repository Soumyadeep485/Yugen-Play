import '../../../core/network/anilist_client.dart';
import '../models/anime_details.dart';
import 'details_queries.dart';

class DetailsRepository {
  final AniListClient _client;

  DetailsRepository(this._client);

  Future<AnimeDetails> fetchAnimeDetails(int id) async {
    try {
      final data = await _client.query(
        queryString: DetailsQueries.animeDetails,
        variables: {'id': id},
      );

      if (data != null && data['Media'] != null) {
        return AnimeDetails.fromAniList({'data': data});
      } else {
        throw Exception('Failed to fetch details from AniList.');
      }
    } catch (e) {
      throw Exception('GraphQL Error: $e');
    }
  }
}