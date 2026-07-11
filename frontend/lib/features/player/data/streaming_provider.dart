import '../models/episode.dart';
import '../models/server.dart';
import '../models/stream_link.dart';

/// Contract implemented by every streaming/media provider.
///
/// The player layer communicates only with this interface and never
/// with provider-specific implementations.
///
/// Examples of future implementations:
///
/// - JellyfinProvider
/// - PlexProvider
/// - LocalLibraryProvider
/// - CustomProvider
///
/// Every implementation is responsible for converting its own data
/// into the shared domain models.
///
/// The rest of the application remains completely provider-agnostic.
abstract interface class StreamingProvider {
  /// Human-readable provider name.
  ///
  /// Examples:
  /// - Jellyfin
  /// - Plex
  /// - Local Library
  String get name;

  /// Whether this provider requires user authentication.
  ///
  /// Example:
  /// - Jellyfin -> true
  /// - Plex -> true
  /// - Local Library -> false
  bool get requiresAuthentication;

  /// Whether this provider is currently available.
  ///
  /// Providers may perform health checks before returning `true`.
  Future<bool> isAvailable();

  /// Returns every available episode for an AniList title.
  ///
  /// [anilistId] is used as the canonical identifier throughout
  /// the application.
  Future<List<Episode>> getEpisodes({required int anilistId});

  /// Returns all available streaming servers for an episode.
  Future<List<Server>> getServers({required Episode episode});

  /// Resolves playable stream links for the selected server.
  ///
  /// Providers should return one or more playable streams ordered
  /// by preference.
  Future<List<StreamLink>> getStreamLinks({
    required Episode episode,
    required Server server,
  });
}
