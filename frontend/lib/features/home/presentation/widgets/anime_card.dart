import 'package:flutter/material.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../shared/models/anime.dart';

class AnimeCard extends StatefulWidget {
  final Anime anime;
  final VoidCallback onTap;

  const AnimeCard({super.key, required this.anime, required this.onTap});

  @override
  State<AnimeCard> createState() => _AnimeCardState();
}

class _AnimeCardState extends State<AnimeCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final displayRating = widget.anime.rating != null
        ? widget.anime.rating!.toStringAsFixed(1)
        : "N/A";

    // InkWell captures TV D-pad focus
    return InkWell(
      onTap: widget.onTap,
      onFocusChange: (hasFocus) {
        setState(() => _isFocused = hasFocus);
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 145,
        // The glowing white border when the TV remote points at this card
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isFocused ? Colors.white : Colors.transparent,
            width: _isFocused ? 3.0 : 0.0,
          ),
          boxShadow: _isFocused
              ? [const BoxShadow(color: Colors.white54, blurRadius: 12, spreadRadius: 1)]
              : [],
        ),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 2 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13), // Adjusted slightly for border fit
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.network(
                        widget.anime.coverImage ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppColors.card,
                          child: const Icon(
                            Icons.broken_image_rounded,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.2),
                              Colors.black.withValues(alpha: 0.85),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 10,
                      right: 10,
                      child: Text(
                        widget.anime.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: AppColors.primary,
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    displayRating,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}