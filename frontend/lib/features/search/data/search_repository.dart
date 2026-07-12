import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../core/network/graphql_client.dart';
import 'search_queries.dart';
import '../../../shared/models/anime.dart';

class SearchRepository {
  Future<List<Anime>> searchAnime(String query) async {
    final trimmed = query.trim();

    if (trimmed.length < 2) {
      return [];
    }

    final result = await GraphQLService.client.query(
      QueryOptions(
        document: gql(SearchQueries.searchAnime),
        variables: {'search': trimmed},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final page = result.data?['Page'];

    if (page == null) {
      return [];
    }

    final List<dynamic> media = page['media'] ?? [];

    return media
        .whereType<Map<String, dynamic>>()
        .map(Anime.fromGraphQL)
        .toList();
  }
}
