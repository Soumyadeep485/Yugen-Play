import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/core/storage/hive_boxes.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../shared/models/anime.dart';

class InfoTab extends StatelessWidget {
  final Anime anime;
  final String? libraryStatus;
  final VoidCallback onLibraryTap;

  const InfoTab({
    super.key,
    required this.anime,
    required this.libraryStatus,
    required this.onLibraryTap,
  });

  String _formatTime(int totalMinutes) {
    if (totalMinutes <= 0) return "-";
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) {
      return "${hours}h ${minutes}m";
    }
    return "${minutes}m";
  }

  @override
  Widget build(BuildContext context) {
    final ratingText = anime.rating != null ? "${anime.rating!.toStringAsFixed(1)}/10" : "N/A";
    final statusText = anime.status ?? "N/A";
    final episodesText = anime.episodes != null ? "${anime.episodes}" : "N/A";
    final synopsisText = (anime.description != null && anime.description!.isNotEmpty)
        ? anime.description!
        : "No synopsis available.";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          // ==========================================
          // 1. ADD TO LIBRARY BUTTON
          // ==========================================
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: onLibraryTap,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
              icon: Icon(
                libraryStatus != null ? Icons.my_library_books_rounded : Icons.menu_book_rounded,
                size: 18,
              ),
              label: Text(
                libraryStatus ?? "Add to Library",
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
          
          const SizedBox(height: 16),

          // ==========================================
          // 2. WATCH TRACKING CARD (Reactive)
          // ==========================================
          ValueListenableBuilder(
            valueListenable: Hive.box<String>(HiveBoxes.continueWatching).listenable(),
            builder: (context, box, child) {
              final rawHistory = box.get(anime.id.toString());
              
              int currentEp = 0;
              double progress = 0.0;

              if (rawHistory != null) {
                final data = jsonDecode(rawHistory);
                currentEp = data['episodeNumber'] ?? 0;
                final int pos = data['positionMs'] ?? 0;
                final int dur = data['durationMs'] ?? 1;
                progress = (pos / dur).clamp(0.0, 1.0);
              }

              final totalEps = anime.episodes ?? 0;
              final hasTotal = totalEps > 0;
              
              // Assuming average of 24 mins per episode for the calculations
              final totalMinutes = hasTotal ? totalEps * 24 : 0;
              final watchedMinutes = currentEp * 24;
              final remainingMinutes = hasTotal ? (totalMinutes - watchedMinutes) : 0;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Episode X of Y + Percentage Pill
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.movie_creation_outlined, color: AppColors.textSecondary, size: 16),
                            const SizedBox(width: 8),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                children: [
                                  const TextSpan(text: "Episode "),
                                  TextSpan(
                                    text: "$currentEp", 
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                                  ),
                                  const TextSpan(text: " of "),
                                  TextSpan(
                                    text: hasTotal ? "$totalEps" : "?", 
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${(progress * 100).toStringAsFixed(2)}%",
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Bottom Row: Total / Watched / Remaining
                    Row(
                      children: [
                        Expanded(child: _buildTimeBlock("Total", _formatTime(totalMinutes))),
                        const SizedBox(width: 8),
                        Expanded(child: _buildTimeBlock("Watched", currentEp > 0 ? _formatTime(watchedMinutes) : "-")),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTimeBlock(
                            "Remaining", 
                            hasTotal ? _formatTime(remainingMinutes) : "-", 
                            highlight: true
                          )
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // ==========================================
          // 3. STATISTICS DROPDOWN REPLICA
          // ==========================================
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                iconColor: Colors.white,
                collapsedIconColor: Colors.white70,
                title: const Row(
                  children: [
                    Icon(Icons.bar_chart_rounded, color: Colors.white70, size: 20),
                    SizedBox(width: 12),
                    Text(
                      "Statistics",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    child: GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: [
                        _buildStatCard("Status", statusText),
                        _buildStatCard("Rating", ratingText),
                        _buildStatCard("Episodes", episodesText),
                        _buildStatCard("ID", anime.id),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ==========================================
          // 4. SYNOPSIS
          // ==========================================
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: true,
                iconColor: Colors.white,
                collapsedIconColor: Colors.white70,
                title: const Row(
                  children: [
                    Icon(Icons.description_outlined, color: Colors.white70, size: 20),
                    SizedBox(width: 12),
                    Text(
                      "Synopsis",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    child: Text(
                      synopsisText.replaceAll("<br>", "\n"), // Clean up dirty HTML tags from Anilist
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBlock(String label, String value, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: highlight ? const Color(0xFFFFA2A2) : Colors.white, // Light reddish tint for Remaining
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}