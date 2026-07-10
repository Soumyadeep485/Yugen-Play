class Anime {
  final int id;
  final String title;
  final String imageUrl;
  final List<String> genres;
  final double rating;
  final String type;
  final int? episodes;

  const Anime({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.genres,
    required this.rating,
    required this.type,
    required this.episodes,
  });

  factory Anime.fromJson(Map<String, dynamic> json) {
    return Anime(
      id: (json["mal_id"] as num?)?.toInt() ?? 0,
      title: json["title_english"] ?? json["title"] ?? "Unknown",
      imageUrl:
          json["images"]?["jpg"]?["large_image_url"] ??
          json["images"]?["jpg"]?["image_url"] ??
          "",
      genres: (json["genres"] as List? ?? [])
          .map((genre) => genre["name"].toString())
          .take(3)
          .toList(),
      rating: (json["score"] as num?)?.toDouble() ?? 0.0,
      type: json["type"]?.toString() ?? "Unknown",
      episodes: (json["episodes"] as num?)?.toInt(),
    );
  }
}
