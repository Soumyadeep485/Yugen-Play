import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../core/network/graphql_client.dart';
import '../../../shared/models/anime_details.dart';

import 'details_queries.dart';

class DetailsRepository {
  Future<AnimeDetails> getAnimeDetails(int id) async {
    final result = await GraphQLService.client.query(
      QueryOptions(
        document: gql(DetailsQueries.animeDetails),
        variables: {"id": id},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    return AnimeDetails.fromGraphQL(result.data!["Media"]);
  }
}
