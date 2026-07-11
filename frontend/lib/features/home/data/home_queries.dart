class HomeQueries {
  HomeQueries._();

  static const String homeFeed = r'''
query HomeFeed {

  trending: Page(page: 1, perPage: 15) {
    media(
      type: ANIME
      sort: TRENDING_DESC
    ) {
      ...AnimeCard
    }
  }

  popular: Page(page: 1, perPage: 15) {
    media(
      type: ANIME
      sort: POPULARITY_DESC
    ) {
      ...AnimeCard
    }
  }

  airing: Page(page: 1, perPage: 15) {
    media(
      type: ANIME
      status: RELEASING
      sort: POPULARITY_DESC
    ) {
      ...AnimeCard
    }
  }

  upcoming: Page(page: 1, perPage: 15) {
    media(
      type: ANIME
      status: NOT_YET_RELEASED
      sort: POPULARITY_DESC
    ) {
      ...AnimeCard
    }
  }
}

fragment AnimeCard on Media {

  id

  title {
    english
    romaji
    native
  }

  coverImage {
    extraLarge
  }

  bannerImage

  genres

  averageScore

  episodes

  format

  seasonYear
}
''';
}
