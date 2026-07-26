import '../../../core/network/anilist_client.dart';
import '../../../shared/models/anime.dart';
import '../models/home_data.dart';

class HomeRepository {
  final AniListClient _client;

  HomeRepository(this._client);

  static const String _homeDataQuery = r'''
    query {
      Page(page: 1, perPage: 20) {
        media(type: ANIME, sort: TRENDING_DESC) {
          id
          title {
            userPreferred
            english
            romaji
          }
          coverImage {
            large
            medium
          }
          bannerImage
          averageScore
          episodes
          status
          description
        }
      }
    }
  ''';

  Future<HomeData> fetchHomeData() async {
    try {
      final data = await _client.query(queryString: _homeDataQuery);
      if (data != null &&
          data['Page'] != null &&
          data['Page']['media'] != null) {
        final mediaList = (data['Page']['media'] as List)
            .map((e) => Anime.fromJson(e as Map<String, dynamic>))
            .toList();

        return HomeData(
          trending: mediaList,
          popular: mediaList,
          topRated: mediaList,
          seasonal: mediaList,
        );
      }
      return HomeData.empty();
    } catch (e) {
      return HomeData.empty();
    }
  }

  Future<HomeData> getHomeData() => fetchHomeData();
}
