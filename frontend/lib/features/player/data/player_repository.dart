import '../models/episode.dart';
import '../models/server.dart';
import '../models/stream_link.dart';
import '../services/stream_service.dart';
import '../services/mapping_service.dart'; // 🌟 NEW IMPORT
import 'streaming_provider.dart';
import 'streaming_source.dart';

/// Repository responsible for all player-related data operations.
///
/// Architecture:
/// PlayerScreen -> PlayerRepository -> [MappingService] -> StreamService -> StreamingProvider
class PlayerRepository {
  const PlayerRepository({
    required this.streamService,
    required this.mappingService,
  });

  final StreamService streamService;
  final MappingService mappingService;

  StreamingProvider get _provider {
    final provider = streamService.currentProvider;

    if (provider == null) {
      throw StateError('No active streaming provider is available.');
    }

    return provider;
  }

  Future<List<Episode>> fetchEpisodes({required int anilistId}) async {
    return _provider.getEpisodes(anilistId: anilistId);
  }

  Future<List<Server>> fetchServers({required Episode episode}) async {
    // 1. Fetch any default servers your current provider might have
    final List<Server> baseServers = await _provider.getServers(
      episode: episode,
    );

    // 2. Query MAL-Sync for the exact Gogoanime scraping URL
    // NOTE: This assumes your Episode model has 'anilistId' and 'number' properties.
    final String? mappedUrl = await mappingService.getGogoanimeEpisodeUrl(
      episode.anilistId,
      episode.number,
    );

    // 3. If the mapping is successful, inject the JavaScript-powered server into the list
    if (mappedUrl != null) {
      final jsEngineServer = Server(
        id: 'gogo_js_ext',
        name: 'Gogoanime (Extension)',
        url: mappedUrl, // 🌟 The crucial string your JS engine needs
        // Check your streaming_source.dart file to see what the exact name is.
        // It will likely be one of these formats:
        source: StreamingSource.custom,

        // OR if your app uses a string-key factory based on your previous server.dart file:
        // source: StreamingSource.fromKey('gogoanime'),
      );

      // Return the new server at the top of the list
      return [jsEngineServer, ...baseServers];
    }

    return baseServers;
  }

  Future<List<StreamLink>> fetchStreamLinks({
    required Episode episode,
    required Server server,
  }) async {
    return _provider.getStreamLinks(episode: episode, server: server);
  }

  Future<bool> isProviderAvailable() async {
    return _provider.isAvailable();
  }

  String get providerName => _provider.name;

  @override
  String toString() {
    return 'PlayerRepository(provider: $providerName)';
  }
}
