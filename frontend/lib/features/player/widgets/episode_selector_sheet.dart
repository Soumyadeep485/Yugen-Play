import 'package:flutter/material.dart';

import '../../../core/colors/app_colors.dart';
import '../../../core/radius/app_radius.dart';
import '../../../core/spacing/app_spacing.dart';
import '../models/episode.dart';
import 'player_selection_sheet.dart';
import 'player_selection_tile.dart';

/// Bottom sheet for selecting an episode.
///
/// Supports searching by episode number or title.
class EpisodeSelectorSheet extends StatefulWidget {
  const EpisodeSelectorSheet({
    super.key,
    required this.episodes,
    required this.selectedEpisode,
    required this.onEpisodeSelected,
  });

  final List<Episode> episodes;
  final Episode? selectedEpisode;
  final ValueChanged<Episode> onEpisodeSelected;

  @override
  State<EpisodeSelectorSheet> createState() => _EpisodeSelectorSheetState();
}

class _EpisodeSelectorSheetState extends State<EpisodeSelectorSheet> {
  late final TextEditingController _searchController;

  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Episode> get _filteredEpisodes {
    if (_query.trim().isEmpty) {
      return widget.episodes;
    }

    final query = _query.toLowerCase();

    return widget.episodes.where((episode) {
      return episode.title.toLowerCase().contains(query) ||
          episode.number.toString().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return PlayerSelectionSheet(
      title: 'Episodes',
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _query = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search episode...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          Expanded(
            child: ListView.separated(
              itemCount: _filteredEpisodes.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final episode = _filteredEpisodes[index];

                return PlayerSelectionTile(
                  title: 'Episode ${episode.number}',
                  subtitle: episode.title,
                  selected: episode == widget.selectedEpisode,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.surface,
                    child: Text(episode.number.toString()),
                  ),
                  onTap: () {
                    widget.onEpisodeSelected(episode);

                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
