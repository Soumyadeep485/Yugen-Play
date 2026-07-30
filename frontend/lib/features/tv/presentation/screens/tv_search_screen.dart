import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../shared/models/anime.dart';
import '../../../search/controllers/search_provider.dart';
import '../../../search/services/search_history_service.dart';
import 'tv_anime_details_screen.dart';

class TvSearchScreen extends ConsumerStatefulWidget {
  const TvSearchScreen({super.key});

  @override
  ConsumerState<TvSearchScreen> createState() => _TvSearchScreenState();
}

class _TvSearchScreenState extends ConsumerState<TvSearchScreen> {
  final SearchHistoryService _historyService = SearchHistoryService();
  String _searchQuery = "";
  Timer? _debounceTimer;

  final List<String> _alphabetKeys = [
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
    'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _searchQuery = ref.read(searchProvider).currentQuery;
      });
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onKeyPressed(String key) {
    setState(() => _searchQuery += key);
    _triggerLiveSearch();
  }

  void _onBackspace() {
    if (_searchQuery.isNotEmpty) {
      setState(() => _searchQuery = _searchQuery.substring(0, _searchQuery.length - 1));
      _triggerLiveSearch();
    }
  }

  void _onClear() {
    setState(() => _searchQuery = "");
    ref.read(searchProvider.notifier).setQuery("");
  }

  void _onSpace() {
    setState(() => _searchQuery += " ");
  }

  void _triggerLiveSearch() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      if (_searchQuery.trim().isNotEmpty) {
        _historyService.addSearch(_searchQuery.trim());
        ref.read(searchProvider.notifier).setQuery(_searchQuery.trim());
      } else {
        ref.read(searchProvider.notifier).setQuery("");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final isQueryEmpty = searchState.currentQuery.trim().isEmpty && _searchQuery.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0E13), 
      body: SafeArea(
        // 🚀 CHANGED: Now using a CustomScrollView so the keyboard scrolls UP and away!
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ================================================================
            // TOP SECTION: Header, Keyboard, and Auto-Complete Chips
            // ================================================================
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  
                  // 1. M3 LARGE SEARCH HEADER
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: _searchQuery.isEmpty ? Colors.white38 : AppColors.primary,
                          size: 38,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _searchQuery.isEmpty ? "Shows, Movies, and More" : _searchQuery,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _searchQuery.isEmpty ? Colors.white38 : Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          Container(width: 3, height: 32, color: AppColors.primary),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. M3 SINGLE-ROW KEYBOARD
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Row(
                      children: [
                        _M3KeyPill(label: "123", width: 42, onTap: () {}),
                        const SizedBox(width: 6),
                        _M3KeyPill(label: "SPACE", width: 62, onTap: _onSpace),
                        const SizedBox(width: 6),
                        ..._alphabetKeys.map((key) => Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: _M3AlphaKey(label: key, onTap: () => _onKeyPressed(key)),
                        )),
                        const SizedBox(width: 2),
                        _M3KeyPill(icon: Icons.backspace_rounded, width: 44, onTap: _onBackspace),
                        const SizedBox(width: 6),
                        _M3KeyPill(icon: Icons.close_rounded, width: 44, onTap: _onClear),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. SMART AUTO-COMPLETE CHIPS
                  if (_searchQuery.isNotEmpty)
                    _buildDynamicSuggestions(searchState.searchResults),

                  const SizedBox(height: 24),
                ],
              ),
            ),

            // ================================================================
            // BOTTOM SECTION: Results (Automatically pushes keyboard up on focus)
            // ================================================================
            if (searchState.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else if (isQueryEmpty)
              SliverToBoxAdapter(child: _buildRecentSearches())
            else if (searchState.searchResults.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Text("No results found.", style: TextStyle(color: Colors.white54, fontSize: 18))),
              )
            else
              ..._buildSliverSearchResults(searchState.searchResults),
          ],
        ),
      ),
    );
  }

  // 🚀 NEW: Smart Auto-Complete Logic based on actual Anime Titles!
  Widget _buildDynamicSuggestions(List<Anime> results) {
    // Grab the top 4 search results to use as smart suggestions
    List<Anime> topMatches = results.take(4).toList();

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        physics: const BouncingScrollPhysics(),
        children: [
          _M3SuggestionChip(
            prefix: 'Q',
            text: '"$_searchQuery"',
            isSearchQuery: true,
            onTap: () {},
          ),
          if (topMatches.isNotEmpty) const SizedBox(width: 10),
          
          // Map real anime titles to the suggestion chips
          ...topMatches.map((anime) {
            final title = anime.title;
            String lowerQuery = _searchQuery.toLowerCase();
            String lowerTitle = title.toLowerCase();
            
            String prefix = "";
            String suffix = title;

            // Highlight the typed part of the word
            if (lowerTitle.startsWith(lowerQuery)) {
              prefix = title.substring(0, _searchQuery.length);
              suffix = title.substring(_searchQuery.length);
            }

            return Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: _M3SuggestionChip(
                prefix: prefix,
                text: suffix,
                onTap: () {
                  setState(() => _searchQuery = title);
                  _triggerLiveSearch();
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<String>('search_history').listenable(),
      builder: (context, box, child) {
        final history = _historyService.getHistory();
        if (history.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 100.0),
              child: Text(
                "Type using the keyboard above to find anime...",
                style: TextStyle(color: Colors.white38, fontSize: 16),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Recent Searches", style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => _historyService.clearAll(),
                    child: const Text("Clear All", style: TextStyle(color: Colors.white38, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: history.map((query) => _M3HistoryChip(
                  query: query,
                  onTap: () {
                    setState(() => _searchQuery = query);
                    _triggerLiveSearch();
                  },
                )).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🚀 CHANGED: Converted the results section into Slivers for seamless scrolling
  List<Widget> _buildSliverSearchResults(List<Anime> results) {
    final topResults = results.take(3).toList();
    final remainingResults = results.skip(3).toList();

    return [
      // Top Results Row
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Top Results", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              SizedBox(
                height: 110,
                child: Row(
                  children: topResults.map((anime) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: _M3TopResultCard(anime: anime),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),

      // Anime Matches Header
      if (remainingResults.isNotEmpty)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Anime Matches", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 14),
              ],
            ),
          ),
        ),

      // Anime Matches Grid
      if (remainingResults.isNotEmpty)
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0).copyWith(bottom: 60),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              childAspectRatio: 0.65,
              crossAxisSpacing: 16,
              mainAxisSpacing: 20,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _M3PosterCard(anime: remainingResults[index]);
              },
              childCount: remainingResults.length,
            ),
          ),
        ),
    ];
  }
}

// ============================================================================
// MATERIAL 3 LOW-RESOURCE TV KEYBOARD WIDGETS
// ============================================================================

class _M3AlphaKey extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _M3AlphaKey({required this.label, required this.onTap});

  @override
  State<_M3AlphaKey> createState() => _M3AlphaKeyState();
}

