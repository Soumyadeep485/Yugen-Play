/// Represents a subtitle track available for a playable stream.
///
/// This model is provider-agnostic and is used throughout the player
/// feature regardless of where the subtitles originate.
///
/// Supported subtitle formats include (but are not limited to):
/// - WebVTT (.vtt)
/// - SubRip (.srt)
/// - ASS / SSA
///
/// The player implementation is responsible for determining whether
/// a specific subtitle format is supported.
class SubtitleTrack {
  const SubtitleTrack({
    required this.label,
    required this.languageCode,
    required this.url,
    this.isDefault = false,
  });

  /// Human-readable subtitle label.
  ///
  /// Examples:
  /// - English
  /// - English (CC)
  /// - Japanese
  /// - Hindi
  final String label;

  /// ISO 639 language code.
  ///
  /// Examples:
  /// - en
  /// - ja
  /// - hi
  /// - es
  final String languageCode;

  /// URL to the subtitle resource.
  final String url;

  /// Whether this subtitle should be selected by default.
  final bool isDefault;

  /// Returns a modified copy of this subtitle track.
  SubtitleTrack copyWith({
    String? label,
    String? languageCode,
    String? url,
    bool? isDefault,
  }) {
    return SubtitleTrack(
      label: label ?? this.label,
      languageCode: languageCode ?? this.languageCode,
      url: url ?? this.url,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  /// Converts this subtitle track into a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'languageCode': languageCode,
      'url': url,
      'isDefault': isDefault,
    };
  }

  /// Creates a [SubtitleTrack] from JSON.
  factory SubtitleTrack.fromJson(Map<String, dynamic> json) {
    return SubtitleTrack(
      label: json['label'] as String,
      languageCode: json['languageCode'] as String,
      url: json['url'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'SubtitleTrack('
        'label: $label, '
        'languageCode: $languageCode, '
        'isDefault: $isDefault'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SubtitleTrack &&
        other.label == label &&
        other.languageCode == languageCode &&
        other.url == url &&
        other.isDefault == isDefault;
  }

  @override
  int get hashCode => Object.hash(label, languageCode, url, isDefault);
}
