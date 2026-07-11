import 'package:flutter/material.dart';

import '../../../core/colors/app_colors.dart';
import '../../../core/radius/app_radius.dart';
import '../../../core/spacing/app_spacing.dart';
import '../models/server.dart';
import 'player_selection_sheet.dart';
import 'player_selection_tile.dart';

/// Bottom sheet for selecting a streaming server.
///
/// Displays all available servers and reports the selected server
/// through [onServerSelected].
class ServerSelectorSheet extends StatelessWidget {
  const ServerSelectorSheet({
    super.key,
    required this.servers,
    required this.selectedServer,
    required this.onServerSelected,
  });

  final List<Server> servers;
  final Server? selectedServer;
  final ValueChanged<Server> onServerSelected;

  @override
  Widget build(BuildContext context) {
    final highestPriority = servers.isEmpty
        ? null
        : servers
              .map((server) => server.priority)
              .reduce((a, b) => a > b ? a : b);

    return PlayerSelectionSheet(
      title: 'Select Server',
      child: ListView.separated(
        itemCount: servers.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final server = servers[index];

          final isRecommended =
              highestPriority != null && server.priority == highestPriority;

          return PlayerSelectionTile(
            title: server.name,
            subtitle: 'Priority ${server.priority}',
            selected: server == selectedServer,
            badge: isRecommended
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
                      'Recommended',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : null,
            onTap: () {
              onServerSelected(server);
              Navigator.of(context).pop();
            },
          );
        },
      ),
    );
  }
}
