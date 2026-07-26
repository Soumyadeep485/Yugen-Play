import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class MappingService {
  final Dio _dio;

  MappingService(this._dio);

  /// Takes an AniList ID and an episode number, and returns the exact Gogoanime episode URL.
  Future<String?> getGogoanimeEpisodeUrl(
    int anilistId,
    int episodeNumber,
  ) async {
    try {
      debugPrint('Requesting mapping for AniList ID: $anilistId');

      final response = await _dio.get(
        'https://api.malsync.moe/mal/anime/anilist:$anilistId',
      );

      if (response.statusCode != 200) {
        debugPrint('MAL-Sync API failed with status: ${response.statusCode}');
        return null;
      }

      final data = response.data;
      final sites = data['Sites'];
      if (sites == null || sites['Gogoanime'] == null) {
        debugPrint('No Gogoanime mapping found for this title.');
        return null;
      }

      final gogoNode = sites['Gogoanime'] as Map<String, dynamic>;
      final firstKey = gogoNode.keys.first;
      final identifier = gogoNode[firstKey]['identifier'];

      final episodeUrl = 'https://gogoanime3.co/$identifier-episode-$episodeNumber';
      return episodeUrl;
    } catch (e) {
      debugPrint('Mapping Service Error: $e');
      return null;
    }
  }
}