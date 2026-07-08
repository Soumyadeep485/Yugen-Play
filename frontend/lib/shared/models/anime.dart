class Anime {
  final String title;
  final String imageUrl;
  final String genre;
  final double rating;

  const Anime({
    required this.title,
    required this.imageUrl,
    required this.genre,
    required this.rating,
  });

  factory Anime.fromJson(Map<String, dynamic> json) {
    return Anime(
      title: json["title"] ?? "Unknown",
      imageUrl:
          json["images"]["jpg"]["large_image_url"] ??
          json["images"]["jpg"]["image_url"],

      genre: (json["genres"] as List).map((g) => g["name"]).take(2).join(" • "),

      rating: (json["score"] ?? 0).toDouble(),
    );
  }
}
