class Anime {
  final String id;
  final int? idMal;
  final String title;
  final String? coverImage;
  final String? bannerImage;
  final double? rating;
  final int? episodes;
  final String? status;
  final String? description;
  final List<String>? synonyms;
  // 🚀 Added missing AniList fields
  final List<String>? genres;
  final String? format; 

  const Anime({
    required this.id,
    this.idMal,
    required this.title,
    this.coverImage,
    this.bannerImage,
    this.rating,
    this.episodes,
    this.status,
    this.description,
    this.synonyms,
    this.genres,
    this.format,
  });

  factory Anime.fromJson(Map<String, dynamic> json) {
    final titleMap = json['title'] as Map<String, dynamic>?;
    final titleString =
        titleMap?['userPreferred'] ??
        titleMap?['english'] ??
        titleMap?['romaji'] ??
        json['title']?.toString() ??
        'Unknown Title';

    final coverMap = json['coverImage'] as Map<String, dynamic>?;

    List<String>? parsedSynonyms;
    if (json['synonyms'] != null && json['synonyms'] is List) {
      parsedSynonyms = (json['synonyms'] as List).map((e) => e.toString()).toList();
    }

    List<String>? parsedGenres;
    if (json['genres'] != null && json['genres'] is List) {
      parsedGenres = (json['genres'] as List).map((e) => e.toString()).toList();
    }

    return Anime(
      id: json['id']?.toString() ?? '',
      idMal: json['idMal'] as int?,
      title: titleString,
      coverImage:
          coverMap?['large'] ??
          coverMap?['medium'] ??
          json['coverImage']?.toString(),
      bannerImage: json['bannerImage']?.toString(),
      rating: (json['averageScore'] as num?)?.toDouble(),
      episodes: json['episodes'] as int?,
      status: json['status']?.toString(),
      description: json['description']?.toString(),
      synonyms: parsedSynonyms,
      genres: parsedGenres,
      format: json['format']?.toString(),
    );
  }
}