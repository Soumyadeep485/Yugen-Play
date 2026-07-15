class AnimeDetails {
  final int id;
  final String title;
  final String imageUrl;
  final double meanScore;
  final String status;
  final String format;
  final int? episodes;
  final int? duration;
  final String source;
  final String season;
  final int? seasonYear;
  final String description;
  final List<String> genres;

  const AnimeDetails({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.meanScore,
    required this.status,
    required this.format,
    this.episodes,
    this.duration,
    required this.source,
    required this.season,
    this.seasonYear,
    required this.description,
    required this.genres,
  });

  factory AnimeDetails.fromAniList(Map<String, dynamic> json) {
    final media = json['data']['Media'] as Map<String, dynamic>;
    final titleNode = media['title'] as Map<String, dynamic>;

    // AniList returns descriptions with HTML tags (like <br> or <i>). We need to strip them.
    final rawDesc = media['description'] as String? ?? 'No synopsis available.';
    final cleanDesc = rawDesc.replaceAll(RegExp(r'<[^>]*>'), '').trim();

    return AnimeDetails(
      id: media['id'] as int,
      title: titleNode['romaji'] ?? titleNode['english'] ?? 'Unknown Title',
      imageUrl:
          media['coverImage']['extraLarge'] ??
          media['coverImage']['large'] ??
          '',
      meanScore: (media['meanScore'] as int? ?? 0) / 10.0, // Convert 85 to 8.5
      status: media['status']?.toString() ?? 'UNKNOWN',
      format: media['format']?.toString() ?? 'UNKNOWN',
      episodes: media['episodes'] as int?,
      duration: media['duration'] as int?,
      source: media['source']?.toString().replaceAll('_', ' ') ?? 'UNKNOWN',
      season: media['season']?.toString() ?? 'UNKNOWN',
      seasonYear: media['seasonYear'] as int?,
      description: cleanDesc,
      genres: List<String>.from(media['genres'] ?? []),
    );
  }
}
