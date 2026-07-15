import 'package:dio/dio.dart';
import 'package:frontend/shared/models/anime_details.dart';

class DetailsRepository {
  final Dio _dio =
      Dio(); // You can inject your unified service_locator Dio here

  Future<AnimeDetails> fetchAnimeDetails(int id) async {
    const String query = '''
      query (\$id: Int) {
        Media (id: \$id, type: ANIME) {
          id
          title {
            romaji
            english
          }
          coverImage {
            extraLarge
            large
          }
          meanScore
          status
          format
          episodes
          duration
          source
          season
          seasonYear
          description
          genres
        }
      }
    ''';

    try {
      final response = await _dio.post(
        'https://graphql.anilist.co',
        data: {
          'query': query,
          'variables': {'id': id},
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return AnimeDetails.fromAniList(response.data);
      } else {
        throw Exception('Failed to fetch details from AniList.');
      }
    } catch (e) {
      throw Exception('GraphQL Error: $e');
    }
  }
}
