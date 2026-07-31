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

  // A proper QWERTY layout for D-Pad navigation
  final List<List<String>> _qwertyLayout = [
    ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
    ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
    ['z', 'x', 'c', 'v', 'b', 'n', 'm'],
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

  void _onKeyPressed(String key) {
    setState(() => _searchQuery += key);
  }

  void _onBackspace() {
    if (_searchQuery.isNotEmpty) {
      setState(() => _searchQuery = _searchQuery.substring(0, _searchQuery.length - 1));
    }
  }

  void _onClear() {
    setState(() => _searchQuery = "");
    ref.read(searchProvider.notifier).setQuery("");
  }

  void _onSpace() {
    setState(() => _searchQuery += " ");
  }

  void _performSearch() {
    final query = _searchQuery.trim();
    if (query.isNotEmpty) {
      _historyService.addSearch(query);
      ref.read(searchProvider.notifier).setQuery(query);
    } else {
      ref.read(searchProvider.notifier).setQuery("");
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final isQueryEmpty = searchState.currentQuery.trim().isEmpty && _searchQuery.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0E13), 
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ================================================================
            // TOP SECTION: Header & Structured QWERTY Keyboard
            // ================================================================
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  
                  // 1. SEARCH HEADER
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

                  const SizedBox(height: 30),

                  // 2. PROPER QWERTY TV KEYBOARD
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1
                        Row(
                          children: [
                            ..._qwertyLayout[0].map((key) => Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: _M3AlphaKey(label: key, onTap: () => _onKeyPressed(key)),
                            )),
                            const SizedBox(width: 8),
                            _M3KeyPill(icon: Icons.backspace_rounded, width: 50, onTap: _onBackspace),
                          ],
                        ),
                        const SizedBox(height: 6),
                        
                        // Row 2
                        Row(
                          children: [
                            const SizedBox(width: 16),
                            ..._qwertyLayout[1].map((key) => Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: _M3AlphaKey(label: key, onTap: () => _onKeyPressed(key)),
                            )),
                            const SizedBox(width: 8),
                            _M3KeyPill(icon: Icons.close_rounded, width: 50, onTap: _onClear),
                          ],
                        ),
                        const SizedBox(height: 6),
                        
                        // Row 3 (Bottom Actions)
                        Row(
                          children: [
                            const SizedBox(width: 32),
                            ..._qwertyLayout[2].map((key) => Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: _M3AlphaKey(label: key, onTap: () => _onKeyPressed(key)),
                            )),
                            const SizedBox(width: 8),
                            _M3KeyPill(label: "SPACE", width: 80, onTap: _onSpace),
                            const SizedBox(width: 8),
                            
                            _M3KeyPill(
                              label: "SEARCH", 
                              width: 100, 
                              isPrimary: true,
                              icon: Icons.search_rounded,
                              onTap: _performSearch,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),

            // ================================================================
            // BOTTOM SECTION: Results / History
            // ================================================================
            if (searchState.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else if (isQueryEmpty || searchState.currentQuery.isEmpty)
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

  Widget _buildRecentSearches() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<String>('search_history').listenable(),
      builder: (context, box, child) {
        final history = _historyService.getHistory();
        if (history.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 80.0),
              child: Text(
                "Type and press SEARCH to find anime...",
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
                    _performSearch();
                  },
                )).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🚀 REPLACED: Unified Grid for AniList Cards
  List<Widget> _buildSliverSearchResults(List<Anime> results) {
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0).copyWith(bottom: 60),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 Wide cards per row
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            mainAxisExtent: 220, // Forces strict card height
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return _TvAniListSearchCard(
                anime: results[index],
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => TvAnimeDetailsScreen(anime: results[index])));
                },
              );
            },
            childCount: results.length,
          ),
        ),
      ),
    ];
  }
}

// ============================================================================
// WIDGETS
// ============================================================================

class _TvAniListSearchCard extends StatefulWidget {
  final Anime anime;
  final VoidCallback onTap;

  const _TvAniListSearchCard({required this.anime, required this.onTap});

  @override
  State<_TvAniListSearchCard> createState() => _TvAniListSearchCardState();
}

