import '../models/episode.dart';
import '../models/server.dart';
import '../models/stream_link.dart';
import '../models/streaming_source.dart';
import 'stream_service.dart';
import 'mapping_service.dart';
import 'streaming_provider.dart';

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
    // 1. Fetch default servers from the active provider
    final List<Server> baseServers = await _provider.getServers(
      episode: episode,
    );

    // 2. Query MAL-Sync mapping service for Gogoanime URL
    final String? mappedUrl = await mappingService.getGogoanimeEpisodeUrl(
      episode.anilistId,
      episode.number,
    );

    // 3. Inject JS Extension server when mapping succeeds
    if (mappedUrl != null) {
      final jsEngineServer = Server(
        id: 'gogo_js_ext',
        name: 'Gogoanime (Extension)',
        url: mappedUrl,
        source: StreamingSource.custom,
      );

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