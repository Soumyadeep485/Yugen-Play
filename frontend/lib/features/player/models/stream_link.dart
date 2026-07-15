import 'audio_track.dart';
import 'subtitle_track.dart';

/// Represents a single playable media stream.
class StreamLink {
  const StreamLink({
    required this.url,
    required this.quality,
    required this.sourceName,
    required this.isM3U8,
    this.headers = const {},
    this.subtitles = const [],
    this.audioTracks = const [],
    this.isHls = false,
    this.isDefault = false,
  });

  final String url;
  final String quality;
  final String sourceName;
  final bool isM3U8;
  final Map<String, String> headers;
  final List<SubtitleTrack> subtitles;
  final List<AudioTrack> audioTracks;
  final bool isHls;
  final bool isDefault;

  // ... keep the copyWith and toJson methods identical ...

  /// Strict parsing factory (The Ironclad Contract)
  factory StreamLink.fromMap(Map<String, dynamic> map) {
    // 1. Strict Validation: URL is absolutely non-negotiable.
    final streamUrl = map['url']?.toString().trim();
    if (streamUrl == null || streamUrl.isEmpty) {
      throw const FormatException(
        'StreamLink payload rejected: Missing mandatory "url" field.',
      );
    }

    return StreamLink(
      url: streamUrl,
      quality: map['quality']?.toString() ?? 'Auto',
      sourceName: map['sourceName']?.toString() ?? 'Unknown Source',
      isM3U8: map['isM3U8'] as bool? ?? streamUrl.contains('.m3u8'),
      headers: Map<String, String>.from(map['headers'] as Map? ?? const {}),
      subtitles: (map['subtitles'] as List<dynamic>? ?? const [])
          .map((item) => SubtitleTrack.fromJson(item as Map<String, dynamic>))
          .toList(),
      audioTracks: (map['audioTracks'] as List<dynamic>? ?? const [])
          .map((item) => AudioTrack.fromJson(item as Map<String, dynamic>))
          .toList(),
      isHls: map['isHls'] as bool? ?? streamUrl.contains('.m3u8'),
      isDefault: map['isDefault'] as bool? ?? false,
    );
  }

  // Remove the duplicate `fromJson` factory completely to maintain a single source of truth.
  // ... keep the toString, operator ==, and hashCode identical ...
}
