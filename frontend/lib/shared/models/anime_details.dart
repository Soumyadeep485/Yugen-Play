class AnimeDetails {
  final int id;
  final String title;
  final String? japaneseTitle;
  final String imageUrl;
  final String? trailerUrl;
  final String synopsis;
  final List<String> genres;
  final double rating;
  final String type;
  final int? episodes;
  final String status;
  final String duration;
  final int? year;
  final List<String> studios;

  const AnimeDetails({
    required this.id,
    required this.title,
    required this.japaneseTitle,
    required this.imageUrl,
    required this.trailerUrl,
    required this.synopsis,
    required this.genres,
    required this.rating,
    required this.type,
    required this.episodes,
    required this.status,
    required this.duration,
    required this.year,
    required this.studios,
  });

  factory AnimeDetails.fromJson(Map<String, dynamic> json) {
    return AnimeDetails(
      id: (json["mal_id"] as num?)?.toInt() ?? 0,

      title:
          json["title_english"]?.toString() ??
          json["title"]?.toString() ??
          "Unknown",

      japaneseTitle: json["title_japanese"]?.toString(),

      imageUrl:
          json["images"]?["jpg"]?["large_image_url"]?.toString() ??
          json["images"]?["jpg"]?["image_url"]?.toString() ??
          "",

      trailerUrl: json["trailer"]?["url"]?.toString(),

      synopsis: json["synopsis"]?.toString() ?? "No synopsis available.",

      genres: (json["genres"] as List? ?? [])
          .map((genre) => genre["name"]?.toString() ?? "Unknown")
          .toList(),

      rating: (json["score"] as num?)?.toDouble() ?? 0.0,

      type: json["type"]?.toString() ?? "Unknown",

      episodes: (json["episodes"] as num?)?.toInt(),

      status: json["status"]?.toString() ?? "Unknown",

      duration: json["duration"]?.toString() ?? "Unknown",

      year: (json["year"] as num?)?.toInt(),

      studios: (json["studios"] as List? ?? [])
          .map((studio) => studio["name"]?.toString() ?? "Unknown")
          .toList(),
    );
  }
}
