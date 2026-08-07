import 'package:flutter/foundation.dart';
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
      'subtitles': subtitles.map((s) => s.toJson()).toList(),
      'audioTracks': audioTracks.map((a) => a.toJson()).toList(),
      'isHls': isHls,
      'isDefault': isDefault,
    };
  }

  /// Strict parsing factory (The Ironclad Contract)
  factory StreamLink.fromMap(Map<String, dynamic> map) {
    final streamUrl = map['url']?.toString().trim();
    if (streamUrl == null || streamUrl.isEmpty) {
      throw const FormatException(
        'StreamLink payload rejected: Missing mandatory "url" field.',
      );
    }

    // 🚀 THE FIX: Accept Map<dynamic, dynamic> from JS, then cast to Map<String, dynamic>
    List<SubtitleTrack> safeSubtitles = [];
    if (map['subtitles'] != null && map['subtitles'] is List) {
      for (var item in map['subtitles']) {
        try {
          if (item is Map) {
            safeSubtitles.add(SubtitleTrack.fromJson(Map<String, dynamic>.from(item)));
          }
        } catch (e) {
          debugPrint('⚠️ [StreamLink] Skipped invalid subtitle track: $e');
        }
      }
    }

    // 🚀 THE FIX: Applied to audio tracks as well just in case!
    List<AudioTrack> safeAudio = [];
    if (map['audioTracks'] != null && map['audioTracks'] is List) {
      for (var item in map['audioTracks']) {
        try {
          if (item is Map) {
            safeAudio.add(AudioTrack.fromJson(Map<String, dynamic>.from(item)));
          }
        } catch (e) {
          debugPrint('⚠️ [StreamLink] Skipped invalid audio track: $e');
        }
      }
    }

    return StreamLink(
      url: streamUrl,
      quality: map['quality']?.toString() ?? 'Auto',
      sourceName: map['sourceName']?.toString() ?? 'Unknown Source',
      isM3U8: map['isM3U8'] as bool? ?? streamUrl.contains('.m3u8'),
      headers: Map<String, String>.from(map['headers'] as Map? ?? const {}),
      subtitles: safeSubtitles,
      audioTracks: safeAudio,
      isHls: map['isHls'] as bool? ?? streamUrl.contains('.m3u8'),
      isDefault: map['isDefault'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'StreamLink('
        'url: $url, '
        'quality: $quality, '
        'sourceName: $sourceName, '
        'isM3U8: $isM3U8, '
        'isHls: $isHls'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is StreamLink &&
        other.url == url &&
        other.quality == quality &&
        other.sourceName == sourceName &&
        other.isM3U8 == isM3U8 &&
        other.isHls == isHls &&
        other.isDefault == isDefault;
  }

  @override
  int get hashCode => Object.hash(url, quality, sourceName, isM3U8, isHls, isDefault);
}