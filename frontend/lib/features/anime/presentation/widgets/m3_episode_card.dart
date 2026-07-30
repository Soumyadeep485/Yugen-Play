import 'package:flutter/material.dart';
import '../../../../core/colors/app_colors.dart';

class M3EpisodeCard extends StatefulWidget {
  final int episodeNumber;
  final String title;
  final String description;
  final String thumbnailUrl;
  final VoidCallback onTap;
  final bool isCurrentlyLoading;

  const M3EpisodeCard({
    super.key,
    required this.episodeNumber,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.onTap,
    this.isCurrentlyLoading = false,
  });

  @override
  State<M3EpisodeCard> createState() => _M3EpisodeCardState();
}

class _M3EpisodeCardState extends State<M3EpisodeCard> {
  bool _isFocused = false; // 👇 TV Focus Tracker

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer( // 👇 Swapped to AnimatedContainer for smooth border fading
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          // 👇 Bright white border when D-Pad highlights the card
          color: _isFocused ? Colors.white : AppColors.textPrimary.withValues(alpha: 0.05),
          width: _isFocused ? 2.0 : 1.0,
        ),
        boxShadow: _isFocused
            ? [const BoxShadow(color: Colors.white24, blurRadius: 8, spreadRadius: 1)]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isCurrentlyLoading ? null : widget.onTap,
          onFocusChange: (focused) => setState(() => _isFocused = focused), // 👇 Listen for remote control
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 120,
                            height: 68,
                            color: AppColors.surfaceVariant,
                            child: Image.network(
                              widget.thumbnailUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.broken_image,
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.textPrimary.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "EP ${widget.episodeNumber}",
                              style: const TextStyle(
                                color: AppColors.background,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}