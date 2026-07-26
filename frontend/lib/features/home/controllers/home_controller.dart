import 'package:flutter/material.dart';

import '../../../../shared/models/anime.dart';
import '../services/home_repository.dart';

enum MediaContext { anime, manga }

class HomeController extends ChangeNotifier {
  final HomeRepository _repository;

  HomeController(this._repository);

  bool isLoading = true;

  List<Anime> trendingAnime = [];
  List<Anime> trendingManga = [];

  MediaContext currentContext = MediaContext.anime;

  List<Anime> get activeTrendingList =>
      currentContext == MediaContext.anime ? trendingAnime : trendingManga;

  Future<void> loadInitialData() async {
    isLoading = true;
    notifyListeners();

    try {
      final homeData = await _repository.fetchHomeData();
      trendingAnime = homeData.trending;
    } catch (e) {
      debugPrint("Error loading initial home data: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> switchContext(MediaContext newContext) async {
    if (currentContext == newContext) {
      return;
    }

    currentContext = newContext;
    notifyListeners();

    if (newContext == MediaContext.manga && trendingManga.isEmpty) {
      isLoading = true;
      notifyListeners();

      try {
        final homeData = await _repository.fetchHomeData();
        trendingManga = homeData.trending;
      } catch (e) {
        debugPrint("Error loading manga data: $e");
      } finally {
        isLoading = false;
        notifyListeners();
      }
    } else if (newContext == MediaContext.anime && trendingAnime.isEmpty) {
      isLoading = true;
      notifyListeners();

      try {
        final homeData = await _repository.fetchHomeData();
        trendingAnime = homeData.trending;
      } catch (e) {
        debugPrint("Error loading anime data: $e");
      } finally {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> refreshActiveData() async {
    isLoading = true;
    notifyListeners();

    try {
      final homeData = await _repository.fetchHomeData();
      if (currentContext == MediaContext.anime) {
        trendingAnime = homeData.trending;
      } else {
        trendingManga = homeData.trending;
      }
    } catch (e) {
      debugPrint("Error refreshing active data: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
