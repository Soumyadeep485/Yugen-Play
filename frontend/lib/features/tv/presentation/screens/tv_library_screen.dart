import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../shared/models/anime.dart';
import '../../../tv/presentation/screens/tv_anime_details_screen.dart';

class TvLibraryScreen extends StatefulWidget {
  const TvLibraryScreen({super.key});

  @override
  State<TvLibraryScreen> createState() => _TvLibraryScreenState();
}

class _TvLibraryScreenState extends State<TvLibraryScreen> {
  int _selectedTabIndex = 0;

  final List<Map<String, dynamic>> _tabs = [
    {'label': 'All', 'icon': Icons.video_library_rounded},
    {'label': 'Watching', 'icon': Icons.play_circle_outline_rounded},
    {'label': 'Plan to Watch', 'icon': Icons.bookmark_border_rounded},
    {'label': 'Completed', 'icon': Icons.check_circle_outline_rounded},
    {'label': 'Dropped', 'icon': Icons.delete_outline_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final currentStatusFilter = _tabs[_selectedTabIndex]['label'] as String;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0E13), 
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================================================================
            // 1. LEFT SIDEBAR
            // ================================================================
            Container(
              width: 280,
              padding: const EdgeInsets.only(top: 32, left: 32, right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shelves, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Library",
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _tabs.asMap().entries.map((entry) {
                          int index = entry.key;
                          var tab = entry.value;
                          return _TvLibrarySidebarItem(
                            icon: tab['icon'],
                            label: tab['label'],
                            isSelected: _selectedTabIndex == index,
                            onTap: () {
                              setState(() => _selectedTabIndex = index);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ================================================================
            // 2. RIGHT GRID (Now completely reactive)
            // ================================================================
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Hive.box<String>('anime_library').listenable(),
                builder: (context, box, child) {
                  // Decode JSON dynamically
                  final allItems = box.values
                      .map((e) => jsonDecode(e) as Map<String, dynamic>)
                      .toList();

                  final filteredItems = currentStatusFilter == 'All'
                      ? allItems
                      : allItems.where((item) => item['status'] == currentStatusFilter).toList();

                  if (filteredItems.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open_rounded, size: 64, color: Colors.white.withValues(alpha: 0.1)),
                          const SizedBox(height: 16),
                          Text(
                            "No anime found in $currentStatusFilter",
                            style: const TextStyle(color: Colors.white54, fontSize: 18),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.only(top: 32, left: 16, right: 40, bottom: 60),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 24,
                    ),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      
                      final reconstructedAnime = Anime(
                        id: item['animeId']?.toString() ?? '',
                        title: item['title'] ?? 'Unknown',
                        coverImage: item['posterUrl'] ?? '',
                        bannerImage: item['posterUrl'] ?? '', 
                        status: item['status'] ?? '',
                      );

                      return _TvLibraryPosterCard(
                        anime: reconstructedAnime,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TvAnimeDetailsScreen(anime: reconstructedAnime),
                            ),
                          );
                        },
                      );
                    },
                  );
                }
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// TV LIBRARY HELPER WIDGETS
// ============================================================================

class _TvLibrarySidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TvLibrarySidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TvLibrarySidebarItem> createState() => _TvLibrarySidebarItemState();
}

class _TvLibrarySidebarItemState extends State<_TvLibrarySidebarItem> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final bool showAsActive = widget.isSelected;
    
    Color bgColor = Colors.transparent;
    if (showAsActive) {
      bgColor = Colors.white;
    } else if (_isFocused) {
      bgColor = Colors.white.withValues(alpha: 0.1);
    }

    Color contentColor = showAsActive ? Colors.black : (_isFocused ? Colors.white : Colors.white70);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onFocusChange: (focused) => setState(() => _isFocused = focused),
          borderRadius: BorderRadius.circular(32),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: _isFocused && !showAsActive ? Colors.white38 : Colors.transparent, 
                width: 1.5
              ),
              boxShadow: showAsActive 
                  ? [BoxShadow(color: Colors.white.withValues(alpha: 0.2), blurRadius: 12)] 
                  : [],
            ),
            child: Row(
              children: [
                Icon(widget.icon, color: contentColor, size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: contentColor,
                      fontSize: 16,
                      fontWeight: showAsActive ? FontWeight.bold : FontWeight.w600,
                    ),
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

class _TvLibraryPosterCard extends StatefulWidget {
  final Anime anime;
  final VoidCallback onTap;

  const _TvLibraryPosterCard({required this.anime, required this.onTap});

  @override
  State<_TvLibraryPosterCard> createState() => _TvLibraryPosterCardState();
}

class _TvLibraryPosterCardState extends State<_TvLibraryPosterCard> {
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
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutQuart,
          transform: Matrix4.diagonal3Values(_isFocused ? 1.08 : 1.0, _isFocused ? 1.08 : 1.0, 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isFocused ? Colors.white : Colors.transparent, 
              width: _isFocused ? 3 : 0
            ),
            boxShadow: _isFocused 
                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.6), blurRadius: 20, spreadRadius: 4)] 
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
                      begin: Alignment.topCenter, 
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.9)],
                      stops: const [0.6, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10, left: 10, right: 10,
                  child: Text(
                    widget.anime.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _isFocused ? Colors.white : Colors.white70, 
                      fontSize: 12, 
                      fontWeight: FontWeight.bold
                    ),
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