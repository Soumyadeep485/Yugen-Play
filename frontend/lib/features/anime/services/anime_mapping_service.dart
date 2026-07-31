import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AnimeMappingService {
  // ⚡ Cache to avoid spammed network calls for different episodes of the same anime
  final Map<int, String> _slugCache = {};

  Future<String?> getExactSlug(int anilistId) async {
    if (anilistId <= 0) return null;

    if (_slugCache.containsKey(anilistId)) {
      debugPrint('⚡ [Mapping Cache] Hit for AniList ID $anilistId -> ${_slugCache[anilistId]}');
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
          // 1. Try Gogoanime mapping (primary target for Anikoto/Gogo providers)
          if (sites['Gogoanime'] != null && sites['Gogoanime'] is Map) {
            final Map<String, dynamic> gogoData = sites['Gogoanime'];
            if (gogoData.isNotEmpty) {
              final firstKey = gogoData.keys.first;
              final identifier = gogoData[firstKey]['identifier']?.toString();
              if (identifier != null && identifier.isNotEmpty) {
                _slugCache[anilistId] = identifier;
                debugPrint('✅ [MAL-Sync] Resolved Gogoanime slug: $identifier');
                return identifier;
              }
            }
          }

          // 2. Try Zoro / Aniwatch mapping as fallback
          if (sites['Zoro'] != null && sites['Zoro'] is Map) {
            final Map<String, dynamic> zoroData = sites['Zoro'];
            if (zoroData.isNotEmpty) {
              final firstKey = zoroData.keys.first;
              final identifier = zoroData[firstKey]['identifier']?.toString();
              if (identifier != null && identifier.isNotEmpty) {
                _slugCache[anilistId] = identifier;
                debugPrint('✅ [MAL-Sync] Resolved Zoro slug: $identifier');
                return identifier;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('🚨 [AnimeMappingService] Error mapping AniList ID $anilistId: $e');
    }
    return null;
  }
}