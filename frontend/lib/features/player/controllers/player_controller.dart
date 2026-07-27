import 'dart:async';
import '../../library/services/library_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/extensions/services/anikoto_extension_service.dart';
import 'package:frontend/features/extensions/services/dynamic_extension_service.dart';
import 'package:frontend/features/history/services/watch_history_service.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../models/episode.dart';
import '../models/stream_link.dart';
import '../services/player_repository.dart';
import '../services/plugin_manager.dart';
import '../services/plugin_registry.dart';

final playerControllerProvider = Provider<PlayerController>((ref) {
  throw UnimplementedError('Initialize this with your dependencies');
});

class PlayerController extends ChangeNotifier {
  final PlayerRepository repository;
  final PluginRegistry pluginRegistry;
  final PluginManager pluginManager;

  final AnikotoExtensionService _anikotoService = AnikotoExtensionService();
  final DynamicExtensionService _dynamicService = DynamicExtensionService();
  final WatchHistoryService _historyService = WatchHistoryService();
  final LibraryService _libraryService = LibraryService();

  List<StreamLink> _streamLinks = [];
  StreamLink? _selectedStream;
  Episode? _selectedEpisode;
  bool _isLoading = false;
  String? _errorMessage;
  int? _currentTotalEpisodes;
  bool _hasMarkedCompleted = false;
  bool _hasMarkedWatching = false;

  late final Player player;
  late final VideoController videoController;

  StreamSubscription? _positionSubscription;
  DateTime _lastSaveTime = DateTime.now();

  String? _currentAnimeId;
  String? _currentAnimeTitle;
  String? _currentPosterUrl;

  PlayerController({
    required this.repository,
    required this.pluginRegistry,
    required this.pluginManager,
  }) {
    player = Player();
    videoController = VideoController(player);
  }

  List<StreamLink> get streamLinks => _streamLinks;
  StreamLink? get selectedStream => _selectedStream;
  Episode? get selectedEpisode => _selectedEpisode;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchStreamsForEpisode({
    required Episode episode,
    required String animeId,
    required String animeTitle,
    required String posterUrl,
    int? totalEpisodes,
  }) async {
    _selectedEpisode = episode;
    _currentAnimeId = animeId;
    _currentAnimeTitle = animeTitle;
    _currentPosterUrl = posterUrl;
    _currentTotalEpisodes = totalEpisodes;
    _hasMarkedCompleted = false;
    _hasMarkedWatching = false;

    _isLoading = true;
    _errorMessage = null;
    _streamLinks = [];
    _selectedStream = null;
    notifyListeners();

    try {
      debugPrint('🎬 [Player] Fetching streams for: ${episode.id}');
      List<StreamLink> links = await _anikotoService.extractStreams(episode.id);

      // 🛑 ONLY ONE FALLBACK BLOCK
      if (links.isEmpty) {
        debugPrint(
          '⚠️ [Player] Primary scraper failed. Trying Dynamic Gist...',
        );

        // Sanitize the ID strictly for the Vidtube fallback (e.g. "Dr. STONE" -> "dr-stone")
        final parts = episode.id.split('-ep-');
        final safeTitle = parts.first
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
            .replaceAll(RegExp(r'^-+|-+$'), '');
        final safeFallbackId =
            '$safeTitle-ep-${parts.length > 1 ? parts.last : '1'}';

        final dynamicStream = await _dynamicService.extractDynamicStream(
          embedUrl: 'https://vidtube.site/e/$safeFallbackId',
          cipherText: safeFallbackId,
        );
        if (dynamicStream != null) links.add(dynamicStream);
      }

      // Update the state with whatever we found
      _streamLinks = links;

      if (links.isNotEmpty) {
        // Let the UI handle stream selection (fixes background audio bug)
        _selectedStream = null;
      } else {
        _errorMessage = 'No streams found for this episode.';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('🚨 [Player] Error: $e');
      _errorMessage = 'An error occurred while fetching streams.';
      notifyListeners();
    }
  }

  void selectStream(StreamLink stream) {
    _selectedStream = stream;
    _isLoading = false;
    notifyListeners();

    final media = Media(stream.url, httpHeaders: stream.headers);
    player.open(media);

    if (_currentAnimeId != null) {
      final savedData = _historyService.getHistory(_currentAnimeId!);
      if (savedData != null && savedData['episodeId'] == _selectedEpisode?.id) {
        final int savedPos = savedData['positionMs'];
        if (savedPos > 0) {
          debugPrint("🕒 [History] Resuming at ${savedPos}ms");
          player.seek(Duration(milliseconds: savedPos));
        }
      }

      _startTrackingPosition();
    }
  }

  
  void _startTrackingPosition() {
    _positionSubscription?.cancel();
    _positionSubscription = player.stream.position.listen((position) {
      final now = DateTime.now();
      final duration = player.state.duration;

      if (now.difference(_lastSaveTime).inSeconds >= 5 &&
          _currentAnimeId != null &&
          _selectedEpisode != null) {
        _historyService.saveHistory(
          animeId: _currentAnimeId!,
          animeTitle: _currentAnimeTitle ?? 'Unknown',
          episodeId: _selectedEpisode!.id,
          episodeNumber: _selectedEpisode!.number,
          posterUrl: _currentPosterUrl ?? '',
          positionMs: position.inMilliseconds,
          durationMs: duration.inMilliseconds,
        );
        _lastSaveTime = now;
      }

      if (duration.inMilliseconds > 0 && _currentAnimeId != null) {
        final double progress = position.inMilliseconds / duration.inMilliseconds;
        
        // 1. Move to "Watching" after 5% of the episode is played
        if (progress > 0.05 && !_hasMarkedWatching) {
          _hasMarkedWatching = true;
          _libraryService.upsertFromPlayer(
            animeId: _currentAnimeId!,
            title: _currentAnimeTitle ?? 'Unknown',
            posterUrl: _currentPosterUrl ?? '',
            status: 'Watching',
            totalEpisodes: _currentTotalEpisodes,
          );
        }

        // 2. Move to "Completed" at 90% ONLY IF it's the final episode
        // 2. Move to "Completed" at 90% ONLY IF it's the final episode
        if (progress > 0.90 && !_hasMarkedCompleted) {
          _hasMarkedCompleted = true;
          final currentEpNum = _selectedEpisode?.number ?? 0; // 🛑 Removed int.tryParse
          
          if (_currentTotalEpisodes != null && currentEpNum == _currentTotalEpisodes) {
            debugPrint("🎉 [Player] Final episode finished! Auto-completing series.");
            _libraryService.upsertFromPlayer(
              animeId: _currentAnimeId!,
              title: _currentAnimeTitle ?? 'Unknown',
              posterUrl: _currentPosterUrl ?? '',
              status: 'Completed',
              totalEpisodes: _currentTotalEpisodes,
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    player.dispose();
    super.dispose();
  }
}
