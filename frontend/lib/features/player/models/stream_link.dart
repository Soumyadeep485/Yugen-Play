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
  final String sourceName; // e.g., "Vidstreaming", "Filemoon"
  final bool isM3U8; // True if it's an HLS stream
  final Map<String, String> headers;
  final List<SubtitleTrack> subtitles;
  final List<AudioTrack> audioTracks;
  final bool isHls;
  final bool isDefault;

  StreamLink copyWith({
    String? url,
    String? quality,
    String? sourceName,
    bool? isM3U8,
    Map<String, String>? headers,
    List<SubtitleTrack>? subtitles,
    List<AudioTrack>? audioTracks,
    bool? isHls,
    bool? isDefault,
  }) {
    return StreamLink(
      url: url ?? this.url,
      quality: quality ?? this.quality,
      sourceName: sourceName ?? this.sourceName,
      isM3U8: isM3U8 ?? this.isM3U8,
      headers: headers ?? this.headers,
      subtitles: subtitles ?? this.subtitles,
      audioTracks: audioTracks ?? this.audioTracks,
      isHls: isHls ?? this.isHls,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'quality': quality,
      'sourceName': sourceName,
      'isM3U8': isM3U8,
      'headers': headers,
      'subtitles': subtitles.map((subtitle) => subtitle.toJson()).toList(),
      'audioTracks': audioTracks.map((track) => track.toJson()).toList(),
      'isHls': isHls,
      'isDefault': isDefault,
    };
  }

  factory StreamLink.fromJson(Map<String, dynamic> json) {
    final streamUrl = json['url'] as String? ?? '';
    return StreamLink(
      url: streamUrl,
      quality: json['quality'] as String? ?? 'Auto',
      sourceName: json['sourceName'] as String? ?? 'Unknown',
      isM3U8: json['isM3U8'] as bool? ?? streamUrl.contains('.m3u8'),
      headers: Map<String, String>.from(json['headers'] as Map? ?? const {}),
      subtitles: (json['subtitles'] as List<dynamic>? ?? const [])
          .map((item) => SubtitleTrack.fromJson(item as Map<String, dynamic>))
          .toList(),
      audioTracks: (json['audioTracks'] as List<dynamic>? ?? const [])
          .map((item) => AudioTrack.fromJson(item as Map<String, dynamic>))
          .toList(),
      isHls: json['isHls'] as bool? ?? streamUrl.contains('.m3u8'),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'StreamLink(source: $sourceName, quality: $quality, url: $url)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is StreamLink &&
        other.url == url &&
        other.quality == quality &&
        other.sourceName == sourceName &&
        other.isM3U8 == isM3U8 &&
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
    sourceName,
    isM3U8,
    Object.hashAll(headers.entries),
    Object.hashAll(subtitles),
    Object.hashAll(audioTracks),
    isHls,
    isDefault,
  );

  static bool _listEquals<T>(List<T> first, List<T> second) {
    if (identical(first, second)) return true;
    if (first.length != second.length) return false;
    for (var i = 0; i < first.length; i++) {
      if (first[i] != second[i]) return false;
    }
    return true;
  }

  static bool _mapEquals<K, V>(Map<K, V> first, Map<K, V> second) {
    if (identical(first, second)) return true;
    if (first.length != second.length) return false;
    for (final key in first.keys) {
      if (first[key] != second[key]) return false;
    }
    return true;
  }
}
