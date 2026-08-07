import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'package:frontend/features/player/services/extension_manager.dart'; 
import '../../library/services/library_service.dart';
import 'package:frontend/features/history/services/watch_history_service.dart';
import '../../../../service_locator.dart';
import '../models/episode.dart';
import '../models/stream_link.dart';
// 🚀 THE FIX: We alias your local model so it stops clashing with media_kit!
import '../models/subtitle_track.dart' as app_model; 
import '../services/player_repository.dart';
import '../services/plugin_manager.dart';
import '../services/plugin_registry.dart';
import '../../anime/services/anime_mapping_service.dart'; 

import 'package:frontend/features/player/services/local_stream_proxy.dart';

final playerControllerProvider = Provider<PlayerController>((ref) {
  throw UnimplementedError('Initialize this with your dependencies');
});

class PlayerController extends ChangeNotifier {
  final PlayerRepository repository;
  final PluginRegistry pluginRegistry;
  final PluginManager pluginManager;

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
  StreamSubscription? _playingSubscription;

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
    
    LocalStreamProxy().start(); 
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

  void _forceSaveHistory() {
    try {
      final livePosition = player.state.position;
      final liveDuration = player.state.duration;

      if (_currentAnimeId != null && 
          _selectedEpisode != null && 
          livePosition.inMilliseconds > 0 && 
          liveDuration.inMilliseconds > 0) {
          
        _historyService.saveHistory(
          animeId: _currentAnimeId!,
          animeTitle: _currentAnimeTitle ?? 'Unknown',
          episodeId: _selectedEpisode!.id,
          episodeNumber: _selectedEpisode!.number,
          posterUrl: _currentPosterUrl ?? '',
          positionMs: livePosition.inMilliseconds,
          durationMs: liveDuration.inMilliseconds,
        );
        
        _lastSaveTime = DateTime.now();
      }
    } catch (e) {
      debugPrint("🚨 [History] Failed to force save: $e");
    }
  }

  void addStreamLink(StreamLink link) {
    if (!_streamLinks.any((s) => s.url == link.url)) {
      _streamLinks.add(link);
      notifyListeners();
    }
  }

