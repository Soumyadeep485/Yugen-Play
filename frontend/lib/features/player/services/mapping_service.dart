import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class MappingService {
  final Dio _dio = Dio();

  /// Takes an AniList ID and an episode number, and returns the exact Gogoanime episode URL.
  Future<String?> getGogoanimeEpisodeUrl(
    int anilistId,
    int episodeNumber,
  ) async {
    try {
      debugPrint('🗺️ Requesting mapping for AniList ID: $anilistId');

      // Ping the MAL-Sync API
      final response = await _dio.get(
        'https://api.malsync.moe/anilist/anime/$anilistId',
      );

      if (response.statusCode != 200) {
        debugPrint('❌ MAL-Sync API failed with status: ${response.statusCode}');
        return null;
      }

      final data = response.data;

      // Navigate the JSON tree to find Gogoanime
      final sites = data['Sites'];
      if (sites == null || sites['Gogoanime'] == null) {
        debugPrint('❌ No Gogoanime mapping found for this title.');
        return null;
      }

      final gogoNode = sites['Gogoanime'] as Map<String, dynamic>;

      // MAL-Sync uses dynamic keys for the identifier, so we grab the first one
      final firstKey = gogoNode.keys.first;
      final identifier = gogoNode[firstKey]['identifier'];

      // Construct the actual episode URL that our JS engine expects
      // Gogoanime typically follows the format: domain.com/identifier-episode-X
      final episodeUrl =
          'https://gogoanime3.co/$identifier-episode-$episodeNumber';

      debugPrint('✅ Mapping successful: $episodeUrl');
      return episodeUrl;
    } catch (e) {
      debugPrint('❌ Mapping Service Error: $e');
      return null;
    }
  }
}
