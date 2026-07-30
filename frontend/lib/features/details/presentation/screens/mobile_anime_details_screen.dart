import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:frontend/features/library/presentation/widgets/library_status_sheet.dart';
import 'package:frontend/features/library/services/library_service.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../shared/models/anime.dart';
import '../widgets/info_tab.dart';
import '../widgets/watch_tab.dart';

class MobileAnimeDetailsScreen extends StatefulWidget {
  final Anime anime;

  const MobileAnimeDetailsScreen({super.key, required this.anime});

  @override
  State<MobileAnimeDetailsScreen> createState() => _AnimeDetailsScreenState();
}

class _AnimeDetailsScreenState extends State<MobileAnimeDetailsScreen> {
  final LibraryService _libraryService = LibraryService();
  String? _libraryStatus;
  
  // 0 = Info, 1 = Watch
  int _currentIndex = 0; 

  @override
  void initState() {
    super.initState();
    _libraryStatus = _libraryService.getAnimeStatus(widget.anime.id.toString());
  }

  void _showLibrarySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => LibraryStatusSheet(
        anime: widget.anime,
        initialStatus: _libraryStatus,
        onStatusUpdated: (newStatus) {
          if (!mounted) return;
          setState(() {
            _libraryStatus = newStatus;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(newStatus == null ? "Removed from Library" : "Moved to $newStatus"),
              backgroundColor: AppColors.card,
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 Fallback image priority: Banner -> Cover Image -> Empty
    final bgImageUrl = widget.anime.coverImage ?? widget.anime.bannerImage ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ==========================================
          // 1. FULLSCREEN BLURRED THUMBNAIL BACKDROP
          // ==========================================
          if (bgImageUrl.isNotEmpty)
            Positioned.fill(
              child: Image.network(
                bgImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: Colors.black),
              ),
            ),

          // Blur filter over the image
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
              child: Container(color: Colors.black.withValues(alpha: 0.3)),
            ),
          ),

          // Dark Vignette Gradient for High Contrast & Text Legibility
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.65),
                    Colors.black.withValues(alpha: 0.85),
                    Colors.black.withValues(alpha: 0.98),
                  ],
                  stops: const [0.0, 0.4, 0.9],
                ),
              ),
            ),
          ),

          // ==========================================
          // 2. SCROLLABLE MAIN CONTENT
          // ==========================================
          Positioned.fill(
            child: ListView(
              padding: EdgeInsets.only(
                top: MediaQuery.paddingOf(context).top + 60, 
                bottom: 120, 
              ),
              physics: const BouncingScrollPhysics(),
              children: [
                // --- POSTER AND TITLE HEADER ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.anime.coverImage ?? bgImageUrl,
                          width: 120,
                          height: 170,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 120, 
                            height: 170, 
                            color: AppColors.card,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              widget.anime.title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (widget.anime.status != null)
                              Text(
                                widget.anime.status!.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.blueAccent, 
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),

                // --- DYNAMIC TAB CONTENT ---
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _currentIndex == 0
                      ? InfoTab(
                          anime: widget.anime,
                          libraryStatus: _libraryStatus,
                          onLibraryTap: _showLibrarySheet,
                        )
                      : WatchTab(anime: widget.anime),
                ),
              ],
            ),
          ),

          // ==========================================
          // 3. TOP NAVIGATION BUTTONS (HOME & CLOSE)
          // ==========================================
          Positioned(
            top: MediaQuery.paddingOf(context).top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCircularButton(
                  icon: Icons.home_rounded,
                  onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
                ),
                _buildCircularButton(
                  icon: Icons.close_rounded,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // ==========================================
          // 4. FLOATING DARK GLASS NAVIGATION PILL
          // ==========================================
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                  child: Container(
                    height: 60,
                    width: 240, 
                    decoration: BoxDecoration(
                      // 🚀 High contrast dark glass ensures absolute visibility
                      color: const Color(0xFF14141B).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildPillNavItem(0, Icons.info_outline_rounded, "Info"),
                        _buildPillNavItem(1, Icons.play_arrow_rounded, "Watch"),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularButton({required IconData icon, required VoidCallback onTap}) {
    bool isFocused = false; 
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return InkWell( 
          onTap: onTap,
          onFocusChange: (focused) => setLocalState(() => isFocused = focused),
          borderRadius: BorderRadius.circular(100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              shape: BoxShape.circle,
              border: Border.all(color: isFocused ? Colors.white : Colors.white24, width: 1.5), 
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        );
      }
    );
  }

  Widget _buildPillNavItem(int index, IconData icon, String label) {
    bool isFocused = false;
    return StatefulBuilder(
      builder: (context, setLocalState) {
        final isSelected = _currentIndex == index;
        return Material( 
          color: Colors.transparent,
          child: InkWell( 
            onTap: () => setState(() => _currentIndex = index),
            onFocusChange: (focused) => setLocalState(() => isFocused = focused),
            borderRadius: BorderRadius.circular(24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isFocused ? Colors.white : Colors.transparent, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: isSelected || isFocused ? Colors.white : Colors.white54,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected || isFocused ? Colors.white : Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}