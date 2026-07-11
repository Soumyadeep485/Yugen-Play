import 'package:flutter/material.dart';
import 'dart:async';
import '../../shared/models/anime.dart';
import 'data/search_repository.dart';
import '../../core/colors/app_colors.dart';
import 'widgets/search_result_title.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final SearchRepository repository = SearchRepository();

  List<String> recentSearches = [];

  final TextEditingController searchController = TextEditingController();

  Timer? _debounce;

  List<Anime> searchResults = [];

  bool isLoading = false;

  String? error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    // recentSearches = await historyService.getHistory();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _searchAnime() async {
    final query = searchController.text.trim();

    if (query.length < 2) {
      setState(() {
        searchResults.clear();
        error = null;
        isLoading = false;
      });
      return;
    }

    if (query.isEmpty) {
      setState(() {
        searchResults = [];
        error = null;
      });
      return;
    }
    // await historyService.saveSearch(query);

    await _loadHistory();
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final results = await repository.searchAnime(query);

      if (!mounted) return;

      setState(() {
        searchResults = results;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 64,
                color: Colors.white38,
              ),

              const SizedBox(height: 20),

              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),

              const SizedBox(height: 20),

              FilledButton.icon(
                onPressed: _searchAnime,
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    if (searchController.text.trim().isEmpty) {
      if (recentSearches.isEmpty) {
        return const Center(
          child: Text(
            "Search your favourite anime",
            style: TextStyle(color: Colors.white70),
          ),
        );
      }

      return ListView(
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              "Recent Searches",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          ...recentSearches.map(
            (query) => ListTile(
              leading: const Icon(Icons.history, color: Colors.white54),
              title: Text(query, style: const TextStyle(color: Colors.white)),
              onTap: () {
                searchController.text = query;
                _searchAnime();
              },
            ),
          ),
        ],
      );
    }

    if (searchResults.isEmpty) {
      return const Center(
        child: Text("No anime found.", style: TextStyle(color: Colors.white54)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 8),
      itemCount: searchResults.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return SearchResultTile(anime: searchResults[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Search"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: searchController,

              textInputAction: TextInputAction.search,

              onChanged: (value) {
                if (_debounce?.isActive ?? false) {
                  _debounce!.cancel();
                }

                _debounce = Timer(
                  const Duration(milliseconds: 500),
                  _searchAnime,
                );

                setState(() {});
              },

              style: const TextStyle(color: Colors.white),

              decoration: InputDecoration(
                hintText: "Search anime...",

                prefixIcon: const Icon(Icons.search),

                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _debounce?.cancel();

                          searchController.clear();

                          setState(() {
                            searchResults.clear();
                            error = null;
                          });
                        },
                        icon: const Icon(Icons.close),
                      ),

                filled: true,

                fillColor: const Color(0xFF1A1A1D),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }
}
