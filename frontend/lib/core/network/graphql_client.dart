import 'package:graphql_flutter/graphql_flutter.dart';

class GraphQLService {
  GraphQLService._();

  // Injecting standard headers to bypass basic Cloudflare tarpitting
  static final HttpLink _httpLink = HttpLink(
    'https://graphql.anilist.co',
    defaultHeaders: {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 13; SM-S911B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  );

  static final GraphQLClient client = GraphQLClient(
    link: _httpLink,
    cache: GraphQLCache(store: InMemoryStore()),
  );
}