class _TvAniListSearchCardState extends State<_TvAniListSearchCard> {
  bool _isFocused = false;

  String _cleanDescription(String? html) {
    if (html == null) return 'No description available.';
    return html.replaceAll(RegExp(r'<[^>]*>|&[a-zA-Z0-9]+;'), '').trim();
  }

  @override
  Widget build(BuildContext context) {
    // Fallbacks for formatting
    final formatStr = widget.anime.format != null ? widget.anime.format!.replaceAll('_', ' ') : 'TV';
    final epStr = widget.anime.episodes != null ? '${widget.anime.episodes} episodes' : '? episodes';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: const Color(0xFF151F2E), // AniList Dark Slate Background
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isFocused ? Colors.white : Colors.transparent,
              width: _isFocused ? 2 : 1,
            ),
            boxShadow: _isFocused
                ? [BoxShadow(color: Colors.white.withValues(alpha: 0.15), blurRadius: 15, spreadRadius: 2)]
                : [],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Poster Image
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                child: Image.network(
                  widget.anime.coverImage ?? '',
                  width: 150,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 150,
                    color: Colors.white10,
                    child: const Icon(Icons.broken_image, color: Colors.white54),
                  ),
                ),
              ),
              // 2. Metadata
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Rating Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.anime.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _isFocused ? Colors.white : const Color(0xFF9FADBD),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (widget.anime.rating != null) ...[
                            const SizedBox(width: 8),
                            Row(
                              children: [
                                const Icon(Icons.mood, color: Colors.greenAccent, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.anime.rating!.toInt()}%',
                                  style: const TextStyle(
                                    color: Colors.greenAccent, 
                                    fontSize: 13, 
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      // Format & Episode Count
                      Text(
                        '$formatStr • $epStr',
                        style: const TextStyle(color: Color(0xFF8BA0B2), fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      
                      // Description Block
                      Expanded(
                        child: Text(
                          _cleanDescription(widget.anime.description),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF6A7685), fontSize: 12, height: 1.4),
                        ),
                      ),
                      
                      // Genre Pills
                      if (widget.anime.genres != null && widget.anime.genres!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: widget.anime.genres!.take(3).map((genre) {
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _isFocused ? Colors.blueAccent : const Color(0xFF3DB4F2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  genre.toLowerCase(),
                                  style: const TextStyle(
                                    color: Colors.white, 
                                    fontSize: 10, 
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        )
                      ]
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

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
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 40,
          height: 42,
          transform: Matrix4.diagonal3Values(_isFocused ? 1.15 : 1.0, _isFocused ? 1.15 : 1.0, 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: _isFocused ? Colors.white : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            boxShadow: _isFocused
                ? [BoxShadow(color: Colors.white.withValues(alpha: 0.4), blurRadius: 10, spreadRadius: 1)]
                : [],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                color: _isFocused ? Colors.black : Colors.white70,
                fontSize: 20,
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
  final bool isPrimary; 

  const _M3KeyPill({this.label, this.icon, required this.width, required this.onTap, this.isPrimary = false});

  @override
  State<_M3KeyPill> createState() => _M3KeyPillState();
}

class _M3KeyPillState extends State<_M3KeyPill> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isPrimary ? AppColors.primary.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.12);
    final focusColor = widget.isPrimary ? AppColors.primary : Colors.white;
    final textColor = widget.isPrimary ? Colors.white : Colors.white70;
    final focusTextColor = widget.isPrimary ? Colors.white : Colors.black;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: widget.width,
          height: 42,
          transform: Matrix4.diagonal3Values(_isFocused ? 1.1 : 1.0, _isFocused ? 1.1 : 1.0, 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: _isFocused ? focusColor : baseColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: _isFocused
                ? [BoxShadow(color: focusColor.withValues(alpha: 0.5), blurRadius: 10)]
                : [],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null)
                  Icon(widget.icon, color: _isFocused ? focusTextColor : textColor, size: 18),
                if (widget.icon != null && widget.label != null)
                  const SizedBox(width: 4),
                if (widget.label != null)
                  Text(
                    widget.label!,
                    style: TextStyle(
                      color: _isFocused ? focusTextColor : textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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