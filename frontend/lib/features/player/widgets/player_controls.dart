import 'package:flutter/material.dart';

import '../../../core/colors/app_colors.dart';
import '../../../core/radius/app_radius.dart';
import '../../../core/spacing/app_spacing.dart';

/// Primary control panel for the player.
///
/// This widget does not contain playback logic.
/// It simply exposes user interactions through callbacks.
class PlayerControls extends StatelessWidget {
  const PlayerControls({
    super.key,
    required this.onPlayPressed,
    required this.onEpisodesPressed,
    required this.onServersPressed,
    required this.onQualityPressed,
    required this.onSubtitlesPressed,
    required this.onAudioPressed,
    this.isPlayEnabled = false,
  });

  final VoidCallback onPlayPressed;
  final VoidCallback onEpisodesPressed;
  final VoidCallback onServersPressed;
  final VoidCallback onQualityPressed;
  final VoidCallback onSubtitlesPressed;
  final VoidCallback onAudioPressed;

  /// Whether playback can be started.
  final bool isPlayEnabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: isPlayEnabled ? onPlayPressed : null,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Play'),
          ),

          const SizedBox(height: AppSpacing.lg),

          Row(
            children: [
              Expanded(
                child: _ControlTile(
                  icon: Icons.list_alt_rounded,
                  label: 'Episodes',
                  onTap: onEpisodesPressed,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ControlTile(
                  icon: Icons.dns_rounded,
                  label: 'Servers',
                  onTap: onServersPressed,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              Expanded(
                child: _ControlTile(
                  icon: Icons.high_quality_rounded,
                  label: 'Quality',
                  onTap: onQualityPressed,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ControlTile(
                  icon: Icons.audiotrack_rounded,
                  label: 'Audio',
                  onTap: onAudioPressed,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          _ControlTile(
            icon: Icons.subtitles_rounded,
            label: 'Subtitles',
            onTap: onSubtitlesPressed,
          ),
        ],
      ),
    );
  }
}

class _ControlTile extends StatelessWidget {
  const _ControlTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
