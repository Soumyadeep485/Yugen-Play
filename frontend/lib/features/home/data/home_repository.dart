import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../core/network/graphql_client.dart';
import '../../../shared/models/anime.dart';
import '../../../shared/models/home_data.dart';
import 'home_queries.dart';

class HomeRepository {
  List<Anime> _parse(dynamic page) {
    final media = (page['media'] as List<dynamic>? ?? []);

    return media
        .whereType<Map<String, dynamic>>()
        .map(Anime.fromGraphQL)
        .toList();
  }

  Future<HomeData> getHomeData() async {
    final result = await GraphQLService.client.query(
      QueryOptions(
        document: gql(HomeQueries.homeFeed),
        fetchPolicy: FetchPolicy.noCache,
        cacheRereadPolicy: CacheRereadPolicy.ignoreAll,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final data = result.data!;

    final trending = _parse(data["trending"]);
    final popular = _parse(data["popular"]);
    final airing = _parse(data["airing"]);
    final upcoming = _parse(data["upcoming"]);

    if (trending.isEmpty && popular.isEmpty) {
      throw Exception("AniList returned no Home data.");
    }

    return HomeData(
      featuredAnime: trending.isNotEmpty ? trending.first : popular.first,
      mostPopularAnime: popular,
      topRatedAnime: trending,
      currentlyAiringAnime: airing,
      upcomingAnime: upcoming,
    );
  }
}
