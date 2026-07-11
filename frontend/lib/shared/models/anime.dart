class Anime {
  final int id;
  final String title;
  final String? nativeTitle;
  final String imageUrl;
  final String? bannerImage;
  final List<String> genres;
  final double rating;
  final String type;
  final int? episodes;
  final int? seasonYear;

  const Anime({
    required this.id,
    required this.title,
    required this.nativeTitle,
    required this.imageUrl,
    required this.bannerImage,
    required this.genres,
    required this.rating,
    required this.type,
    required this.episodes,
    required this.seasonYear,
  });

  factory Anime.fromGraphQL(Map<String, dynamic> json) {
    return Anime(
      id: (json["id"] as num).toInt(),

      title: json["title"]?["english"] ?? json["title"]?["romaji"] ?? "Unknown",

      nativeTitle: json["title"]?["native"],

      imageUrl: json["coverImage"]?["extraLarge"] ?? "",

      bannerImage: json["bannerImage"],

      genres:
          (json["genres"] as List?)?.map((e) => e.toString()).toList() ?? [],

      rating: ((json["averageScore"] ?? 0) as num).toDouble() / 10,

      type: json["format"] ?? "Unknown",

      episodes: (json["episodes"] as num?)?.toInt(),

      seasonYear: (json["seasonYear"] as num?)?.toInt(),
    );
  }
}
