import 'package:flutter/material.dart';

import '../../core/colors/app_colors.dart';
import '../../core/spacing/app_spacing.dart';
import 'controllers/playback_controller.dart';
import 'controllers/player_controller.dart';
import 'widgets/audio_selector_sheet.dart';
import 'widgets/episode_selector_sheet.dart';
import 'widgets/player_controls.dart';
import 'widgets/player_info_section.dart';
import 'widgets/player_video_surface.dart';
import 'widgets/quality_selector_sheet.dart';
import 'widgets/server_selector_sheet.dart';
import 'widgets/subtitle_selector_sheet.dart';
// Ensure this import points to your actual PlayerSelectionSheet location
import 'widgets/player_selection_sheet.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    required this.controller,
    required this.animeTitle,
  });

  final PlayerController controller;
  final String animeTitle;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  PlayerController get _controller => widget.controller;
  late final PlaybackController _playbackController;

  @override
  void initState() {
    super.initState();

    // Initialize the media_kit playback engine
    _playbackController = PlaybackController();

    // Listen to selection changes
    _controller.addListener(_onPlayerStateChanged);

    // Listen to playback state changes
    _playbackController.addListener(_refresh);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadPlugins();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onPlayerStateChanged);
    _playbackController.removeListener(_refresh);
    _playbackController.dispose();
    super.dispose();
  }

  void _onPlayerStateChanged() {
    _refresh();

    final selectedStream = _controller.selectedStream;

    if (selectedStream != null &&
        selectedStream != _playbackController.currentStream) {
      _playbackController.setStream(selectedStream);
      _playbackController.play();
    }
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  void _showPluginSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      builder: (_) => PlayerSelectionSheet(
        title: "Select Scraper",
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _controller.availablePlugins.length,
          itemBuilder: (ctx, index) {
            final plugin = _controller.availablePlugins[index];
            final isSelected = _controller.selectedPlugin?.id == plugin.id;

            return ListTile(
              title: Text(
                plugin.name,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                "v${plugin.version}",
                style: const TextStyle(color: Colors.grey),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                _controller.selectPlugin(plugin);
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          'Player',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            _controller.errorMessage ?? 'Something went wrong',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.error),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: PlayerVideoSurface(controller: _playbackController),
              ),
            ),
          ),

          // Plugin Selection Button
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.extension_rounded),
              label: Text(_controller.selectedPlugin?.name ?? "Select Scraper"),
              onPressed: _showPluginSelector,
            ),
          ),

          PlayerInfoSection(
            animeTitle: widget.animeTitle,
            episode: _controller.selectedEpisode,
          ),

          PlayerControls(
            isPlayEnabled:
                _controller.selectedEpisode != null &&
                _controller.selectedServer != null &&
                _controller.selectedStream != null,
            onPlayPressed: () {
              _playbackController.togglePlay();
            },
            onEpisodesPressed: _showEpisodeSelector,
            onServersPressed: _showServerSelector,
            onQualityPressed: _showQualitySelector,
            onSubtitlesPressed: _showSubtitleSelector,
            onAudioPressed: _showAudioSelector,
          ),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  // --- Selectors ---

  void _showEpisodeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (_) => EpisodeSelectorSheet(
        episodes: _controller.episodes,
        selectedEpisode: _controller.selectedEpisode,
        onEpisodeSelected: (episode) => _controller.selectEpisode(episode),
      ),
    );
  }

  void _showServerSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) => ServerSelectorSheet(
        servers: _controller.servers,
        selectedServer: _controller.selectedServer,
        onServerSelected: (server) => _controller.selectServer(server),
      ),
    );
  }

  void _showQualitySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) => QualitySelectorSheet(
        streamLinks: _controller.streamLinks,
        selectedStream: _controller.selectedStream,
        onQualitySelected: (stream) => _controller.selectStream(stream),
      ),
    );
  }

  void _showSubtitleSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) => SubtitleSelectorSheet(
        subtitles: _controller.subtitleTracks,
        selectedSubtitle: _controller.selectedSubtitle,
        onSubtitleSelected: (subtitle) => _controller.selectSubtitle(subtitle),
      ),
    );
  }

  void _showAudioSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) => AudioSelectorSheet(
        audioTracks: _controller.audioTracks,
        selectedAudio: _controller.selectedAudio,
        onAudioSelected: (audio) => _controller.selectAudio(audio),
      ),
    );
  }
}
