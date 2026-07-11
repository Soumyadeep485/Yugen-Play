import 'package:flutter/material.dart';

import '../../../core/colors/app_colors.dart';
import '../../../core/radius/app_radius.dart';
import '../../../core/spacing/app_spacing.dart';

/// Base layout for all player selection bottom sheets.
///
/// This widget provides a consistent Material 3 layout used by:
///
/// • Episode Selector
/// • Server Selector
/// • Quality Selector
/// • Subtitle Selector
/// • Audio Selector
///
/// Only the title and content differ between sheets.
class PlayerSelectionSheet extends StatelessWidget {
  const PlayerSelectionSheet({
    super.key,
    required this.title,
    required this.child,
  });

  /// Sheet title.
  final String title;

  /// Sheet content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            Text(
              title,
              style: textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}
