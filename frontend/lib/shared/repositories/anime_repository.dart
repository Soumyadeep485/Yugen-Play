import 'dart:convert';

import '../models/anime.dart';
import '../services/api_service.dart';

class AnimeRepository {
  final ApiService apiService;

  AnimeRepository(this.apiService);

  Future<Anime> getFeaturedAnime() async {
    final response = await apiService.get("/top/anime");

    if (response.statusCode != 200) {
      throw Exception("Failed to load anime");
    }

    final json = jsonDecode(response.body);

    final firstAnime = json["data"][0];

    return Anime.fromJson(firstAnime);
  }

  Future<List<Anime>> getTopAnime() async {
    final response = await apiService.get("/top/anime");

    if (response.statusCode != 200) {
      throw Exception("Failed to load anime");
    }

    final json = jsonDecode(response.body);

    final List data = json["data"];

    return data.take(15).map((anime) => Anime.fromJson(anime)).toList();
  }
}
