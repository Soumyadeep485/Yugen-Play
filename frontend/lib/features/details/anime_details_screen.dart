import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:frontend/features/player/screens/find_torrent_sheet.dart';
import '../../core/colors/app_colors.dart';
import '../../core/radius/app_radius.dart';
import '../../shared/models/anime_details.dart';
import '../../shared/widgets/buttons/icon_circle_button.dart';
import '../../shared/widgets/buttons/primary_button.dart';
import '../player/controllers/player_controller.dart';
import 'data/details_repository.dart';
import 'widgets/details_loading.dart';
import 'widgets/expandable_synopsis.dart';
import 'widgets/info_card.dart';
import '../../service_locator.dart';
import '../player/models/plugin_meta.dart';

class AnimeDetailsScreen extends StatefulWidget {
  final int animeId;
  final String heroTag;

  const AnimeDetailsScreen({
    super.key,
    required this.animeId,
    required this.heroTag,
  });

  @override
  State<AnimeDetailsScreen> createState() => _AnimeDetailsScreenState();
}

class _AnimeDetailsScreenState extends State<AnimeDetailsScreen> {
  final DetailsRepository _repository = DetailsRepository();
  late Future<AnimeDetails> _animeDetailsFuture;

  // Scoped controller mapped to GetIt factories
  late final PlayerController _playerController;

  @override
  void initState() {
    super.initState();
    _playerController = locator<PlayerController>();
    _loadAnime();

    // Add this to ensure plugins are loaded before the user tries to watch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playerController.loadPlugins();
    });
  }

  void _loadAnime() {
    // FIXED: Changed to match the new repository method name
    _animeDetailsFuture = _repository.fetchAnimeDetails(widget.animeId);
  }

  void _retryLoad() {
    setState(() {
      _loadAnime();
      _playerController.loadPlugins();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<AnimeDetails>(
        future: _animeDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const DetailsLoading();
          }

          if (snapshot.hasError) {
            return _DetailsErrorState(
              onRetry: _retryLoad,
              onBack: () => Navigator.pop(context),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text(
                'No anime details available',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          final anime = snapshot.data!;

          // Wrapped in a ListenableBuilder to securely listen to the state updates of PlayerController
          return ListenableBuilder(
            listenable: _playerController,
            builder: (context, _) {
              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 430,
                    pinned: true,
                    backgroundColor: AppColors.background,
                    surfaceTintColor: Colors.transparent,
                    leading: Padding(
                      padding: const EdgeInsets.all(8),
                      child: IconCircleButton(
                        icon: Icons.arrow_back_rounded,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 8,
                          right: 12,
                          bottom: 8,
                        ),
                        child: IconCircleButton(
                          icon: Icons.bookmark_border_rounded,
                          onPressed: () {},
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          Hero(
                            tag: widget.heroTag,
                            child: CachedNetworkImage(
                              imageUrl: anime.imageUrl,
                              fit: BoxFit.cover,
                              fadeInDuration: const Duration(milliseconds: 300),
                              placeholder: (context, url) =>
                                  Container(color: AppColors.card),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.card,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.white38,
                                  size: 48,
                                ),
                              ),
                            ),
                          ),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Color(0x33000000),
                                  Color(0xCC0D0D0F),
                                  AppColors.background,
                                ],
                                stops: [0.25, 0.50, 0.82, 1.0],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            anime.title,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  height: 1.08,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              // FIXED: Mapped to meanScore instead of rating
                              if (anime.meanScore > 0)
                                _InfoChip(
                                  label: '★ ${anime.meanScore}',
                                  emphasized: true,
                                ),
                              // FIXED: Mapped to format instead of type
                              if (anime.format != 'UNKNOWN')
                                _InfoChip(label: anime.format),
                              if (anime.episodes != null)
                                _InfoChip(label: '${anime.episodes} Episodes'),
                              // FIXED: Mapped to seasonYear instead of year
                              if (anime.seasonYear != null)
                                _InfoChip(label: anime.seasonYear.toString()),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (anime.genres.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: anime.genres
                                  .map((genre) => _GenreChip(label: genre))
                                  .toList(),
                            ),

                          // 📦 DROPDOWN SELECTOR BLOCK INJECTED HERE
                          const SizedBox(height: 24),
                          const _SectionTitle(title: 'Video Provider Source'),
                          const SizedBox(height: 8),
                          _buildPluginDropdown(),
                          const SizedBox(height: 24),

                          Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: PrimaryButton(
                                  // Or whatever your button widget is named
                                  text: "Watch Now",
                                  icon: Icons.play_arrow_rounded,
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      useRootNavigator:
                                          true, // Ensures it overlays the bottom nav bar too
                                      builder: (context) => const FindTorrentSheet(
                                        animeTitle:
                                            "Attack on Titan", // Pass your actual dynamic variables here
                                        episodeNumber: 1,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 50,
                                height: 50,
                                child: OutlinedButton(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    foregroundColor: Colors.white,
                                    side: BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.18,
                                      ),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.md,
                                      ),
                                    ),
                                  ),
                                  child: const Icon(Icons.add_rounded),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          const _SectionTitle(title: 'Synopsis'),
                          const SizedBox(height: 10),
                          // FIXED: Mapped to description instead of synopsis
                          ExpandableSynopsis(synopsis: anime.description),
                          const SizedBox(height: 30),
                          const _SectionTitle(title: 'Information'),
                          const SizedBox(height: 14),
                          InfoCard(
                            icon: Icons.live_tv_rounded,
                            title: "Status",
                            value: anime.status,
                          ),
                          InfoCard(
                            icon: Icons.schedule_rounded,
                            title: "Duration",
                            // FIXED: Added null check and toString() conversion
                            value: anime.duration != null
                                ? "${anime.duration} min"
                                : "Unknown",
                          ),
                          InfoCard(
                            icon: Icons.movie_creation_outlined,
                            title: "Episodes",
                            value: anime.episodes?.toString() ?? "Unknown",
                          ),
                          InfoCard(
                            icon: Icons.business_rounded,
                            title: "Studio",
                            // FIXED: Studios removed from new model, safely mapped to Unknown for legacy screen
                            value: "Unknown",
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // Generates a clean, stylized dropdown selector based on active Hive storage states
  Widget _buildPluginDropdown() {
    if (_playerController.isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 12),
            Text(
              "Loading local extensions...",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_playerController.availablePlugins.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
        ),
        child: const Text(
          "❌ No active plugins available. Core engine locked.",
          style: TextStyle(
            color: Colors.redAccent,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PluginMeta>(
          value: _playerController.selectedPlugin,
          isExpanded: true,
          dropdownColor: AppColors.card,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),
          items: _playerController.availablePlugins.map((PluginMeta plugin) {
            return DropdownMenuItem<PluginMeta>(
              value: plugin,
              child: Text(
                "${plugin.name} (v${plugin.version})",
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          onChanged: (PluginMeta? newPlugin) {
            if (newPlugin != null) {
              _playerController.selectPlugin(newPlugin);
            }
          },
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final bool emphasized;

  const _InfoChip({required this.label, this.emphasized = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: emphasized
            ? AppColors.primary.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: emphasized
              ? AppColors.primary.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: emphasized ? Colors.white : AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  final String label;

  const _GenreChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _DetailsErrorState extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onRetry;

  const _DetailsErrorState({required this.onRetry, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: Colors.white54,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Unable to load anime details',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please check your connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text("Retry"),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
