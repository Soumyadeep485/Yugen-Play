import 'package:flutter/material.dart';

import '../../../core/colors/app_colors.dart';
import '../../../core/radius/app_radius.dart';
import '../../../core/spacing/app_spacing.dart';

/// A reusable selectable tile used throughout the player feature.
///
/// This widget provides a consistent appearance for all player
/// selection sheets such as:
///
/// • Episodes
/// • Servers
/// • Playback Quality
/// • Audio Tracks
/// • Subtitle Tracks
///
/// It contains no business logic and simply exposes a tap callback.
class PlayerSelectionTile extends StatelessWidget {
  const PlayerSelectionTile({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.leading,
    this.badge,
    this.selected = false,
  });

  /// Primary title.
  final String title;

  /// Optional secondary text.
  final String? subtitle;

  /// Optional leading widget.
  final Widget? leading;

  /// Optional badge widget.
  final Widget? badge;

  /// Whether this tile is currently selected.
  final bool selected;

  /// Called when the tile is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.15)
                : AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.md),
              ],

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (badge != null) ...[
                badge!,
                const SizedBox(width: AppSpacing.sm),
              ],

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: selected
                    ? const Icon(
                        Icons.check_circle,
                        key: ValueKey('selected'),
                        color: AppColors.primary,
                      )
                    : const SizedBox(
                        key: ValueKey('unselected'),
                        width: 24,
                        height: 24,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
