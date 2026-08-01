import 'dart:async';
import 'package:dio/dio.dart'; 
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
import '../../anime/services/anime_mapping_service.dart'; 

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
  final AnimeMappingService _mappingService = AnimeMappingService(); 

  List<StreamLink> _streamLinks = [];
  StreamLink? _selectedStream;
  Episode? _selectedEpisode;
  bool _isLoading = false;
  String? _errorMessage;
  int? _currentTotalEpisodes;
  bool _hasMarkedCompleted = false;
  bool _hasMarkedWatching = false;
  bool _hasFetchedSkipTimes = false;
  StreamSubscription? _durationSubscription;

  // AniSkip State Variables
  Duration? _introStart;
  Duration? _introEnd;
  Duration? _outroStart;
  Duration? _outroEnd;

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

  Duration? get introStart => _introStart;
  Duration? get introEnd => _introEnd;
  Duration? get outroStart => _outroStart;
  Duration? get outroEnd => _outroEnd;

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

    // Reset Skip Times for the new episode
    _introStart = null;
    _introEnd = null;
    _outroStart = null;
    _outroEnd = null;
    _hasFetchedSkipTimes = false;

    _isLoading = true;
    _errorMessage = null;
    _streamLinks = [];
    _selectedStream = null;
    notifyListeners();

    try {
      String targetEpisodeId = episode.id;
      bool isMapped = false;

      // 1. Try MAL-Sync Mapping
      if (episode.anilistId > 0) {
        final mappedSlug = await _mappingService.getExactSlug(episode.anilistId);
        if (mappedSlug != null && mappedSlug.isNotEmpty) {
          targetEpisodeId = '$mappedSlug-ep-${episode.number}';
          isMapped = true;
          debugPrint('🎯 [Player] Resolved exact ID via MAL-Sync: $targetEpisodeId');
        }
      }

      // 2. Fallback Sanitizer
      if (!isMapped) {
        final parts = targetEpisodeId.split('-ep-');
        String safeTitle = parts.first.toLowerCase();
        
        safeTitle = safeTitle.replaceAll('cour', 'part');
        safeTitle = safeTitle.replaceAll('nd season', '2');
        safeTitle = safeTitle.replaceAll('rd season', '3'); 
        safeTitle = safeTitle.replaceAll('th season', ''); 
        
        safeTitle = safeTitle
            .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
            .replaceAll(RegExp(r'^-+|-+$'), '');

        targetEpisodeId = '$safeTitle-ep-${parts.length > 1 ? parts.last : '1'}';
        debugPrint('🛠️ [Player] MAL-Sync missed. Sanitized ID for Anikoto: $targetEpisodeId');
      }

      // 3. Run primary scraper (passes animeTitle as fallback query candidate)
      debugPrint('🎬 [Player] Fetching streams for: $targetEpisodeId');
      List<StreamLink> links = await _anikotoService.extractStreams(
        targetEpisodeId, 
        animeTitle: animeTitle,
      );

      // 4. Dynamic Gist fallback if primary yields no links
      if (links.isEmpty) {
        debugPrint('⚠️ [Player] Primary scraper failed. Trying Dynamic Gist...');
        final dynamicStream = await _dynamicService.extractDynamicStream(
          embedUrl: 'https://vidtube.site/e/$targetEpisodeId',
          cipherText: targetEpisodeId,
        );
        if (dynamicStream != null) links.add(dynamicStream);
      }

      _streamLinks = links;

      if (links.isNotEmpty) {
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

  // ============================================================================
  // ANISKIP API INTEGRATION
  // ============================================================================
  Future<void> _fetchSkipTimes(int anilistId, int episodeNumber, int episodeLength) async {
    if (anilistId == 0) return;

    try {
      final dio = Dio();
      
      final alRes = await dio.post(
        'https://graphql.anilist.co',
        data: {
          'query': '''
            query (\$id: Int) {
              Media(id: \$id) {
                idMal
              }
            }
          ''',
          'variables': {'id': anilistId},
        },
      );

      final malId = alRes.data['data']?['Media']?['idMal'];
      if (malId == null) {
        debugPrint('⚠️ [AniSkip] No MAL ID found for AniList ID: $anilistId');
        return;
      }

      debugPrint('🔍 [AniSkip] Looking up MAL: $malId, Ep: $episodeNumber, Exact Length: ${episodeLength}s');

      Future<Response> fetchFromAniSkip(int length) {
        final url = 'https://api.aniskip.com/v2/skip-times/$malId/$episodeNumber'
            '?types[]=op&types[]=ed&types[]=mixed-op&types[]=mixed-ed&types[]=recap&episodeLength=$length';
            
        debugPrint('🌐 [AniSkip] Calling: $url');
        return dio.get(url, options: Options(validateStatus: (status) => true)); 
      }

      var skipRes = await fetchFromAniSkip(episodeLength);

      if (skipRes.statusCode == 404) {
        debugPrint('⚠️ [AniSkip] Exact length rejected. Falling back to generic length (0)...');
        skipRes = await fetchFromAniSkip(0);
      }

      if (skipRes.statusCode == 200 && skipRes.data['found'] == true) {
        final results = skipRes.data['results'] as List;
        debugPrint('✅ [AniSkip] Match found! Parsing ${results.length} timestamps...');
        
        for (var result in results) {
          final type = result['skipType'];
          final start = (result['interval']['startTime'] as num).toDouble();
          final end = (result['interval']['endTime'] as num).toDouble();

          if (type == 'op' || type == 'mixed-op') { 
            _introStart = Duration(milliseconds: (start * 1000).toInt());
            _introEnd = Duration(milliseconds: (end * 1000).toInt());
          } else if (type == 'ed' || type == 'mixed-ed') { 
            _outroStart = Duration(milliseconds: (start * 1000).toInt());
            _outroEnd = Duration(milliseconds: (end * 1000).toInt());
          }
        }
        notifyListeners(); 
      } else {
        debugPrint('❌ [AniSkip] Completely failed. Status: ${skipRes.statusCode}');
        debugPrint('❌ [AniSkip] Raw Response Body: ${skipRes.data}');
      }

    } catch (e) {
      debugPrint('🚨 [AniSkip] Fatal error during fetch: $e');
    }
  }

  void selectStream(StreamLink stream) {
    _selectedStream = stream;
    _isLoading = false;
    notifyListeners();

    final media = Media(stream.url, httpHeaders: stream.headers);
    player.open(media);

    _durationSubscription?.cancel();
    _durationSubscription = player.stream.duration.listen((duration) {
      if (duration.inMilliseconds > 0 && !_hasFetchedSkipTimes) {
        _hasFetchedSkipTimes = true;
        final lengthInSeconds = (duration.inMilliseconds / 1000).round();
        _fetchSkipTimes(int.tryParse(_currentAnimeId ?? '') ?? 0, _selectedEpisode?.number ?? 1, lengthInSeconds);
      }
    });

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

        if (progress > 0.90 && !_hasMarkedCompleted) {
          _hasMarkedCompleted = true;
          final currentEpNum = _selectedEpisode?.number ?? 0; 
          
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
    _durationSubscription?.cancel();
    player.dispose();
    super.dispose();
  }
}