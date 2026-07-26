import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../shared/models/anime.dart';

class SearchState {
  final List<Anime> searchResults;
  final bool isLoading;
  final String currentQuery;

  // Active Filters
  final String? genre;
  final String? format;
  final String? sort; // e.g., 'POPULARITY_DESC'
  final String? status; // e.g., 'RELEASING'
  final String? customLabel; // For the UI Chip (e.g., "Popular Animes")

  SearchState({
    required this.searchResults,
    required this.isLoading,
    required this.currentQuery,
    this.genre,
    this.format,
    this.sort,
    this.status,
    this.customLabel,
  });

  SearchState copyWith({
    List<Anime>? searchResults,
    bool? isLoading,
    String? currentQuery,
    String? genre,
    String? format,
    String? sort,
    String? status,
    String? customLabel,
    bool clearGenre = false,
    bool clearFormat = false,
    bool clearSortAndStatus = false,
  }) {
    return SearchState(
      searchResults: searchResults ?? this.searchResults,
      isLoading: isLoading ?? this.isLoading,
      currentQuery: currentQuery ?? this.currentQuery,
      genre: clearGenre ? null : (genre ?? this.genre),
      format: clearFormat ? null : (format ?? this.format),
      sort: clearSortAndStatus ? null : (sort ?? this.sort),
      status: clearSortAndStatus ? null : (status ?? this.status),
      customLabel: clearSortAndStatus
          ? null
          : (customLabel ?? this.customLabel),
    );
  }
}

class SearchNotifier extends Notifier<SearchState> {
  @override
  SearchState build() {
    return SearchState(searchResults: [], isLoading: false, currentQuery: "");
  }

  // Setters for UI
  void setQuery(String query) => _triggerSearch(query: query);

  void setFilter({String? genre, String? format}) =>
      _triggerSearch(genre: genre, format: format);

  void setCategoryMode(String sort, String? status, String label) =>
      _triggerSearch(
        sort: sort,
        status: status,
        customLabel: label,
        clearQuery: true,
      );

  void removeGenre() => _triggerSearch(clearGenre: true);
  void removeFormat() => _triggerSearch(clearFormat: true);
  void removeCategory() => _triggerSearch(clearSortAndStatus: true);

  Future<void> _triggerSearch({
    String? query,
    String? genre,
    String? format,
    String? sort,
    String? status,
    String? customLabel,
    bool clearGenre = false,
    bool clearFormat = false,
    bool clearSortAndStatus = false,
    bool clearQuery = false,
  }) async {
    state = state.copyWith(
      isLoading: true,
      currentQuery: clearQuery ? "" : (query ?? state.currentQuery),
      genre: genre,
      format: format,
      sort: sort,
      status: status,
      customLabel: customLabel,
      clearGenre: clearGenre,
      clearFormat: clearFormat,
      clearSortAndStatus: clearSortAndStatus,
    );

    try {
      const graphQLQuery = '''
        query (\$search: String, \$genre: String, \$format: MediaFormat, \$sort: [MediaSort], \$status: MediaStatus) {
          Page(page: 1, perPage: 24) {
            media(search: \$search, type: ANIME, genre: \$genre, format: \$format, sort: \$sort, status: \$status) {
              id title { english romaji native } coverImage { extraLarge medium large } bannerImage genres averageScore format episodes seasonYear
            }
          }
        }
      ''';

      Map<String, dynamic> variables = {};

      if (state.currentQuery.trim().isNotEmpty) {
        variables['search'] = state.currentQuery.trim();
      }
      if (state.genre != null) {
        variables['genre'] = state.genre;
      }
      if (state.format != null) {
        variables['format'] = state.format;
      }
      if (state.status != null) {
        variables['status'] = state.status;
      }

      List<String> sortList = [];
      if (state.sort != null) {
        sortList.add(state.sort!);
      } else if (state.currentQuery.trim().isNotEmpty) {
        sortList.add("SEARCH_MATCH");
      } else {
        sortList.add("TRENDING_DESC"); // Default when nothing is selected
      }
      variables['sort'] = sortList;

      final response = await http.post(
        Uri.parse('https://graphql.anilist.co'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'query': graphQLQuery, 'variables': variables}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        final List<dynamic> animeData = data['Page']['media'];
        state = state.copyWith(
          searchResults: animeData.map((j) => Anime.fromJson(j)).toList(),
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false, searchResults: []);
      }
    } catch (e) {
      debugPrint("Search error: $e");
      state = state.copyWith(isLoading: false, searchResults: []);
    }
  }
}

final searchProvider = NotifierProvider<SearchNotifier, SearchState>(
  () => SearchNotifier(),
);
