import '../models/episode.dart';
import '../models/server.dart';
import '../models/stream_link.dart';
import '../services/stream_service.dart';
import 'streaming_provider.dart';

/// Repository responsible for all player-related data operations.
///
/// The UI should communicate only with this repository.
///
/// The repository delegates every operation to the currently
/// active provider managed by [StreamService].
///
/// Architecture:
///
/// PlayerScreen
///      │
///      ▼
/// PlayerRepository
///      │
///      ▼
/// StreamService
///      │
///      ▼
/// StreamingProvider
class PlayerRepository {
  const PlayerRepository({required this._streamService});

  final StreamService _streamService;

  /// Returns the currently active streaming provider.
  ///
  /// Throws a [StateError] if no provider has been selected.
  StreamingProvider get _provider {
    final provider = _streamService.currentProvider;

    if (provider == null) {
      throw StateError('No active streaming provider is available.');
    }

    return provider;
  }

  /// Fetches all available episodes for an AniList title.
  Future<List<Episode>> fetchEpisodes({required int anilistId}) async {
    return _provider.getEpisodes(anilistId: anilistId);
  }

  /// Fetches all available servers for an episode.
  Future<List<Server>> fetchServers({required Episode episode}) async {
    return _provider.getServers(episode: episode);
  }

  /// Fetches all playable stream links for the selected server.
  Future<List<StreamLink>> fetchStreamLinks({
    required Episode episode,
    required Server server,
  }) async {
    return _provider.getStreamLinks(episode: episode, server: server);
  }

  /// Returns whether the current provider is reachable.
  Future<bool> isProviderAvailable() async {
    return _provider.isAvailable();
  }

  /// Returns the display name of the active provider.
  String get providerName => _provider.name;

  @override
  String toString() {
    return 'PlayerRepository(provider: $providerName)';
  }
}
