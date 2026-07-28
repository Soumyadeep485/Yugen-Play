import 'dart:async';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'hive_boxes.dart';
import 'history_record.dart';

class HistoryRepository {
  final Box<String> _box = Hive.box<String>(HiveBoxes.continueWatching);
  Timer? _debounceTimer;

  /// Retrieves the saved history for a specific anime
  HistoryRecord? getHistory(String animeId) {
    final jsonStr = _box.get(animeId);
    if (jsonStr == null) return null;
    try {
      return HistoryRecord.fromJson(jsonStr);
    } catch (e) {
      return null; // Handle corrupted JSON silently
    }
  }

  /// Saves the progress, but debounces the disk write to prevent UI stutter
  void saveProgressDebounced({
    required String animeId,
    required String animeTitle,
    required String episodeId,
    required int episodeNumber,
    required Duration position,
    required Duration duration,
  }) {
    // Ignore tiny accidental plays or completions
    if (position.inSeconds < 5 || position.inMilliseconds >= duration.inMilliseconds - 5000) {
      return; 
    }

    final record = HistoryRecord(
      animeId: animeId,
      animeTitle: animeTitle,
      episodeId: episodeId,
      episodeNumber: episodeNumber,
      positionMs: position.inMilliseconds,
      durationMs: duration.inMilliseconds,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    // Cancel the previous timer if it exists
    _debounceTimer?.cancel();

    // Wait 5 seconds before actually writing to the Hive box
    _debounceTimer = Timer(const Duration(seconds: 5), () {
      _box.put(animeId, record.toJson());
    });
  }
  
  /// Force an immediate save (Use this when the player screen is closed/disposed)
  void saveProgressImmediate(HistoryRecord record) {
    _debounceTimer?.cancel();
    _box.put(record.animeId, record.toJson());
  }
}