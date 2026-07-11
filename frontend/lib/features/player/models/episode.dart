/// Represents a single anime episode exposed by a streaming provider.
///
/// This model is intentionally provider-agnostic and acts as the unified
/// domain model throughout the player feature.
///
/// Individual providers (HiAnime, AnimePahe, etc.) are responsible for
/// converting their own responses into this model.
///
/// The model is immutable and fully serializable, making it suitable for:
/// - Offline caching (Hive)
/// - Continue Watching
/// - Favorites
/// - UI rendering
/// - Testing
/// - Future cloud synchronization
class Episode {
  const Episode({
    required this.id,
    required this.providerId,
    required this.anilistId,
    required this.number,
    required this.title,
    this.description,
    this.thumbnail,
    this.duration,
    this.airedAt,
    this.isFiller = false,
    this.isRecap = false,
  });

  /// Internal unique identifier.
  final String id;

  /// Episode identifier used by the streaming provider.
  final String providerId;

  /// AniList anime identifier.
  final int anilistId;

  /// Episode number.
  final int number;

  /// Episode title.
  final String title;

  /// Optional episode synopsis.
  final String? description;

  /// Optional episode thumbnail URL.
  final String? thumbnail;

  /// Episode duration in minutes.
  final int? duration;

  /// Air date/time.
  final DateTime? airedAt;

  /// Whether this episode is marked as filler.
  final bool isFiller;

  /// Whether this episode is a recap episode.
  final bool isRecap;

  /// Creates a modified copy of this episode.
  Episode copyWith({
    String? id,
    String? providerId,
    int? anilistId,
    int? number,
    String? title,
    String? description,
    String? thumbnail,
    int? duration,
    DateTime? airedAt,
    bool? isFiller,
    bool? isRecap,
  }) {
    return Episode(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      anilistId: anilistId ?? this.anilistId,
      number: number ?? this.number,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnail: thumbnail ?? this.thumbnail,
      duration: duration ?? this.duration,
      airedAt: airedAt ?? this.airedAt,
      isFiller: isFiller ?? this.isFiller,
      isRecap: isRecap ?? this.isRecap,
    );
  }

  /// Converts this episode into a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'providerId': providerId,
      'anilistId': anilistId,
      'number': number,
      'title': title,
      'description': description,
      'thumbnail': thumbnail,
      'duration': duration,
      'airedAt': airedAt?.toIso8601String(),
      'isFiller': isFiller,
      'isRecap': isRecap,
    };
  }

  /// Creates an [Episode] from JSON.
  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'] as String,
      providerId: json['providerId'] as String,
      anilistId: json['anilistId'] as int,
      number: json['number'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      thumbnail: json['thumbnail'] as String?,
      duration: json['duration'] as int?,
      airedAt: json['airedAt'] != null
          ? DateTime.parse(json['airedAt'] as String)
          : null,
      isFiller: json['isFiller'] as bool? ?? false,
      isRecap: json['isRecap'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'Episode('
        'id: $id, '
        'providerId: $providerId, '
        'anilistId: $anilistId, '
        'number: $number, '
        'title: $title'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Episode &&
        other.id == id &&
        other.providerId == providerId &&
        other.anilistId == anilistId &&
        other.number == number &&
        other.title == title &&
        other.description == description &&
        other.thumbnail == thumbnail &&
        other.duration == duration &&
        other.airedAt == airedAt &&
        other.isFiller == isFiller &&
        other.isRecap == isRecap;
  }

  @override
  int get hashCode => Object.hash(
    id,
    providerId,
    anilistId,
    number,
    title,
    description,
    thumbnail,
    duration,
    airedAt,
    isFiller,
    isRecap,
  );
}