class _M3AlphaKeyState extends State<_M3AlphaKey> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 36,
          height: 38,
          transform: Matrix4.diagonal3Values(_isFocused ? 1.15 : 1.0, _isFocused ? 1.15 : 1.0, 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: _isFocused ? Colors.white : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            boxShadow: _isFocused
                ? [BoxShadow(color: Colors.white.withValues(alpha: 0.4), blurRadius: 10, spreadRadius: 1)]
                : [],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                color: _isFocused ? Colors.black : Colors.white70,
                fontSize: 18,
                fontWeight: _isFocused ? FontWeight.w900 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _M3KeyPill extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final double width;
  final VoidCallback onTap;

  const _M3KeyPill({this.label, this.icon, required this.width, required this.onTap});

  @override
  State<_M3KeyPill> createState() => _M3KeyPillState();
}

class _M3KeyPillState extends State<_M3KeyPill> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: widget.width,
          height: 38,
          transform: Matrix4.diagonal3Values(_isFocused ? 1.1 : 1.0, _isFocused ? 1.1 : 1.0, 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: _isFocused ? Colors.white : Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            boxShadow: _isFocused
                ? [BoxShadow(color: Colors.white.withValues(alpha: 0.4), blurRadius: 10)]
                : [],
          ),
          child: Center(
            child: widget.icon != null
                ? Icon(widget.icon, color: _isFocused ? Colors.black : Colors.white, size: 18)
                : Text(
                    widget.label!,
                    style: TextStyle(
                      color: _isFocused ? Colors.black : Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _M3SuggestionChip extends StatefulWidget {
  final String prefix;
  final String text;
  final bool isSearchQuery;
  final VoidCallback onTap;

  const _M3SuggestionChip({
    required this.prefix,
    required this.text,
    this.isSearchQuery = false,
    required this.onTap,
  });

  @override
  State<_M3SuggestionChip> createState() => _M3SuggestionChipState();
}

class _M3SuggestionChipState extends State<_M3SuggestionChip> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _isFocused
                ? Colors.white
                : (widget.isSearchQuery ? AppColors.primary.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.08)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isFocused ? Colors.white : (widget.isSearchQuery ? AppColors.primary : Colors.white10),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isSearchQuery)
                Icon(Icons.search_rounded, size: 16, color: _isFocused ? Colors.black : AppColors.primary),
              if (widget.isSearchQuery) const SizedBox(width: 6),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: widget.prefix,
                      style: TextStyle(
                        color: _isFocused ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    TextSpan(
                      text: widget.text,
                      style: TextStyle(
                        color: _isFocused ? Colors.black54 : Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _M3TopResultCard extends StatefulWidget {
  final Anime anime;
  const _M3TopResultCard({required this.anime});

  @override
  State<_M3TopResultCard> createState() => _M3TopResultCardState();
}

class _M3TopResultCardState extends State<_M3TopResultCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final poster = widget.anime.bannerImage ?? widget.anime.coverImage ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => TvAnimeDetailsScreen(anime: widget.anime)));
        },
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.diagonal3Values(_isFocused ? 1.04 : 1.0, _isFocused ? 1.04 : 1.0, 1.0),
          transformAlignment: Alignment.center,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _isFocused ? Colors.white.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isFocused ? Colors.white : Colors.white10,
              width: _isFocused ? 2 : 1,
            ),
            boxShadow: _isFocused
                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 16)]
                : [],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    poster,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[900]),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.anime.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.anime.status ?? "Anime Series",
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _M3PosterCard extends StatefulWidget {
  final Anime anime;
  const _M3PosterCard({required this.anime});

  @override
  State<_M3PosterCard> createState() => _M3PosterCardState();
}

