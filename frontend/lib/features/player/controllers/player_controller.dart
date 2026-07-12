import 'package:flutter/foundation.dart';
import '../models/subtitle_track.dart';
import '../data/player_repository.dart';
import '../models/episode.dart';
import '../models/server.dart';
import '../models/stream_link.dart';
import '../models/audio_track.dart';
import '../services/video_extraction_service.dart';

class PlayerController extends ChangeNotifier {
  PlayerController({
    required this.repository,
    required this.extractionService, // 🌟 INJECTED SERVICE
  });

  final PlayerRepository repository;
  final VideoExtractionService extractionService;

  bool _isLoading = false;
  String? _errorMessage;

  List<Episode> _episodes = [];
  List<Server> _servers = [];
  List<StreamLink> _streamLinks = [];
  final List<SubtitleTrack> _subtitleTracks = [];
  final List<AudioTrack> _audioTracks = [];

  List<SubtitleTrack> get subtitleTracks => List.unmodifiable(_subtitleTracks);

  Episode? _selectedEpisode;
  Server? _selectedServer;
  StreamLink? _selectedStream;
  SubtitleTrack? _selectedSubtitle;
  AudioTrack? _selectedAudio;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Episode> get episodes => List.unmodifiable(_episodes);
  List<Server> get servers => List.unmodifiable(_servers);
  List<StreamLink> get streamLinks => List.unmodifiable(_streamLinks);
  Episode? get selectedEpisode => _selectedEpisode;
  Server? get selectedServer => _selectedServer;
  StreamLink? get selectedStream => _selectedStream;
  SubtitleTrack? get selectedSubtitle => _selectedSubtitle;
  List<AudioTrack> get audioTracks => List.unmodifiable(_audioTracks);
  AudioTrack? get selectedAudio => _selectedAudio;
  bool get hasError => _errorMessage != null;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadEpisodes({required int anilistId}) async {
    await _execute(() async {
      _episodes = await repository.fetchEpisodes(anilistId: anilistId);
      if (_episodes.isNotEmpty) {
        _selectedEpisode = _episodes.first;
      }
    });
  }

  Future<void> loadServers() async {
    final episode = _selectedEpisode;
    if (episode == null) return;

    await _execute(() async {
      _servers = await repository.fetchServers(episode: episode);
      if (_servers.isNotEmpty) {
        _selectedServer = _servers.first;
      }
    });
  }

  // 🌟 UPDATED: Route stream extraction through the JS Engine
  Future<void> loadStreamLinks() async {
    final episode = _selectedEpisode;
    final server = _selectedServer;

    if (episode == null || server == null) return;

    await _execute(() async {
      // Pass the server's URL (e.g., the Gogoanime episode link) to the JS scraper
      // Note: Ensure your Server model exposes the target URL property
      _streamLinks = await extractionService.getPlayableStreams(server.url);

      if (_streamLinks.isNotEmpty) {
        _selectedStream = _streamLinks.first;
      } else {
        throw Exception(
          "Engine failed to extract video streams from the source.",
        );
      }
    });
  }

  void selectEpisode(Episode episode) {
    if (_selectedEpisode == episode) return;
    _selectedEpisode = episode;
    _selectedServer = null;
    _selectedStream = null;
    _servers = [];
    _streamLinks = [];
    notifyListeners();
  }

  void selectServer(Server server) {
    if (_selectedServer == server) return;
    _selectedServer = server;
    _selectedStream = null;
    _streamLinks = [];
    notifyListeners();

    // Auto-load streams when a user manually picks a new server
    loadStreamLinks();
  }

  void selectStream(StreamLink stream) {
    if (_selectedStream == stream) return;
    _selectedStream = stream;
    _selectedSubtitle = null;
    _selectedAudio = null;
    notifyListeners();
  }

  void selectSubtitle(SubtitleTrack subtitle) {
    if (_selectedSubtitle == subtitle) return;
    _selectedSubtitle = subtitle;
    notifyListeners();
  }

  void selectAudio(AudioTrack audio) {
    if (_selectedAudio == audio) return;
    _selectedAudio = audio;
    notifyListeners();
  }

  Future<void> _execute(Future<void> Function() operation) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await operation();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
