import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/radius/app_radius.dart';
import 'glassy_player_screen.dart';
// Note: You'll link this to your video player in the next step
// import 'glassy_player_screen.dart';

class FindTorrentSheet extends StatelessWidget {
  final String animeTitle;
  final int episodeNumber;

  const FindTorrentSheet({
    super.key,
    required this.animeTitle,
    required this.episodeNumber,
  });

  // Dummy data mirroring your Migu reference image
  static const List<Map<String, dynamic>> _dummyTorrents = [
    {
      "group": "MTBB",
      "filename": "Shingeki no Kyojin - 01 (BD)",
      "size": "3.94 GB",
      "seeders": 152,
      "age": "2 years ago",
      "tags": ["1080p"],
      "isBest": false,
    },
    {
      "group": "TatakaeSubs",
      "filename": "Attack on Titan - S01E01 (BD OPUS) .mkv",
      "size": "2.36 GB",
      "seeders": 58,
      "age": "2 years ago",
      "tags": ["HEVC", "1080p"],
      "isBest": false,
    },
    {
      "group": "Erai-raws",
      "filename": "Shingeki no Kyojin - 01 [Multiple Subtitle]",
      "size": "1.24 GB",
      "seeders": 16,
      "age": "7 years ago",
      "tags": ["1080p"],
      "isBest": false,
    },
    {
      "group": "ZeroBuild",
      "filename": "Shingeki no Kyojin (Batch)",
      "size": "107.7 GB",
      "seeders": 0,
      "age": "2 years ago",
      "tags": ["Dual Audio", "Best Release"],
      "isBest": true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          height: MediaQuery.sizeOf(context).height * 0.90, // 90% screen height
          color: const Color(
            0xFF0D0D0F,
          ).withValues(alpha: 0.75), // Deep frosted glass
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 10, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Find Torrents",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Top Metadata / Auto-Selected highlight
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Auto-Selected Torrent",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // The Auto-Selected Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildTorrentCard(context, _dummyTorrents[0], true),
              ),

              const Padding(
                padding: EdgeInsets.all(20),
                child: Divider(color: Colors.white12, height: 1),
              ),

              // Filter Controls (Visual only for now)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTextFilter("Episode", episodeNumber.toString()),
                    _buildTextFilter("Resolution", "1080p"),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // The List of Torrents
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: _dummyTorrents.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildTorrentCard(
                      context,
                      _dummyTorrents[index],
                      false,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFilter(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Icon(Icons.arrow_drop_down_rounded, color: Colors.white54),
      ],
    );
  }

  Widget _buildTorrentCard(
    BuildContext context,
    Map<String, dynamic> torrent,
    bool isAutoSelected,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () {
          // 1. Close the bottom sheet first so it doesn't stay open underneath
          Navigator.pop(context);

          // 2. Launch the video player
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GlassyPlayerScreen(
                title:
                    torrent['filename'], // Pass the file name so the player shows it
                quality: (torrent['tags'] as List).isNotEmpty
                    ? torrent['tags'][0]
                    : "1080p",
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isAutoSelected
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    torrent['group'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.green,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                torrent['filename'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    "${torrent['size']} • ${torrent['seeders']} Seeders • ${torrent['age']}",
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  const Spacer(),
                  ...((torrent['tags'] as List<String>).map((tag) {
                    final isBest = tag == "Best Release";
                    return Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isBest
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: isBest ? Border.all(color: Colors.green) : null,
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: isBest ? Colors.greenAccent : Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  })),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
