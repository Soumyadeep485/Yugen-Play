import 'package:graphql_flutter/graphql_flutter.dart';

class GraphQLService {
  GraphQLService._();

  static final HttpLink _httpLink = HttpLink('https://graphql.anilist.co');

  static final GraphQLClient client = GraphQLClient(
    link: _httpLink,
    cache: GraphQLCache(store: InMemoryStore()),
  );
}
