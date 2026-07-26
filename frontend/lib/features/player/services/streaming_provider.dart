import '../models/episode.dart';
import '../models/server.dart';
import '../models/stream_link.dart';

/// Contract implemented by every streaming/media provider.
///
/// The player layer communicates only with this interface and never
/// with provider-specific implementations.
abstract interface class StreamingProvider {
  /// Human-readable provider name.
  String get name;

  /// Whether this provider requires user authentication.
  bool get requiresAuthentication;

  /// Whether this provider is currently available.
  Future<bool> isAvailable();

  /// Returns every available episode for an AniList title.
  Future<List<Episode>> getEpisodes({required int anilistId});

  /// Returns all available streaming servers for an episode.
  Future<List<Server>> getServers({required Episode episode});

  /// Resolves playable stream links for the selected server.
  Future<List<StreamLink>> getStreamLinks({
    required Episode episode,
    required Server server,
  });
}