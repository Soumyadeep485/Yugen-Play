/// Represents an audio track available for a playable stream.
///
/// This model is provider-agnostic and describes a single audio option
/// exposed by a streaming provider.
///
/// Examples:
/// - Japanese
/// - English Dub
/// - Hindi Dub
/// - Dual Audio
///
/// The player uses this model to populate the audio selection UI.
/// It contains metadata only and does not represent a playable stream.
class AudioTrack {
  const AudioTrack({
    required this.label,
    required this.languageCode,
    this.isDefault = false,
  });

  /// Human-readable audio track name.
  ///
  /// Examples:
  /// - Japanese
  /// - English
  /// - Hindi Dub
  final String label;

  /// ISO 639 language code.
  ///
  /// Examples:
  /// - ja
  /// - en
  /// - hi
  /// - es
  final String languageCode;

  /// Whether this audio track should be selected automatically.
  final bool isDefault;

  /// Returns a copy of this audio track with the provided changes.
  AudioTrack copyWith({String? label, String? languageCode, bool? isDefault}) {
    return AudioTrack(
      label: label ?? this.label,
      languageCode: languageCode ?? this.languageCode,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  /// Converts this audio track into a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'languageCode': languageCode,
      'isDefault': isDefault,
    };
  }

  /// Creates an [AudioTrack] from JSON.
  factory AudioTrack.fromJson(Map<String, dynamic> json) {
    return AudioTrack(
      label: json['label'] as String,
      languageCode: json['languageCode'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'AudioTrack('
        'label: $label, '
        'languageCode: $languageCode, '
        'isDefault: $isDefault'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AudioTrack &&
        other.label == label &&
        other.languageCode == languageCode &&
        other.isDefault == isDefault;
  }

  @override
  int get hashCode => Object.hash(label, languageCode, isDefault);
}
