class EpisodeMetadata {
  final int number;
  final String title;
  final String description;
  final String thumbnail;

  EpisodeMetadata({
    required this.number,
    required this.title,
    required this.description,
    required this.thumbnail,
  });

  factory EpisodeMetadata.fromJson(
    Map<String, dynamic> json,
    int defaultNumber,
    String defaultThumbnail,
  ) {
    final titleMap = json['title'] as Map<String, dynamic>? ?? {};

    // Fallback chain for titles: English -> Romaji -> Japanese -> Default
    final title =
        titleMap['en'] ??
        titleMap['x-jat'] ??
        titleMap['ja'] ??
        'Episode $defaultNumber';

    return EpisodeMetadata(
      number: defaultNumber,
      title: title,
      description:
          json['overview'] ??
          'Tap to fetch extension streams and start playing.',
      thumbnail: json['image'] ?? defaultThumbnail,
    );
  }
}
