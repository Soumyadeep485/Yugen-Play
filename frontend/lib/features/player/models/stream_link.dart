import 'audio_track.dart';
import 'subtitle_track.dart';

/// Represents a single playable media stream.
///
/// A [StreamLink] contains all information required by the player
/// to start playback.
///
/// It is intentionally provider-agnostic and supports:
///
/// • MP4 streams
/// • HLS (.m3u8)
/// • Required HTTP headers
/// • Multiple subtitle tracks
/// • Multiple audio tracks
///
/// This model is designed to remain stable as new streaming providers
/// are added to the application.
class StreamLink {
  const StreamLink({
    required this.url,
    required this.quality,
    this.headers = const {},
    this.subtitles = const [],
    this.audioTracks = const [],
    this.isHls = false,
    this.isDefault = false,
  });

  /// Direct playable media URL.
  final String url;

  /// Human-readable quality label.
  ///
  /// Examples:
  /// - Auto
  /// - 360p
  /// - 480p
  /// - 720p
  /// - 1080p
  final String quality;

  /// Additional HTTP headers required when requesting this stream.
  ///
  /// Some providers require headers such as:
  /// - Referer
  /// - Origin
  /// - User-Agent
  final Map<String, String> headers;

  /// Available subtitle tracks.
  final List<SubtitleTrack> subtitles;

  /// Available audio tracks.
  final List<AudioTrack> audioTracks;

  /// Indicates whether this stream uses HLS (.m3u8).
  ///
  /// False generally indicates a direct video file such as MP4.
  final bool isHls;

  /// Whether this stream should be selected automatically.
  final bool isDefault;

  /// Creates a modified copy of this stream.
  StreamLink copyWith({
    String? url,
    String? quality,
    Map<String, String>? headers,
    List<SubtitleTrack>? subtitles,
    List<AudioTrack>? audioTracks,
    bool? isHls,
    bool? isDefault,
  }) {
    return StreamLink(
      url: url ?? this.url,
      quality: quality ?? this.quality,
      headers: headers ?? this.headers,
      subtitles: subtitles ?? this.subtitles,
      audioTracks: audioTracks ?? this.audioTracks,
      isHls: isHls ?? this.isHls,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  /// Converts this stream into a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'quality': quality,
      'headers': headers,
      'subtitles': subtitles.map((subtitle) => subtitle.toJson()).toList(),
      'audioTracks': audioTracks.map((track) => track.toJson()).toList(),
      'isHls': isHls,
      'isDefault': isDefault,
    };
  }

  /// Creates a [StreamLink] from JSON.
  factory StreamLink.fromJson(Map<String, dynamic> json) {
    return StreamLink(
      url: json['url'] as String,
      quality: json['quality'] as String,
      headers: Map<String, String>.from(json['headers'] as Map? ?? const {}),
      subtitles: (json['subtitles'] as List<dynamic>? ?? const [])
          .map((item) => SubtitleTrack.fromJson(item as Map<String, dynamic>))
          .toList(),
      audioTracks: (json['audioTracks'] as List<dynamic>? ?? const [])
          .map((item) => AudioTrack.fromJson(item as Map<String, dynamic>))
          .toList(),
      isHls: json['isHls'] as bool? ?? false,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'StreamLink('
        'quality: $quality, '
        'url: $url, '
        'isHls: $isHls, '
        'isDefault: $isDefault, '
        'subtitles: ${subtitles.length}, '
        'audioTracks: ${audioTracks.length}'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is StreamLink &&
        other.url == url &&
        other.quality == quality &&
        _mapEquals(other.headers, headers) &&
        _listEquals(other.subtitles, subtitles) &&
        _listEquals(other.audioTracks, audioTracks) &&
        other.isHls == isHls &&
        other.isDefault == isDefault;
  }

  @override
  int get hashCode => Object.hash(
    url,
    quality,
    Object.hashAll(headers.entries),
    Object.hashAll(subtitles),
    Object.hashAll(audioTracks),
    isHls,
    isDefault,
  );

  static bool _listEquals<T>(List<T> first, List<T> second) {
    if (identical(first, second)) {
      return true;
    }

    if (first.length != second.length) {
      return false;
    }

    for (var i = 0; i < first.length; i++) {
      if (first[i] != second[i]) {
        return false;
      }
    }

    return true;
  }

  static bool _mapEquals<K, V>(Map<K, V> first, Map<K, V> second) {
    if (identical(first, second)) {
      return true;
    }

    if (first.length != second.length) {
      return false;
    }

    for (final key in first.keys) {
      if (first[key] != second[key]) {
        return false;
      }
    }

    return true;
  }
}
