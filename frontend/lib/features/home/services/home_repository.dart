import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/network/anilist_client.dart';
import '../../../shared/models/anime.dart';
import '../models/home_data.dart';
import 'home_queries.dart'; // Make sure this is imported

class HomeRepository {
  final AniListClient _client;

  HomeRepository(this._client);

  Future<HomeData> fetchHomeData() async {
    try {
      // 1. Try AniList First
      return await _fetchFromAniList();
    } catch (e) {
      debugPrint("🚨 AniList API failed or rate-limited. Falling back to Jikan: $e");
      
      try {
        // 2. Immediate Fallback to Jikan
        return await _fetchFromJikan();
      } catch (jikanError) {
        debugPrint("🚨 Jikan Fallback also failed: $jikanError");
        return HomeData.empty();
      }
    }
  }

  Future<HomeData> getHomeData() => fetchHomeData();

  // --- ANILIST PRIMARY FETCH ---
  Future<HomeData> _fetchFromAniList() async {
    // Actually using your HomeQueries file instead of the hardcoded duplicate query!
    final data = await _client.query(queryString: HomeQueries.homeFeed);

    if (data == null) throw Exception("AniList returned null data");

    List<Anime> parseList(String key) {
      if (data[key] != null && data[key]['media'] != null) {
        return (data[key]['media'] as List)
            .map((e) => Anime.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    }

    return HomeData(
      trending: parseList('trending'),
      popular: parseList('popular'),
      seasonal: parseList('airing'),
      topRated: parseList('upcoming'), 
    );
  }

  // --- JIKAN FALLBACK FETCH ---
  Future<HomeData> _fetchFromJikan() async {
    debugPrint("Fetching from Jikan with browser headers...");
    
    // Standard headers to trick Cloudflare into treating the app like a web browser
    final headers = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'application/json',
      'Referer': 'https://myanimelist.net/',
    };

    Future<List<Anime>> safeFetch(String url) async {
      try {
        // Using a 10-second timeout so it doesn't hang indefinitely on a 504 gateway drop
        final res = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 10));
        
        if (res.statusCode == 200) {
          final jsonBody = jsonDecode(res.body);
          final dataList = jsonBody['data'] as List? ?? [];
          return dataList.map((jikanData) {
            return Anime.fromJson(_mapJikanToAniList(jikanData));
          }).toList();
        } else {
          debugPrint("Jikan failed for $url: Status ${res.statusCode}");
          return [];
        }
      } catch (e) {
        debugPrint("Jikan network crash for $url: $e");
        return [];
      }
    }

    final trendingList = await safeFetch('https://api.jikan.moe/v4/top/anime?filter=airing&limit=15');
    await Future.delayed(const Duration(milliseconds: 1000)); 
    
    final popularList = await safeFetch('https://api.jikan.moe/v4/top/anime?filter=bypopularity&limit=15');
    await Future.delayed(const Duration(milliseconds: 1000)); 
    
    final upcomingList = await safeFetch('https://api.jikan.moe/v4/seasons/upcoming?limit=15');

    return HomeData(
      trending: trendingList,
      popular: popularList,
      seasonal: trendingList, 
      topRated: upcomingList,
    );
  }

  // --- JIKAN TO ANILIST JSON ADAPTER ---
  Map<String, dynamic> _mapJikanToAniList(Map<String, dynamic> jikanData) {
    // Jikan score is 1-10. AniList is 1-100.
    int? averageScore;
    if (jikanData['score'] != null) {
      averageScore = (jikanData['score'] * 10).toInt();
    }

    String mapStatus(String? jikanStatus) {
      if (jikanStatus == "Currently Airing") return "RELEASING";
      if (jikanStatus == "Finished Airing") return "FINISHED";
      if (jikanStatus == "Not yet aired") return "NOT_YET_RELEASED";
      return "UNKNOWN";
    }

    return {
      'id': jikanData['mal_id'],
      'title': {
        'english': jikanData['title_english'],
        'romaji': jikanData['title'],
        'native': jikanData['title_japanese'],
        'userPreferred': jikanData['title_english'] ?? jikanData['title'],
      },
      'coverImage': {
        'extraLarge': jikanData['images']?['jpg']?['large_image_url'],
        'large': jikanData['images']?['jpg']?['large_image_url'],
        'medium': jikanData['images']?['jpg']?['image_url'],
      },
      'bannerImage': null, // Jikan doesn't return banners in standard endpoints
      'genres': jikanData['genres']?.map((g) => g['name']).toList() ?? [],
      'averageScore': averageScore,
      'episodes': jikanData['episodes'],
      'format': jikanData['type']?.toString().toUpperCase() ?? "TV",
      'seasonYear': jikanData['year'],
      'status': mapStatus(jikanData['status']),
      'description': jikanData['synopsis'],
    };
  }
}