import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../details/presentation/screens/anime_details_screen.dart';
// Adjusted relative imports based on the modern architecture tree
import '../../../home/presentation/widgets/anime_card.dart';
import '../../controllers/search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final bool autofocus;

  const SearchScreen({super.key, this.autofocus = false});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchController.text = ref.read(searchProvider).currentQuery;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterModal(BuildContext context, SearchState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.65,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(
                alpha: 0.9,
              ), // Fixed hardcoded 0xFF0A0A0F
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              border: Border(
                top: BorderSide(
                  color: AppColors.textPrimary.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: _FilterModalContent(currentState: state),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(
                  alpha: 0.15,
                ), // Fixed rogue purple hex
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Glassy Search Bar
                Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 20,
                    bottom: 12,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: TextField(
                        controller: _searchController,
                        autofocus: widget.autofocus,
                        style: const TextStyle(
                          color: AppColors.textPrimary, // Fixed
                          fontSize: 16,
                        ),
                        onSubmitted: (value) =>
                            ref.read(searchProvider.notifier).setQuery(value),
                        decoration: InputDecoration(
                          hintText: "Search anime...",
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.6,
                            ), // Fixed
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.textSecondary,
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_searchController.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    color: AppColors.textSecondary,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref
                                        .read(searchProvider.notifier)
                                        .setQuery("");
                                  },
                                ),
                              IconButton(
                                icon: Icon(
                                  Icons.tune_rounded,
                                  color:
                                      (searchState.genre != null ||
                                          searchState.format != null)
                                      ? AppColors
                                            .primary // Fixed
                                      : AppColors.textSecondary,
                                ),
                                onPressed: () =>
                                    _showFilterModal(context, searchState),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                          filled: true,
                          fillColor: AppColors.textPrimary.withValues(
                            alpha: 0.08,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color: AppColors.primary, // Fixed
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Active Filter Chips
                if (searchState.customLabel != null ||
                    searchState.genre != null ||
                    searchState.format != null)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        if (searchState.customLabel != null)
                          _buildActiveChip(
                            searchState.customLabel!,
                            () => ref
                                .read(searchProvider.notifier)
                                .removeCategory(),
                          ),
                        if (searchState.format != null)
                          _buildActiveChip(
                            searchState.format!,
                            () => ref
                                .read(searchProvider.notifier)
                                .removeFormat(),
                          ),
                        if (searchState.genre != null)
                          _buildActiveChip(
                            searchState.genre!,
                            () =>
                                ref.read(searchProvider.notifier).removeGenre(),
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),

                // Results Grid
                Expanded(
                  child: searchState.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary, // Fixed
                          ),
                        )
                      : searchState.searchResults.isEmpty
                      ? const Center(
                          child: Text(
                            "No results found.",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.only(
                            left: 20,
                            right: 20,
                            bottom: 140,
                            top: 10,
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 0.55,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: searchState.searchResults.length,
                          itemBuilder: (context, index) {
                            final anime = searchState.searchResults[index];
                            return AnimeCard(
                              anime: anime,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AnimeDetailsScreen(anime: anime),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.2), // Fixed
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.5), // Fixed
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary, // Fixed
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: AppColors.primary, // Fixed
            ),
          ),
        ],
      ),
    );
  }
}

// Modal Content extracted for state management
class _FilterModalContent extends ConsumerStatefulWidget {
  final SearchState currentState;
  const _FilterModalContent({required this.currentState});

  @override
  ConsumerState<_FilterModalContent> createState() =>
      _FilterModalContentState();
}

class _FilterModalContentState extends ConsumerState<_FilterModalContent> {
  String? _selectedFormat;
  String? _selectedGenre;

  @override
  void initState() {
    super.initState();
    _selectedFormat = widget.currentState.format;
    _selectedGenre = widget.currentState.genre;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.5), // Fixed
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          "Filters",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),

        _buildFilterSection(
          "Format",
          ["TV", "MOVIE", "OVA", "SPECIAL"],
          _selectedFormat,
          (val) {
            setState(
              () => _selectedFormat = _selectedFormat == val ? null : val,
            );
          },
        ),
        const SizedBox(height: 20),
        _buildFilterSection(
          "Genres",
          [
            "Action",
            "Romance",
            "Sci-Fi",
            "Horror",
            "Comedy",
            "Fantasy",
            "Drama",
          ],
          _selectedGenre,
          (val) {
            setState(() => _selectedGenre = _selectedGenre == val ? null : val);
          },
        ),

        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, // Fixed
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {
              ref
                  .read(searchProvider.notifier)
                  .setFilter(genre: _selectedGenre, format: _selectedFormat);
              Navigator.pop(context);
            },
            child: const Text(
              "Apply Filters",
              style: TextStyle(
                color: Colors
                    .white, // Safe hardcode for contrast against primary button
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFilterSection(
    String title,
    List<String> options,
    String? selected,
    Function(String) onTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary, // Fixed
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((option) {
            bool isSelected = option == selected;
            return GestureDetector(
              onTap: () => onTap(option),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.2) // Fixed
                      : AppColors.textPrimary.withValues(alpha: 0.05), // Fixed
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors
                              .primary // Fixed
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors
                              .primary // Fixed
                        : AppColors.textSecondary, // Fixed
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
