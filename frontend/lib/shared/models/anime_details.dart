class AnimeDetails {
  final int id;
  final String title;
  final String? japaneseTitle;
  final String imageUrl;
  final String? bannerImage;
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
    required this.bannerImage,
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

  factory AnimeDetails.fromGraphQL(Map<String, dynamic> json) {
    return AnimeDetails(
      id: (json["id"] as num).toInt(),

      title: json["title"]?["english"] ?? json["title"]?["romaji"] ?? "Unknown",

      japaneseTitle: json["title"]?["native"],

      imageUrl: json["coverImage"]?["extraLarge"] ?? "",

      bannerImage: json["bannerImage"],

      synopsis: json["description"] ?? "No synopsis available.",

      genres:
          (json["genres"] as List?)?.map((e) => e.toString()).toList() ?? [],

      rating: ((json["averageScore"] ?? 0) as num).toDouble() / 10,

      type: json["format"] ?? "Unknown",

      episodes: (json["episodes"] as num?)?.toInt(),

      status: json["status"] ?? "Unknown",

      duration: json["duration"] != null
          ? "${json["duration"]} min"
          : "Unknown",

      year: (json["seasonYear"] as num?)?.toInt(),

      studios:
          (json["studios"]?["nodes"] as List?)
              ?.map((e) => e["name"].toString())
              .toList() ??
          [],
    );
  }
}
