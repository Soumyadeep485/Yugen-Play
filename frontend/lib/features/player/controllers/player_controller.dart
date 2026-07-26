import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/extensions/services/anikoto_extension_service.dart';
import 'package:frontend/features/extensions/services/dynamic_extension_service.dart';
// 🛑 Import MediaKit
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

  List<StreamLink> _streamLinks = [];
  StreamLink? _selectedStream;
  Episode? _selectedEpisode;
  bool _isLoading = false;
  String? _errorMessage;

  // 🛑 THE MISSING MEDIAKIT COMPONENTS
  late final Player player;
  late final VideoController videoController;

  PlayerController({
    required this.repository,
    required this.pluginRegistry,
    required this.pluginManager,
  }) {
    // 🛑 Initialize MediaKit inside the controller so the UI can access it
    player = Player();
    videoController = VideoController(player);
  }

  List<StreamLink> get streamLinks => _streamLinks;
  StreamLink? get selectedStream => _selectedStream;
  Episode? get selectedEpisode => _selectedEpisode;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchStreamsForEpisode(Episode episode) async {
    _selectedEpisode = episode;
    _isLoading = true;
    _errorMessage = null;
    _streamLinks = [];
    _selectedStream = null;
    notifyListeners();

    try {
      debugPrint('🎬 [Player] Fetching streams for: ${episode.id}');
      List<StreamLink> links = await _anikotoService.extractStreams(episode.id);

      if (links.isEmpty) {
        final dynamicStream = await _dynamicService.extractDynamicStream(
          embedUrl: 'https://vidtube.site/e/${episode.id}',
          cipherText: episode.id,
        );
        if (dynamicStream != null) links.add(dynamicStream);
      }

      _streamLinks = links;

      if (links.isNotEmpty) {
        // Auto-select and play the first stream
        selectStream(links.first);
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

    // 🛑 Pass the URL and required headers to media_kit so Cloudflare doesn't block it
    final media = Media(stream.url, httpHeaders: stream.headers);

    player.open(media);
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }
}
