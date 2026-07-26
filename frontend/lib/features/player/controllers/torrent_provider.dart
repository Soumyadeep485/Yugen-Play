import 'package:flutter_riverpod/flutter_riverpod.dart';
// Adjusted relative import based on the standard architecture tree (3 levels up to lib/)
import '../../../shared/models/anime.dart';

class TorrentStream {
  final String title;
  final String magnet;
  final String quality;
  final String size;
  final int seeders;

  TorrentStream({
    required this.title,
    required this.magnet,
    required this.quality,
    required this.size,
    required this.seeders,
  });
}

class TorrentNotifier extends Notifier<AsyncValue<List<TorrentStream>>> {
  @override
  AsyncValue<List<TorrentStream>> build() {
    return const AsyncValue.data([]);
  }

  Future<void> fetchAndFilterTorrents(
    Anime anime,
    int targetEpisode,
    int seasonNumber,
    String preferredQuality,
  ) async {
    state = const AsyncValue.loading();

    try {
      // Simulated API response delay from torrent indexer
      await Future.delayed(const Duration(seconds: 1));

      final rawApiResults = [
        "[SubsPlease] Shingeki no Kyojin - 60 (1080p) [HEVC].mkv",
        "[Erai-raws] Attack on Titan S04E01 [720p].mp4",
        "[HorribleSubs] Attack on Titan - 01 (1080p).mkv",
        "Shingeki no Kyojin The Final Season - Episode 01 1080p",
      ];

      List<TorrentStream> filteredStreams = [];

      for (var filename in rawApiResults) {
        if (!filename.contains(preferredQuality)) {
          continue;
        }

        final seasonEpRegex = RegExp(
          'S0?${seasonNumber}E0?$targetEpisode',
          caseSensitive: false,
        );

        final absoluteEp = 59 + targetEpisode;
        final absoluteRegex = RegExp(
          '(?: - | Episode | EP )\\b0?$absoluteEp\\b',
          caseSensitive: false,
        );

        final relativeRegex = RegExp(
          '(?: - | Episode | EP )\\b0?$targetEpisode\\b',
          caseSensitive: false,
        );

        bool matchesSeasonAndEp = seasonEpRegex.hasMatch(filename);
        bool matchesAbsolute = absoluteRegex.hasMatch(filename);
        bool matchesRelative =
            relativeRegex.hasMatch(filename) &&
            filename.toLowerCase().contains("final season");

        if (matchesSeasonAndEp || matchesAbsolute || matchesRelative) {
          filteredStreams.add(
            TorrentStream(
              title: filename,
              magnet: "magnet:?xt=urn:btih:fakehash_for_go_engine",
              quality: preferredQuality,
              size: "1.2 GB",
              seeders: 145,
            ),
          );
        }
      }

      filteredStreams.sort((a, b) => b.seeders.compareTo(a.seeders));
      state = AsyncValue.data(filteredStreams);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final torrentProvider =
    NotifierProvider<TorrentNotifier, AsyncValue<List<TorrentStream>>>(() {
      return TorrentNotifier();
    });