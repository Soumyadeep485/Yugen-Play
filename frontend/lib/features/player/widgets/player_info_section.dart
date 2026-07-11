import 'package:flutter/material.dart';

import '../../../core/colors/app_colors.dart';
import '../../../core/spacing/app_spacing.dart';
import '../models/episode.dart';

/// Displays metadata about the currently selected anime episode.
///
/// This widget intentionally displays only anime/episode information.
/// Playback information such as provider, quality, subtitles and
/// audio tracks are displayed elsewhere.
class PlayerInfoSection extends StatelessWidget {
  const PlayerInfoSection({
    super.key,
    required this.animeTitle,
    this.episode,
    this.format,
    this.duration,
  });

  /// Anime title from AniList.
  final String animeTitle;

  /// Currently selected episode.
  final Episode? episode;

  /// Anime format.
  ///
  /// Example:
  /// TV
  /// Movie
  /// OVA
  final String? format;

  /// Episode duration.
  ///
  /// Example:
  /// 24 min
  final String? duration;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            animeTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          if (episode != null)
            Text(
              'Episode ${episode!.number} • ${episode!.title}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Text(
              'No episode selected',
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

          if (format != null || duration != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                if (format != null)
                  Text(
                    format!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (format != null && duration != null)
                  Text(
                    '•',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (duration != null)
                  Text(
                    duration!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
