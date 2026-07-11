class SearchQueries {
  SearchQueries._();

  static const String searchAnime = r'''
query SearchAnime($search: String) {
  Page(page: 1, perPage: 20) {
    media(
      search: $search
      type: ANIME
      sort: SEARCH_MATCH
    ) {

      id

      title {
        romaji
        english
      }

      coverImage {
        extraLarge
      }

      genres

      averageScore

      episodes

      format
    }
  }
}
''';
}
