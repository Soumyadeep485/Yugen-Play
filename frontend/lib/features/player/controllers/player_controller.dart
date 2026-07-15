import 'package:flutter/foundation.dart';
import '../models/subtitle_track.dart';
import '../data/player_repository.dart';
import '../models/episode.dart';
import '../models/server.dart';
import '../models/stream_link.dart';
import '../models/audio_track.dart';
import '../models/plugin_meta.dart';
import '../data/registry/plugin_registry.dart';
import '../services/plugin_manager.dart';

class PlayerController extends ChangeNotifier {
  PlayerController({
    required this.repository,
    required this.pluginRegistry,
    required this.pluginManager,
  });

  final PlayerRepository repository;
  final PluginRegistry pluginRegistry;
  final PluginManager pluginManager;

  bool _isLoading = false;
  String? _errorMessage;

  List<Episode> _episodes = [];
  List<Server> _servers = [];
  List<StreamLink> _streamLinks = [];
  List<PluginMeta> _availablePlugins = [];
  List<PluginMeta> get availablePlugins => _availablePlugins;
  final List<SubtitleTrack> _subtitleTracks = [];
  final List<AudioTrack> _audioTracks = [];

  Episode? _selectedEpisode;
  Server? _selectedServer;
  StreamLink? _selectedStream;
  PluginMeta? _selectedPlugin;
  SubtitleTrack? _selectedSubtitle;
  AudioTrack? _selectedAudio;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Episode> get episodes => List.unmodifiable(_episodes);

  List<Server> get servers => List.unmodifiable(_servers);
  List<StreamLink> get streamLinks => List.unmodifiable(_streamLinks);
  List<SubtitleTrack> get subtitleTracks => List.unmodifiable(_subtitleTracks);
  List<AudioTrack> get audioTracks => List.unmodifiable(_audioTracks);

  Episode? get selectedEpisode => _selectedEpisode;
  Server? get selectedServer => _selectedServer;
  StreamLink? get selectedStream => _selectedStream;
  PluginMeta? get selectedPlugin => _selectedPlugin;
  SubtitleTrack? get selectedSubtitle => _selectedSubtitle;
  AudioTrack? get selectedAudio => _selectedAudio;

  bool get hasError => _errorMessage != null;

  Future<void> loadPlugins() async {
    await _execute(() async {
      _availablePlugins = await pluginRegistry.getActivePlugins();
      if (_availablePlugins.isNotEmpty) {
        _selectedPlugin = _availablePlugins.first;
      } else {
        _selectedPlugin = null;
      }
    });
  }

  void selectPlugin(PluginMeta plugin) {
    if (_selectedPlugin == plugin) return;
    _selectedPlugin = plugin;

    // Hard flush state when swapping providers to prevent ghost data
    _episodes = [];
    _servers = [];
    _streamLinks = [];
    _selectedEpisode = null;
    _selectedServer = null;
    _selectedStream = null;
    notifyListeners();

    if (_selectedServer != null) {
      loadStreamLinks();
    }
  }

  Future<void> loadEpisodes({required int anilistId}) async {
    await _execute(() async {
      // Flush previous grid data before starting the new network request
      _episodes = [];
      _selectedEpisode = null;

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
      // Flush previous servers before starting the new network request
      _servers = [];
      _selectedServer = null;

      _servers = await repository.fetchServers(episode: episode);
      if (_servers.isNotEmpty) {
        _selectedServer = _servers.first;
      }
    });
  }

  Future<void> loadStreamLinks() async {
    final server = _selectedServer;
    final plugin = _selectedPlugin;

    if (server == null) throw Exception("No server selected.");
    if (plugin == null) {
      throw Exception("No extraction plugin selected. Check Registry.");
    }

    await _execute(() async {
      // Flush previous streams before executing the JS extractor
      _streamLinks = [];
      _selectedStream = null;

      _streamLinks = await pluginManager.execute(plugin, server.url);

      if (_streamLinks.isNotEmpty) {
        _selectedStream = _streamLinks.first;
      } else {
        throw Exception("Plugin [${plugin.name}] failed to extract streams.");
      }
    });
  }

  void selectEpisode(Episode episode) {
    if (_selectedEpisode == episode && _servers.isNotEmpty) return;
    _selectedEpisode = episode;
    _selectedServer = null;
    _selectedStream = null;
    _servers = [];
    _streamLinks = [];
    notifyListeners();
    loadServers();
  }

  void selectServer(Server server) {
    if (_selectedServer == server) return;
    _selectedServer = server;
    _selectedStream = null;
    _streamLinks = [];
    notifyListeners();
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
