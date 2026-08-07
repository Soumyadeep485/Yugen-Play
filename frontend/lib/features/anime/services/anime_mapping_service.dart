import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/database/kv_helper.dart'; // Adjust import
import 'package:frontend/features/extensions/services/source_mapper.dart'; // Adjust import
import 'package:frontend/shared/models/episode_metadata.dart'; // Adjust path if needed

/// Represents a fully enriched episode combining video stream data and rich UI metadata
class EnrichedEpisode {
  final int number;
  final String title;
  final String? thumbnail;
  final String? description;
  final String streamUrl; // The .m3u8 or raw stream link from extension

  EnrichedEpisode({
    required this.number,
    required this.title,
    this.thumbnail,
    this.description,
    required this.streamUrl,
  });
}

class AnimeMappingService {
  // ⚡ Cache to avoid spammed network calls for MAL-Sync
  static final Map<int, String> _slugCache = {};

  /// Fast-path lookup using MAL-Sync API
  static Future<String?> _getMalSyncSlug(int anilistId) async {
    if (anilistId <= 0) return null;

    if (_slugCache.containsKey(anilistId)) {
      return _slugCache[anilistId];
    }

    try {
      final response = await http.get(
        Uri.parse('https://api.malsync.moe/anilist/anime/$anilistId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final sites = data['Sites'];

        if (sites != null) {
          if (sites['Gogoanime'] != null && sites['Gogoanime'] is Map) {
            final gogoData = sites['Gogoanime'] as Map<String, dynamic>;
            if (gogoData.isNotEmpty) {
              final identifier = gogoData[gogoData.keys.first]['identifier']?.toString();
              if (identifier != null && identifier.isNotEmpty) {
                _slugCache[anilistId] = identifier;
                return identifier;
              }
            }
          }
          if (sites['Zoro'] != null && sites['Zoro'] is Map) {
             final zoroData = sites['Zoro'] as Map<String, dynamic>;
            if (zoroData.isNotEmpty) {
              final identifier = zoroData[zoroData.keys.first]['identifier']?.toString();
              if (identifier != null && identifier.isNotEmpty) {
                _slugCache[anilistId] = identifier;
                return identifier;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('🚨 [MAL-Sync] Error mapping AniList ID $anilistId: $e');
    }
    return null;
  }

  /// Resolves the base slug for an anime (used by player controllers).
  /// Upgraded to check local Isar overrides first, then falls back to MAL-Sync.
  Future<String?> getExactSlug(int anilistId) async {
    if (anilistId <= 0) return null;

    // STEP 1: Check if user manually corrected the title (Isar Sticky Cache)
    final stickySlug = DynamicKeys.stickySource.get<String?>(anilistId.toString());
    if (stickySlug != null && stickySlug.isNotEmpty) {
      debugPrint('✅ [Isar Override] Using manual slug: $stickySlug');
      return stickySlug;
    }

    // STEP 2: Try MAL-Sync for a fast lookup
    final malSyncSlug = await _getMalSyncSlug(anilistId);
    if (malSyncSlug != null && malSyncSlug.isNotEmpty) {
      return malSyncSlug;
    }

    return null;
  }

  /// The master function to load fully enriched episodes
  static Future<List<EnrichedEpisode>> loadEnrichedEpisodes<T extends Object>({
    required String mediaId,
    required List<String> titles,
    required List<String> synonyms,
    required Future<List<T>> Function(String query) searchExtension,
    required String Function(T item) getTitleFromItem,
    required Future<List<Map<String, dynamic>>> Function(String extensionSlug) fetchRawExtensionEpisodes,
    required Future<List<EpisodeMetadata>> Function(String mediaId) fetchRichMetadata,
    void Function(String status)? onStatusUpdate,
  }) async {
    
    String? resolvedExtensionSlug;

    // STEP 1: Check if user manually corrected the title before (Isar Sticky Cache)
    resolvedExtensionSlug = DynamicKeys.stickySource.get<String?>(mediaId);

    // STEP 2: Try MAL-Sync for a fast lookup (if no manual override exists)
    if (resolvedExtensionSlug == null || resolvedExtensionSlug.isEmpty) {
      onStatusUpdate?.call("Checking MAL-Sync database...");
      final intId = int.tryParse(mediaId) ?? 0;
      resolvedExtensionSlug = await _getMalSyncSlug(intId);
    }

    // STEP 3: Fallback to Fuzzy Matching (if MAL-Sync fails or is missing the anime)
    if (resolvedExtensionSlug == null || resolvedExtensionSlug.isEmpty) {
      onStatusUpdate?.call("MAL-Sync failed. Running fuzzy match...");
      final matchedItem = await SourceMapper.mapMedia<T>(
        mediaId: mediaId,
        titles: titles,
        synonyms: synonyms,
        searchExtension: searchExtension,
        getTitleFromItem: getTitleFromItem,
        onStatusUpdate: onStatusUpdate,
      );

      if (matchedItem != null) {
        resolvedExtensionSlug = getTitleFromItem(matchedItem); // Or extract URL/slug from T
      }
    }

    // If all three stages fail, we abort.
    if (resolvedExtensionSlug == null || resolvedExtensionSlug.isEmpty) {
      onStatusUpdate?.call("Could not map anime to extension.");
      return [];
    }

    onStatusUpdate?.call("Fetching episode streams & metadata...");

    // STEP 4: Fetch raw streams and rich metadata concurrently
    final results = await Future.wait([
      fetchRawExtensionEpisodes(resolvedExtensionSlug),
      fetchRichMetadata(mediaId),
    ]);

    final rawEpisodes = results[0] as List<Map<String, dynamic>>;
    final metadataList = results[1] as List<EpisodeMetadata>;

    final metadataMap = {
  for (var meta in metadataList) meta.number: meta
};

    // STEP 5: Merge streams with metadata
    final List<EnrichedEpisode> enrichedList = [];

    for (int i = 0; i < rawEpisodes.length; i++) {
      final raw = rawEpisodes[i];
      final epNum = (raw['number'] as num?)?.toInt() ?? (i + 1);
      final streamUrl = raw['url']?.toString() ?? '';

      final meta = metadataMap[epNum];

      enrichedList.add(
        EnrichedEpisode(
          number: epNum,
          title: meta?.title ?? "Episode $epNum",
          thumbnail: meta?.thumbnail ?? raw['thumbnail']?.toString(),
          description: meta?.description,
          streamUrl: streamUrl,
        ),
      );
    }

    onStatusUpdate?.call("Complete");
    return enrichedList;
  }
}