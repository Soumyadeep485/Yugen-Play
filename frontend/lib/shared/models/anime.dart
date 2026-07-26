class Anime {
  final String id;
  final String title;
  final String? coverImage;
  final String? bannerImage;
  final double? rating;
  final int? episodes;
  final String? status;
  final String? description;

  const Anime({
    required this.id,
    required this.title,
    this.coverImage,
    this.bannerImage,
    this.rating,
    this.episodes,
    this.status,
    this.description,
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

    return Anime(
      id: json['id']?.toString() ?? '',
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
    );
  }
}
