import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../shared/models/anime.dart';
import '../../services/tv_library_service.dart';
import 'tv_watch_screen.dart';

class TvAnimeDetailsScreen extends ConsumerStatefulWidget {
  final Anime anime;

  const TvAnimeDetailsScreen({super.key, required this.anime});

  @override
  ConsumerState<TvAnimeDetailsScreen> createState() => _TvAnimeDetailsScreenState();
}

class _TvAnimeDetailsScreenState extends ConsumerState<TvAnimeDetailsScreen> {
  final TvLibraryService _libraryService = TvLibraryService();

  // Cleans HTML tags from AniList descriptions
  String get _cleanDescription {
    if (widget.anime.description == null) return "No synopsis available.";
    return widget.anime.description!.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  void _showLibraryPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (BuildContext dialogContext) {
        return Center(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1E222A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24, width: 2),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 40)],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Add to Library", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  _LibraryStatusButton(
                    label: "Watching",
                    icon: Icons.play_circle_outline_rounded,
                    onTap: () {
                      _libraryService.addToLibrary(widget.anime.id, widget.anime.title, widget.anime.coverImage ?? '', 'Watching');
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Added to Watching")));
                    },
                  ),
                  const SizedBox(height: 12),
                  _LibraryStatusButton(
                    label: "Plan to Watch",
                    icon: Icons.bookmark_border_rounded,
                    onTap: () {
                      _libraryService.addToLibrary(widget.anime.id, widget.anime.title, widget.anime.coverImage ?? '', 'Plan to Watch');
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Added to Plan to Watch")));
                    },
                  ),
                  const SizedBox(height: 12),
                  _LibraryStatusButton(
                    label: "Completed",
                    icon: Icons.check_circle_outline_rounded,
                    onTap: () {
                      _libraryService.addToLibrary(widget.anime.id, widget.anime.title, widget.anime.coverImage ?? '', 'Completed');
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Added to Completed")));
                    },
                  ),
                  const SizedBox(height: 12),
                  _LibraryStatusButton(
                    label: "Dropped",
                    icon: Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    onTap: () {
                      _libraryService.addToLibrary(widget.anime.id, widget.anime.title, widget.anime.coverImage ?? '', 'Dropped');
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Moved to Dropped")));
                    },
                  ),
                  const SizedBox(height: 24),
                  _LibraryStatusButton(
                    label: "Remove from Library",
                    icon: Icons.close_rounded,
                    isOutlined: true,
                    onTap: () {
                      _libraryService.removeFromLibrary(widget.anime.id);
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Removed from Library")));
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bannerImage = widget.anime.bannerImage ?? widget.anime.coverImage ?? '';
    final posterImage = widget.anime.coverImage ?? '';
    
    // 🚀 CLEANED UP METADATA EXTRACTION
    final rating = widget.anime.rating != null ? "${widget.anime.rating}%" : "N/A";
    final episodes = widget.anime.episodes != null ? "${widget.anime.episodes} EP" : "TBA";
    final formatStr = widget.anime.format?.replaceAll('_', ' ') ?? 'TV';
    final statusText = widget.anime.status?.replaceAll('_', ' ') ?? 'UNKNOWN';

    return Scaffold(
      backgroundColor: const Color(0xFF0F0E13),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // =========================================================
          // 1. HIGH-PERFORMANCE AMBIENT BACKGROUND
          // =========================================================
          if (bannerImage.isNotEmpty)
            Opacity(
              opacity: 0.15, 
              child: Image.network(
                bannerImage,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  const Color(0xFF0F0E13).withValues(alpha: 1.0),
                  const Color(0xFF0F0E13).withValues(alpha: 0.8),
                  const Color(0xFF0F0E13).withValues(alpha: 0.4),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  const Color(0xFF0F0E13).withValues(alpha: 1.0),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5],
              ),
            ),
          ),

          // =========================================================
          // 2. FOREGROUND CONTENT
          // =========================================================
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TOP BAR 
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
                  child: Row(
                    children: [
                      _TvTopBarButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          widget.anime.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                // MAIN SPLIT LAYOUT
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // -----------------------------------------------------
                      // LEFT COLUMN: Poster (Library Popup) & Watch Now
                      // -----------------------------------------------------
                      Padding(
                        padding: const EdgeInsets.only(left: 40.0, right: 40.0),
                        child: SizedBox(
                          width: 220, 
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _TvPosterButton(
                                imageUrl: posterImage,
                                onTap: () => _showLibraryPopup(context),
                              ),
                              const SizedBox(height: 24),
                              _TvWatchNowCard(
                                title: "Watch Now",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TvWatchScreen(anime: widget.anime),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      // -----------------------------------------------------
                      // RIGHT COLUMN: Details 
                      // -----------------------------------------------------
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(right: 40.0, bottom: 40.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                widget.anime.title,
                                style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold, height: 1.1),
                              ),
                              const SizedBox(height: 16),

                              // 🚀 NEW: Accurate Metadata Row with Format, Episodes, Status
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _Badge(text: formatStr),
                                  _Badge(text: episodes),
                                  if (statusText != 'UNKNOWN') _Badge(text: statusText),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                                      const SizedBox(width: 6),
                                      Text(rating, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                              
                              // 🚀 NEW: Dynamic Genre Injection
                              if (widget.anime.genres != null && widget.anime.genres!.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: widget.anime.genres!.map((genre) => Text(
                                    genre.toUpperCase(),
                                    style: const TextStyle(
                                      color: Color(0xFF3DB4F2), 
                                      fontSize: 13, 
                                      fontWeight: FontWeight.w900, 
                                      letterSpacing: 1.2
                                    ),
                                  )).toList(),
                                ),
                              ],
                              
                              const SizedBox(height: 28),
                              Container(height: 1, color: Colors.white10), 
                              const SizedBox(height: 28),

                              // Synopsis
                              const Text("SYNOPSIS", style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                              const SizedBox(height: 12),
                              Text(
                                _cleanDescription,
                                style: const TextStyle(
                                  color: Colors.white70, 
                                  fontSize: 16, 
                                  height: 1.6,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// UI HELPER WIDGETS
// ============================================================================

class _TvPosterButton extends StatefulWidget {
  final String imageUrl;
  final VoidCallback onTap;

  const _TvPosterButton({required this.imageUrl, required this.onTap});

  @override
  State<_TvPosterButton> createState() => _TvPosterButtonState();
}

class _TvPosterButtonState extends State<_TvPosterButton> {
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
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutQuart,
          transform: Matrix4.diagonal3Values(_isFocused ? 1.05 : 1.0, _isFocused ? 1.05 : 1.0, 1.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _isFocused ? Colors.white : Colors.white24, width: _isFocused ? 4 : 1),
            boxShadow: _isFocused 
                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.6), blurRadius: 20, spreadRadius: 4)] 
                : [BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_isFocused ? 4 : 7),
            child: AspectRatio(
              aspectRatio: 2 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[900]),
                  ),
                  if (_isFocused)
                    Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: const Center(
                        child: Icon(Icons.playlist_add_rounded, color: Colors.white, size: 64),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _TvTopBarButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TvTopBarButton({required this.icon, required this.onTap});

  @override
  State<_TvTopBarButton> createState() => _TvTopBarButtonState();
}

class _TvTopBarButtonState extends State<_TvTopBarButton> {
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isFocused ? Colors.white : Colors.white.withValues(alpha: 0.05),
            border: Border.all(color: _isFocused ? Colors.white : Colors.transparent),
          ),
          child: Icon(
            widget.icon,
            color: _isFocused ? Colors.black : Colors.white70,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _TvWatchNowCard extends StatefulWidget {
  final String title;
  final VoidCallback onTap;

  const _TvWatchNowCard({required this.title, required this.onTap});

  @override
  State<_TvWatchNowCard> createState() => _TvWatchNowCardState();
}

class _TvWatchNowCardState extends State<_TvWatchNowCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true, 
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onFocusChange: (focused) => setState(() => _isFocused = focused),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            transform: Matrix4.diagonal3Values(_isFocused ? 1.05 : 1.0, _isFocused ? 1.05 : 1.0, 1.0),
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              color: _isFocused ? AppColors.primary : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _isFocused ? Colors.white : Colors.white24, width: _isFocused ? 2 : 1),
              boxShadow: _isFocused ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.6), blurRadius: 16)] : [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_fill_rounded, color: _isFocused ? Colors.white : Colors.white70, size: 32),
                const SizedBox(width: 12),
                Text(
                  widget.title,
                  style: TextStyle(
                    color: _isFocused ? Colors.white : Colors.white, 
                    fontSize: 18, 
                    fontWeight: FontWeight.bold
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

class _LibraryStatusButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final bool isOutlined;

  const _LibraryStatusButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
    this.isOutlined = false,
  });

  @override
  State<_LibraryStatusButton> createState() => _LibraryStatusButtonState();
}

class _LibraryStatusButtonState extends State<_LibraryStatusButton> {
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
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _isFocused ? Colors.white : (widget.isOutlined ? Colors.transparent : Colors.white.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _isFocused ? Colors.white : (widget.isOutlined ? Colors.white24 : Colors.transparent)),
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: _isFocused ? Colors.black : (widget.color ?? Colors.white), size: 20),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: TextStyle(
                  color: _isFocused ? Colors.black : (widget.color ?? Colors.white),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}