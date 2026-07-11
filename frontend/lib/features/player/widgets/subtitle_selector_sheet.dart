import 'package:flutter/material.dart';

import '../../../core/colors/app_colors.dart';
import '../../../core/radius/app_radius.dart';
import '../../../core/spacing/app_spacing.dart';
import '../models/subtitle_track.dart';
import 'player_selection_sheet.dart';
import 'player_selection_tile.dart';

/// Bottom sheet for selecting subtitle tracks.
///
/// This widget is presentation-only and reports the selected
/// subtitle through [onSubtitleSelected].
class SubtitleSelectorSheet extends StatelessWidget {
  const SubtitleSelectorSheet({
    super.key,
    required this.subtitles,
    required this.selectedSubtitle,
    required this.onSubtitleSelected,
  });

  /// Available subtitle tracks.
  final List<SubtitleTrack> subtitles;

  /// Currently selected subtitle.
  final SubtitleTrack? selectedSubtitle;

  /// Called when a subtitle track is selected.
  final ValueChanged<SubtitleTrack> onSubtitleSelected;

  @override
  Widget build(BuildContext context) {
    return PlayerSelectionSheet(
      title: 'Subtitles',
      child: ListView.separated(
        itemCount: subtitles.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final subtitle = subtitles[index];

          return PlayerSelectionTile(
            title: subtitle.label,
            subtitle: subtitle.languageCode.toUpperCase(),
            selected: subtitle == selectedSubtitle,

            badge: subtitle.isDefault
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      'Default',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : null,

            onTap: () {
              onSubtitleSelected(subtitle);
              Navigator.of(context).pop();
            },
          );
        },
      ),
    );
  }
}
