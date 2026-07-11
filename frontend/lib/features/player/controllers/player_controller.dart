import 'package:flutter/foundation.dart';
import '../models/subtitle_track.dart';
import '../data/player_repository.dart';
import '../models/episode.dart';
import '../models/server.dart';
import '../models/stream_link.dart';
import '../models/audio_track.dart';

/// Controls the state of the player feature.
///
/// The controller is responsible for:
///
/// - Loading episodes
/// - Loading servers
/// - Loading stream links
/// - Managing loading and error states
/// - Managing current selections
///
/// The UI should interact only with this controller.
/// Networking and provider communication remain inside
/// [PlayerRepository].
class PlayerController extends ChangeNotifier {
  PlayerController({required this.repository});

  final PlayerRepository repository;

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

  /// Whether the controller is currently performing an operation.
  bool get isLoading => _isLoading;

  /// Current error message.
  String? get errorMessage => _errorMessage;

  /// Available episodes.
  List<Episode> get episodes => List.unmodifiable(_episodes);

  /// Available servers.
  List<Server> get servers => List.unmodifiable(_servers);

  /// Available stream links.
  List<StreamLink> get streamLinks => List.unmodifiable(_streamLinks);

  /// Currently selected episode.
  Episode? get selectedEpisode => _selectedEpisode;

  /// Currently selected server.
  Server? get selectedServer => _selectedServer;

  /// Currently selected stream.
  StreamLink? get selectedStream => _selectedStream;

  /// Currently selected subtitle track.
  SubtitleTrack? get selectedSubtitle => _selectedSubtitle;

  /// Available audio tracks.
  List<AudioTrack> get audioTracks => List.unmodifiable(_audioTracks);

  /// Currently selected audio track.
  AudioTrack? get selectedAudio => _selectedAudio;

  /// Whether an error is currently present.
  bool get hasError => _errorMessage != null;

  /// Clears the current error.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Loads all episodes for an AniList title.
  Future<void> loadEpisodes({required int anilistId}) async {
    await _execute(() async {
      _episodes = await repository.fetchEpisodes(anilistId: anilistId);

      if (_episodes.isNotEmpty) {
        _selectedEpisode = _episodes.first;
      }
    });
  }

  /// Loads all servers for the currently selected episode.
  Future<void> loadServers() async {
    final episode = _selectedEpisode;

    if (episode == null) {
      return;
    }

    await _execute(() async {
      _servers = await repository.fetchServers(episode: episode);

      if (_servers.isNotEmpty) {
        _selectedServer = _servers.first;
      }
    });
  }

  /// Loads all playable stream links.
  Future<void> loadStreamLinks() async {
    final episode = _selectedEpisode;
    final server = _selectedServer;

    if (episode == null || server == null) {
      return;
    }

    await _execute(() async {
      _streamLinks = await repository.fetchStreamLinks(
        episode: episode,
        server: server,
      );

      if (_streamLinks.isNotEmpty) {
        _selectedStream = _streamLinks.first;
      }
    });
  }

  /// Selects an episode.
  ///
  /// Clears any server and stream selections.
  void selectEpisode(Episode episode) {
    if (_selectedEpisode == episode) {
      return;
    }

    _selectedEpisode = episode;
    _selectedServer = null;
    _selectedStream = null;

    _servers = [];
    _streamLinks = [];

    notifyListeners();
  }

  /// Selects a server.
  ///
  /// Clears any previously selected stream.
  void selectServer(Server server) {
    if (_selectedServer == server) {
      return;
    }

    _selectedServer = server;
    _selectedStream = null;

    _streamLinks = [];

    notifyListeners();
  }

  /// Selects a playable stream.
  void selectStream(StreamLink stream) {
    if (_selectedStream == stream) {
      return;
    }

    _selectedStream = stream;

    // Tracks belong to a stream.
    _selectedSubtitle = null;
    _selectedAudio = null;

    notifyListeners();
  }

  /// Selects a subtitle track.
  void selectSubtitle(SubtitleTrack subtitle) {
    if (_selectedSubtitle == subtitle) {
      return;
    }

    _selectedSubtitle = subtitle;

    notifyListeners();
  }

  /// Selects an audio track.
  void selectAudio(AudioTrack audio) {
    if (_selectedAudio == audio) {
      return;
    }

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