  Future<List<StreamLink>> loadStreamsForEpisode({
    required Episode episode,
    required String animeId,
    required String animeTitle,
    required String posterUrl,
    int? totalEpisodes,
  }) async {
    _forceSaveHistory(); 

    _selectedEpisode = episode;
    _currentAnimeId = animeId;
    _currentAnimeTitle = animeTitle;
    _currentPosterUrl = posterUrl;
    _currentTotalEpisodes = totalEpisodes;
    _hasMarkedCompleted = false;
    _hasMarkedWatching = false;

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
      final extManager = locator<ExtensionManager>();
      final activeExtension = extManager.activeExtensions[episode.providerId];

      if (activeExtension == null) {
        _errorMessage = 'Extension ${episode.providerId} is not installed or active.';
        notifyListeners();
        return [];
      }

      String targetEpisodeId = episode.id;

      if (episode.anilistId > 0 && !targetEpisodeId.contains('-ep-')) {
        final mappedSlug = await _mappingService.getExactSlug(episode.anilistId);
        if (mappedSlug != null && mappedSlug.isNotEmpty) {
          targetEpisodeId = '$mappedSlug-ep-${episode.number}';
        }
      }

      final links = await activeExtension.extractStreams(targetEpisodeId, animeTitle: animeTitle);
      _streamLinks = links;

      if (links.isEmpty) {
        _errorMessage = 'No streams found from ${activeExtension.name}.';
      }
      
      _isLoading = false;
      notifyListeners();
      return links;

    } catch (e) {
      _errorMessage = 'An error occurred while fetching streams.';
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

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
      if (malId == null) return;

      Future<Response> fetchFromAniSkip(int length) {
        final url = 'https://api.aniskip.com/v2/skip-times/$malId/$episodeNumber'
            '?types[]=op&types[]=ed&types[]=mixed-op&types[]=mixed-ed&types[]=recap&episodeLength=$length';
        return dio.get(url, options: Options(validateStatus: (status) => true)); 
      }

      var skipRes = await fetchFromAniSkip(episodeLength);

      if (skipRes.statusCode == 404) {
        skipRes = await fetchFromAniSkip(0);
      }

      if (skipRes.statusCode == 200 && skipRes.data['found'] == true) {
        final results = skipRes.data['results'] as List;
        
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
      }
    } catch (e) {
      debugPrint('🚨 [AniSkip] Error: $e');
    }
  }

  void selectStream(StreamLink stream, {Duration? startPosition}) {
    final headers = Map<String, String>.from(stream.headers);
    final proxiedVideoUrl = LocalStreamProxy().getProxyUrl(stream.url, headers);
    
    final proxiedSubtitles = stream.subtitles.map((sub) {
      if (sub.url.startsWith('http')) {
        // 🚀 THE FIX: Use our new 'app_model' alias here so Dart doesn't cry
        return app_model.SubtitleTrack(
          id: sub.id,
          label: sub.label,
          url: LocalStreamProxy().getProxyUrl(sub.url, headers),
          language: sub.language,
          isDefault: sub.isDefault,
        );
      }
      return sub;
    }).toList();

    final proxiedStream = stream.copyWith(
      url: proxiedVideoUrl,
      subtitles: proxiedSubtitles,
    );

    _selectedStream = proxiedStream;
    addStreamLink(proxiedStream);
    _isLoading = false;
    notifyListeners();

    try {
      (player.platform as dynamic)?.setProperty('osd-level', '0');
    } catch (_) {}

    final media = Media(proxiedStream.url);
    player.open(media);

    if (proxiedStream.subtitles.isNotEmpty) {
      try {
        final bestSub = proxiedStream.subtitles.firstWhere(
          (s) {
            final label = s.label.toLowerCase(); 
            return label.contains('eng') || label.contains('en');
          },
          orElse: () => proxiedStream.subtitles.first,
        );
        
        Future.delayed(const Duration(milliseconds: 500), () {
          try {
            // Notice how this one still uses media_kit's SubtitleTrack natively!
            player.setSubtitleTrack(SubtitleTrack.uri(bestSub.url));
            debugPrint('✅ [Player] Auto-loaded external subtitle: ${bestSub.label}');
          } catch (e) {
            debugPrint('⚠️ [Player] Delayed subtitle load failed: $e');
          }
        });
        
      } catch (e) {
        debugPrint('⚠️ [Player] Failed to load external subtitle: $e');
        player.setSubtitleTrack(SubtitleTrack.auto()); 
      }
    } else {
      debugPrint('ℹ️ [Player] No external subtitles found. Falling back to embedded tracks.');
      player.setSubtitleTrack(SubtitleTrack.auto()); 
    }

    if (startPosition != null && startPosition.inMilliseconds > 2000) {
      StreamSubscription? safeSeekSub;
      safeSeekSub = player.stream.duration.listen((duration) {
        if (duration.inMilliseconds > 0) {
          safeSeekSub?.cancel();
          Future.delayed(const Duration(milliseconds: 300), () {
            try {
              player.seek(startPosition);
            } catch (e) {
              debugPrint('⚠️ [Seek Error]: $e');
            }
          });
        }
      });
    }

    _playingSubscription?.cancel();
    _playingSubscription = player.stream.playing.listen((isPlaying) {
      if (!isPlaying) {
        _forceSaveHistory();
      }
    });

    _durationSubscription?.cancel();
    _durationSubscription = player.stream.duration.listen((duration) {
      if (duration.inMilliseconds > 0 && !_hasFetchedSkipTimes) {
        _hasFetchedSkipTimes = true;
        final lengthInSeconds = (duration.inMilliseconds / 1000).round();

        Future.delayed(const Duration(seconds: 2), () {
          _fetchSkipTimes(int.tryParse(_currentAnimeId ?? '') ?? 0, _selectedEpisode?.number ?? 1, lengthInSeconds);
        });
      }
    });

    if (_currentAnimeId != null) {
      _startTrackingPosition();
    }
  }

  void _startTrackingPosition() {
    _positionSubscription?.cancel();
    
    _positionSubscription = player.stream.position
        .map((p) => p.inSeconds)
        .distinct()
        .listen((second) {
      final position = Duration(seconds: second);
      final now = DateTime.now();
      final duration = player.state.duration;

      if (now.difference(_lastSaveTime).inSeconds >= 60 &&
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
    _forceSaveHistory();
    _playingSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    player.dispose();
    
    LocalStreamProxy().stop();
    
    super.dispose();
  }
}