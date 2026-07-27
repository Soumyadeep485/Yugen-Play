import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:frontend/features/library/presentation/widgets/library_status_sheet.dart';
import 'package:frontend/features/library/services/library_service.dart';
import 'package:palette_generator/palette_generator.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../shared/models/anime.dart';
import '../widgets/info_tab.dart';
import '../widgets/watch_tab.dart';

class AnimeDetailsScreen extends StatefulWidget {
  final Anime anime;

  const AnimeDetailsScreen({super.key, required this.anime});

  @override
  State<AnimeDetailsScreen> createState() => _AnimeDetailsScreenState();
}

class _AnimeDetailsScreenState extends State<AnimeDetailsScreen> {
  final LibraryService _libraryService = LibraryService();
  String? _libraryStatus;
  
  // 0 = Info, 1 = Watch, 2 = Comments (if you add them later)
  int _currentIndex = 0; 

Color _dominantColor = Colors.black;

  @override
  void initState() {
    super.initState();
    _libraryStatus = _libraryService.getAnimeStatus(widget.anime.id.toString());
    _extractDominantColor();
  }
  // NEW: Extract color from the banner
  Future<void> _extractDominantColor() async {
    final bannerUrl = widget.anime.bannerImage ?? widget.anime.coverImage ?? '';
    if (bannerUrl.isEmpty) return;

    try {
      final palette = await PaletteGenerator.fromImageProvider(NetworkImage(bannerUrl));
      if (mounted && palette.dominantColor != null) {
        setState(() {
          _dominantColor = palette.dominantColor!.color;
        });
      }
    } catch (e) {
      debugPrint("Failed to extract color: $e");
    }
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
    final bannerUrl = widget.anime.bannerImage ?? widget.anime.coverImage ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ==========================================
          // 1. BLURRED BACKGROUND IMAGE
          // ==========================================
          Positioned.fill(
            child: Image.network(
              bannerUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: AppColors.background),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500), // Smooth fade in
                // Tint the glass with the anime's extracted color, darkened so text is readable
                color: _dominantColor.withValues(alpha: 0.75), 
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
                bottom: 120, // Space for the floating nav
              ),
              physics: const BouncingScrollPhysics(),
              children: [
                // --- POSTER AND TITLE HEADER ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Mini Poster
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.anime.coverImage ?? bannerUrl,
                          width: 120,
                          height: 170,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 120, height: 170, color: AppColors.card,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Title & Status
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
                                color: AppColors.textPrimary,
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
                                  color: Colors.blueAccent, // Matches the AnymeX blue
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
                  duration: const Duration(milliseconds: 300),
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
          // 4. FLOATING PILL NAVIGATION
          // ==========================================
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                  child: Container(
                    height: 64,
                    width: 200, // 🛑 Shrunk from 280 since we only have two buttons now
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildPillNavItem(0, Icons.info_outline_rounded, "Info"),
                        _buildPillNavItem(1, Icons.play_arrow_rounded, "Watch"),
                        // 🛑 Comments button brutally murdered as requested
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

  // Helper for Top Buttons
  Widget _buildCircularButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  // Helper for Floating Nav Items
  Widget _buildPillNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}