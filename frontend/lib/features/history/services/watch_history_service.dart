import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';

class WatchHistoryService {
  final Box<String> _historyBox = Hive.box<String>('watch_history');

  /// Saves the user's progress. Uses animeId as the key so it overwrites
  /// previous episodes of the same anime (keeping only the most recent).
  Future<void> saveHistory({
    required String animeId,
    required String animeTitle,
    required String episodeId,
    required int episodeNumber,
    required String posterUrl,
    required int positionMs,
    required int durationMs,
  }) async {
    // Don't save if they've watched less than 5 seconds
    if (positionMs < 5000) return;

    final data = {
      'animeId': animeId,
      'animeTitle': animeTitle,
      'episodeId': episodeId,
      'episodeNumber': episodeNumber,
      'posterUrl': posterUrl,
      'positionMs': positionMs,
      'durationMs': durationMs,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    await _historyBox.put(animeId, jsonEncode(data));
  }

  /// Gets the history for a specific anime (used to resume play)
  Map<String, dynamic>? getHistory(String animeId) {
    final data = _historyBox.get(animeId);
    if (data == null) return null;
    return jsonDecode(data);
  }

  /// Gets all history sorted by most recently watched (for the Home Screen)
  List<Map<String, dynamic>> getAllHistory() {
    final all = _historyBox.values
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();

    // Sort by timestamp descending (newest first)
    all.sort(
      (a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int),
    );
    return all;
  }

  Future<void> clearHistory(String animeId) async {
    await _historyBox.delete(animeId);
  }
  Future<void> clearAllHistory() async {
    await _historyBox.clear();
  }
}
