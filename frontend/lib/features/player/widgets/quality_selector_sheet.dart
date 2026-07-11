import 'package:flutter/material.dart';

import '../../../core/colors/app_colors.dart';
import '../../../core/radius/app_radius.dart';
import '../../../core/spacing/app_spacing.dart';
import '../models/stream_link.dart';
import 'player_selection_sheet.dart';
import 'player_selection_tile.dart';

/// Bottom sheet for selecting playback quality.
///
/// Displays every available [StreamLink].
class QualitySelectorSheet extends StatelessWidget {
  const QualitySelectorSheet({
    super.key,
    required this.streamLinks,
    required this.selectedStream,
    required this.onQualitySelected,
  });

  final List<StreamLink> streamLinks;

  final StreamLink? selectedStream;

  final ValueChanged<StreamLink> onQualitySelected;

  @override
  Widget build(BuildContext context) {
    return PlayerSelectionSheet(
      title: 'Playback Quality',
      child: ListView.separated(
        itemCount: streamLinks.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final stream = streamLinks[index];

          return PlayerSelectionTile(
            title: stream.quality,
            subtitle: stream.isHls ? 'Adaptive (HLS)' : 'Direct Stream',
            selected: stream == selectedStream,

            badge: stream.isHls
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
                      'HLS',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : null,

            onTap: () {
              onQualitySelected(stream);
              Navigator.of(context).pop();
            },
          );
        },
      ),
    );
  }
}
