import 'package:flutter/material.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/radius/app_radius.dart';
import '../../models/stream_link.dart';
import 'player_selection_sheet.dart';
import 'player_selection_tile.dart';

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
    if (streamLinks.isEmpty) {
      return const PlayerSelectionSheet(
        title: 'Playback Quality',
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                color: AppColors.textSecondary,
                size: 64,
              ),
              SizedBox(height: 16),
              Text(
                "No streams found.",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Try selecting a different server or plugin.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

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
