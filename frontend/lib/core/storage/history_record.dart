import 'dart:convert';

class HistoryRecord {
  final String animeId;
  final String animeTitle;
  final String episodeId;
  final int episodeNumber;
  final int positionMs;
  final int durationMs;
  final int updatedAt;

  HistoryRecord({
    required this.animeId,
    required this.animeTitle,
    required this.episodeId,
    required this.episodeNumber,
    required this.positionMs,
    required this.durationMs,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'animeId': animeId,
      'animeTitle': animeTitle,
      'episodeId': episodeId,
      'episodeNumber': episodeNumber,
      'positionMs': positionMs,
      'durationMs': durationMs,
      'updatedAt': updatedAt,
    };
  }

  factory HistoryRecord.fromMap(Map<String, dynamic> map) {
    return HistoryRecord(
      animeId: map['animeId'] ?? '',
      animeTitle: map['animeTitle'] ?? '',
      episodeId: map['episodeId'] ?? '',
      episodeNumber: map['episodeNumber']?.toInt() ?? 1,
      positionMs: map['positionMs']?.toInt() ?? 0,
      durationMs: map['durationMs']?.toInt() ?? 0,
      updatedAt: map['updatedAt']?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  String toJson() => json.encode(toMap());

  factory HistoryRecord.fromJson(String source) => HistoryRecord.fromMap(json.decode(source));
}