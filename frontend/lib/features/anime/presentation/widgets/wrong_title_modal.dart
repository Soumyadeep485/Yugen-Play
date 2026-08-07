import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/radius/app_radius.dart';

Future<void> showWrongTitleModal<T>({
  required BuildContext context,
  required String initialText,
  required String mediaId,
  required String sourceName,
  required Future<List<T>> Function(String) searchExtension,
  required String Function(T) getTitle,
  required String Function(T) getPoster,
  required String Function(T) getUrl,
  required Function(T) onBind,
}) async {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (BuildContext context) {
      return _WrongTitleModalContent<T>(
        initialText: initialText,
        sourceName: sourceName,
        searchExtension: searchExtension,
        getTitle: getTitle,
        getPoster: getPoster,
        getUrl: getUrl,
        onBind: onBind,
      );
    },
  );
}

class _WrongTitleModalContent<T> extends StatefulWidget {
  final String initialText;
  final String sourceName;
  final Future<List<T>> Function(String) searchExtension;
  final String Function(T) getTitle;
  final String Function(T) getPoster;
  final String Function(T) getUrl;
  final Function(T) onBind;

  const _WrongTitleModalContent({
    required this.initialText,
    required this.sourceName,
    required this.searchExtension,
    required this.getTitle,
    required this.getPoster,
    required this.getUrl,
    required this.onBind,
  });

  @override
  State<_WrongTitleModalContent<T>> createState() => _WrongTitleModalContentState<T>();
}

class _WrongTitleModalContentState<T> extends State<_WrongTitleModalContent<T>> {
  late TextEditingController _searchController;
  List<T> _results = [];
  bool _isLoading = false;
  bool _isSearchBtnFocused = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialText);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performSearch(widget.initialText);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _results = [];
    });

    try {
      final results = await widget.searchExtension(query);
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Search Extension Error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.85,
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              'Select Correct Title',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    onSubmitted: _performSearch,
                    decoration: InputDecoration(
                      hintText: 'Search franchise...',
                      hintStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 🚀 TV FOCUS FIX FOR SEARCH BUTTON
                Focus(
                  onFocusChange: (focused) => setState(() => _isSearchBtnFocused = focused),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      onTap: () => _performSearch(_searchController.text),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isSearchBtnFocused ? AppColors.primary.withValues(alpha: 0.8) : AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: _isSearchBtnFocused ? Colors.white : Colors.transparent,
                            width: _isSearchBtnFocused ? 2 : 0,
                          ),
                          boxShadow: _isSearchBtnFocused ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 8)] : [],
                        ),
                        child: const Icon(Icons.search, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text("Searching...", style: TextStyle(color: Colors.white70))
                      ],
                    ),
                  )
                : _results.isEmpty
                    ? const Center(
                        child: Text(
                          'No results found.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        itemCount: _results.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _results[index];
                          final title = widget.getTitle(item);
                          final poster = widget.getPoster(item);

                          // 🚀 EXTRACTED TO ITS OWN STATEFUL WIDGET FOR FOCUS HANDLING
                          return _SearchResultItemCard(
                            title: title,
                            poster: poster,
                            sourceName: widget.sourceName,
                            onTap: () {
                              widget.onBind(item);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// 🚀 TV FOCUS FIX FOR RESULT ITEMS
class _SearchResultItemCard extends StatefulWidget {
  final String title;
  final String poster;
  final String sourceName;
  final VoidCallback onTap;

  const _SearchResultItemCard({
    required this.title,
    required this.poster,
    required this.sourceName,
    required this.onTap,
  });

  @override
  State<_SearchResultItemCard> createState() => _SearchResultItemCardState();
}

class _SearchResultItemCardState extends State<_SearchResultItemCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isFocused ? AppColors.primary.withValues(alpha: 0.15) : AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: _isFocused ? Colors.white : Colors.white10,
                width: _isFocused ? 2.0 : 1.0,
              ),
              boxShadow: _isFocused ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10)] : [],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: CachedNetworkImage(
                    imageUrl: widget.poster.isNotEmpty ? widget.poster : 'https://via.placeholder.com/70x100',
                    width: 70,
                    height: 100,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      width: 70,
                      height: 100,
                      color: Colors.white10,
                      child: const Icon(Icons.broken_image, color: Colors.white54),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: _isFocused ? Colors.white : AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.sourceName,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}