import 'package:flutter/material.dart';
import 'package:frontend/src/rust/api/fetchers.dart';

class MiguTorrentCard extends StatelessWidget {
  final TorrentItem torrent;
  final VoidCallback onTap;

  const MiguTorrentCard({
    super.key,
    required this.torrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF141414), // Deep Material 3 dark surface
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Provider & Verified Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  torrent.provider,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                if (torrent.isVerified)
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.greenAccent,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // Middle Row: Full File Name
            Text(
              torrent.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),

            // Bottom Row: Metadata & Tags
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Metadata (Size, Seeders, Age)
                Expanded(
                  child: Text(
                    "${torrent.size} • ${torrent.seeders} Seeders • ${torrent.age}",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ),
                // Tags (AAC, 1080p, etc.)
                Wrap(
                  spacing: 6,
                  children: torrent.tags.map((tag) => _buildTag(tag)).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF222222), // Slightly lighter than background
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