class _M3PosterCardState extends State<_M3PosterCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final score = widget.anime.rating != null ? "★ ${widget.anime.rating!.toStringAsFixed(1)}" : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => TvAnimeDetailsScreen(anime: widget.anime)));
        },
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutQuart,
          transform: Matrix4.diagonal3Values(_isFocused ? 1.08 : 1.0, _isFocused ? 1.08 : 1.0, 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _isFocused ? Colors.white : Colors.transparent, width: _isFocused ? 3 : 0),
            boxShadow: _isFocused
                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.8), blurRadius: 20, spreadRadius: 4)]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  widget.anime.coverImage ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[900]),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.9)],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
                if (score != null)
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: Text(score, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                Positioned(
                  bottom: 10, left: 10, right: 10,
                  child: Text(
                    widget.anime.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: _isFocused ? Colors.white : Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
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

class _M3HistoryChip extends StatefulWidget {
  final String query;
  final VoidCallback onTap;

  const _M3HistoryChip({required this.query, required this.onTap});

  @override
  State<_M3HistoryChip> createState() => _M3HistoryChipState();
}

class _M3HistoryChipState extends State<_M3HistoryChip> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.diagonal3Values(_isFocused ? 1.05 : 1.0, _isFocused ? 1.05 : 1.0, 1.0),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: _isFocused ? Colors.white : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            boxShadow: _isFocused ? [BoxShadow(color: Colors.white.withValues(alpha: 0.3), blurRadius: 10)] : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded, color: _isFocused ? Colors.black : Colors.white54, size: 16),
              const SizedBox(width: 8),
              Text(widget.query, style: TextStyle(color: _isFocused ? Colors.black : Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}