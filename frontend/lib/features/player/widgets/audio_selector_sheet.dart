import 'package:flutter/material.dart';

import '../../../core/colors/app_colors.dart';
import '../../../core/radius/app_radius.dart';
import '../../../core/spacing/app_spacing.dart';
import '../models/audio_track.dart';
import 'player_selection_sheet.dart';
import 'player_selection_tile.dart';

/// Bottom sheet for selecting an audio track.
///
/// This widget is presentation-only and reports the selected
/// audio track through [onAudioSelected].
class AudioSelectorSheet extends StatelessWidget {
  const AudioSelectorSheet({
    super.key,
    required this.audioTracks,
    required this.selectedAudio,
    required this.onAudioSelected,
  });

  /// Available audio tracks.
  final List<AudioTrack> audioTracks;

  /// Currently selected audio track.
  final AudioTrack? selectedAudio;

  /// Called when an audio track is selected.
  final ValueChanged<AudioTrack> onAudioSelected;

  @override
  Widget build(BuildContext context) {
    return PlayerSelectionSheet(
      title: 'Audio Tracks',
      child: ListView.separated(
        itemCount: audioTracks.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final audio = audioTracks[index];

          final subtitle = audio.languageCode.toUpperCase();

          return PlayerSelectionTile(
            title: audio.label,
            subtitle: subtitle,
            selected: audio == selectedAudio,

            badge: audio.isDefault
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
              onAudioSelected(audio);
              Navigator.of(context).pop();
            },
          );
        },
      ),
    );
  }
}
