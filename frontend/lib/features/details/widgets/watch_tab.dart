import 'package:flutter/material.dart';
import 'package:frontend/features/player/screens/find_torrent_sheet.dart';
import '../../../core/colors/app_colors.dart';
import '../../../core/radius/app_radius.dart';
import '../../../service_locator.dart';
import '../../player/controllers/player_controller.dart';
import '../../player/models/plugin_meta.dart';

class WatchTab extends StatefulWidget {
  final int animeId;
  final String animeTitle;
  final ScrollController scrollController;

  const WatchTab({
    super.key,
    required this.animeId,
    required this.animeTitle,
    required this.scrollController,
  });

  @override
  State<WatchTab> createState() => _WatchTabState();
}

class _WatchTabState extends State<WatchTab> {
  late final PlayerController _playerController;

  @override
  void initState() {
    super.initState();
    _playerController = locator<PlayerController>();

    // Automatically fetch plugins if they aren't loaded yet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_playerController.availablePlugins.isEmpty) {
        _playerController.loadPlugins();
      } else if (_playerController.selectedPlugin != null) {
        // If a plugin is already active, trigger the episode fetch for this specific anime
        _playerController.loadEpisodes(anilistId: widget.animeId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _playerController,
      builder: (context, _) {
        return ListView(
          controller: widget.scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            // Provider Selection Header
            Row(
              children: [
                const Icon(
                  Icons.source_rounded,
                  color: Colors.white54,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  "Source",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_playerController.isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // The Sleek Saikou-style Dropdown
            _buildSourceSelector(),

            const SizedBox(height: 24),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 24),

            // Episode Grid State Machine
            _buildEpisodesArea(),
          ],
        );
      },
    );
  }

  Widget _buildSourceSelector() {
    if (_playerController.availablePlugins.isEmpty &&
        !_playerController.isLoading) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: const Text(
          "No scrapers installed. Check extension manager.",
          style: TextStyle(color: Colors.redAccent, fontSize: 13),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PluginMeta>(
          value: _playerController.selectedPlugin,
          isExpanded: true,
          dropdownColor: AppColors.card,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white54,
          ),
          hint: const Text(
            "Select Provider",
            style: TextStyle(color: Colors.white54),
          ),
          items: _playerController.availablePlugins.map((plugin) {
            return DropdownMenuItem(
              value: plugin,
              child: Text(
                plugin.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
          onChanged: (newPlugin) {
            if (newPlugin != null) {
              _playerController.selectPlugin(newPlugin);
              // Immediately fetch episodes when the user changes the provider
              _playerController.loadEpisodes(anilistId: widget.animeId);
            }
          },
        ),
      ),
    );
  }

  Widget _buildEpisodesArea() {
    if (_playerController.selectedPlugin == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: Text(
            "Select a source to load episodes.",
            style: TextStyle(color: Colors.white38),
          ),
        ),
      );
    }

    if (_playerController.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_playerController.episodes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            children: [
              const Icon(
                Icons.sentiment_dissatisfied_rounded,
                color: Colors.white38,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                "Couldn't find anything :(\nTry another source.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              ),
            ],
          ),
        ),
      );
    }

    // Render the responsive episode grid
    return GridView.builder(
      controller: widget.scrollController,
      shrinkWrap: true, // Needed inside a ListView
      physics:
          const NeverScrollableScrollPhysics(), // Let the parent ListView handle scrolling
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 80,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.5,
      ),
      itemCount: _playerController.episodes.length,
      itemBuilder: (context, index) {
        final episode = _playerController.episodes[index];
        return InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: () {
            // Trigger the glassy torrent sheet
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              useRootNavigator: true,
              builder: (context) => FindTorrentSheet(
                animeTitle: widget.animeTitle,
                episodeNumber: episode.number,
              ),
            );
          },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Text(
              episode.number.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
