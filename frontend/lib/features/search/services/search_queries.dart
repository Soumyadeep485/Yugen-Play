class SearchQueries {
  SearchQueries._();

  // Updated to support the full filter suite (genre, format, sort, status)
  static const String searchAnime = r'''
    query ($search: String, $genre: String, $format: MediaFormat, $sort: [MediaSort], $status: MediaStatus) {
      Page(page: 1, perPage: 24) {
        media(search: $search, type: ANIME, genre: $genre, format: $format, sort: $sort, status: $status) {
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
          format 
          episodes 
          seasonYear
        }
      }
    }
  ''';
}