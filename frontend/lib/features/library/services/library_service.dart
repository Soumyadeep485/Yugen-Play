import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../../../shared/models/anime.dart';

class LibraryService {
  final Box<String> _libraryBox = Hive.box<String>('anime_library');

  /// Saves or updates an anime's status in the library
  Future<void> saveToLibrary({
    required Anime anime,
    required String status, // 'Watching', 'Plan to Watch', 'Completed', 'Dropped'
  }) async {
    final data = {
      'animeId': anime.id.toString(),
      'title': anime.title,
      'posterUrl': anime.coverImage ?? anime.bannerImage ?? '',
      'status': status,
      'episodes': anime.episodes ?? 0,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };

    await _libraryBox.put(anime.id.toString(), jsonEncode(data));
    debugPrint('📌 [Library] Saved ${anime.title} as "$status"');
  }

  /// Gets the saved status for a specific anime (returns null if not in library)
  String? getAnimeStatus(String animeId) {
    final raw = _libraryBox.get(animeId);
    if (raw == null) return null;
    final Map<String, dynamic> data = jsonDecode(raw);
    return data['status'] as String?;
  }

  /// Removes an anime from the library entirely
  Future<void> removeFromLibrary(String animeId) async {
    await _libraryBox.delete(animeId);
    debugPrint('🗑️ [Library] Removed anime ID: $animeId');
  }

  /// Fetches all items in the library filtered by status (or all if status is null)
  List<Map<String, dynamic>> getLibraryItems({String? statusFilter}) {
    final all = _libraryBox.values
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();

    if (statusFilter == null || statusFilter == 'All') {
      return all;
    }

    return all.where((item) => item['status'] == statusFilter).toList();
  }
  /// Silently updates the status of an existing library entry
  Future<void> updateStatus(String animeId, String newStatus) async {
    final raw = _libraryBox.get(animeId);
    if (raw != null) {
      final Map<String, dynamic> data = jsonDecode(raw);
      // Only update if it isn't already set to the new status
      if (data['status'] != newStatus) {
        data['status'] = newStatus;
        data['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
        await _libraryBox.put(animeId, jsonEncode(data));
        debugPrint('✅ [Library] Auto-updated anime ID $animeId to "$newStatus"');
      }
    }
  }
  /// Forcibly adds or updates an anime from the Player, even if it wasn't in the library before.
  Future<void> upsertFromPlayer({
    required String animeId,
    required String title,
    required String posterUrl,
    required String status,
    int? totalEpisodes,
  }) async {
    final raw = _libraryBox.get(animeId);
    
    if (raw != null) {
      // It exists, just update the status if needed
      final Map<String, dynamic> data = jsonDecode(raw);
      if (data['status'] != status) {
        data['status'] = status;
        data['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
        await _libraryBox.put(animeId, jsonEncode(data));
      }
    } else {
      // It doesn't exist, create a new library entry
      final data = {
        'animeId': animeId,
        'title': title,
        'posterUrl': posterUrl,
        'status': status,
        'episodes': totalEpisodes ?? 0,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };
      await _libraryBox.put(animeId, jsonEncode(data));
      debugPrint('📌 [Library] Auto-added $title to "$status" from Player.');
    }
  }
}