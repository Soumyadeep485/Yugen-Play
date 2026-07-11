/// Defines all supported streaming providers.
///
/// This enum is the single source of truth for identifying
/// streaming providers throughout the application.
///
/// Add new providers here as they are implemented.
///
/// Example:
/// ```dart
/// final source = StreamingSource.hianime;
/// print(source.displayName); // HiAnime
/// ```
enum StreamingSource {
  /// HiAnime provider.
  hianime(key: 'hianime', displayName: 'HiAnime'),

  /// AnimePahe provider.
  animepahe(key: 'animepahe', displayName: 'AnimePahe'),

  /// User-defined or self-hosted provider.
  custom(key: 'custom', displayName: 'Custom');

  const StreamingSource({required this.key, required this.displayName});

  /// Stable identifier used for persistence and serialization.
  final String key;

  /// Human-readable provider name.
  final String displayName;

  /// Creates a [StreamingSource] from its serialized key.
  ///
  /// Throws an [ArgumentError] if the key is unsupported.
  factory StreamingSource.fromKey(String key) {
    return StreamingSource.values.firstWhere(
      (source) => source.key == key,
      orElse: () => throw ArgumentError.value(
        key,
        'key',
        'Unsupported streaming source.',
      ),
    );
  }

  /// Serializes this enum to a stable string key.
  String toJson() => key;

  @override
  String toString() => displayName;
}
