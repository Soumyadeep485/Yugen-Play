import 'package:flutter/material.dart';
import 'dart:async';
import '../../shared/models/anime.dart';
import 'data/search_repository.dart';
import '../../core/colors/app_colors.dart';
import 'widgets/search_result_title.dart';
import 'widgets/trending_searches.dart';
import 'widgets/recent_searches.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final SearchRepository repository = SearchRepository();
  final TextEditingController searchController = TextEditingController();

  Timer? _debounce;
  List<Anime> searchResults = [];
  bool isLoading = false;
  String? error;

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
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

  /// The unified state machine for the search content area
  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        key: ValueKey('loadingState'),
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (error != null) {
      return Center(
        key: const ValueKey('errorState'),
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
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (searchController.text.trim().isEmpty) {
      // Fluidly present the idle widgets you previously created but ignored
      return ListView(
        key: const ValueKey('idleState'),
        padding: const EdgeInsets.only(top: 12),
        children: const [
          TrendingSearches(),
          SizedBox(height: 32),
          RecentSearches(),
        ],
      );
    }

    if (searchResults.isEmpty) {
      return const Center(
        key: ValueKey('emptyState'),
        child: Text(
          "No anime found.",
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }

    return ListView.separated(
      key: const ValueKey('resultsState'),
      padding: const EdgeInsets.only(top: 12),
      itemCount: searchResults.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, color: Colors.white10),
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
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 8),
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
                // Trigger an immediate rebuild to handle the empty state swap
                setState(() {});
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search anime...",
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
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
                        icon: const Icon(Icons.close, color: Colors.white54),
                      ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              // The Saikou-style smooth transition wrapper
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
