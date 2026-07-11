class DetailsQueries {
  DetailsQueries._();

  static const String animeDetails = r'''
query AnimeDetails($id: Int) {

  Media(id: $id, type: ANIME) {

    id

    title {
      romaji
      english
      native
    }

    coverImage {
      extraLarge
    }

    bannerImage

    description(asHtml:false)

    genres

    averageScore

    episodes

    duration

    format

    status

    seasonYear

    studios(isMain:true) {
      nodes {
        name
      }
    }
  }
}
''';
}
