import 'package:flutter/material.dart';
import '../../../core/colors/app_colors.dart';
import '../../../core/radius/app_radius.dart';
import 'info_tab.dart';
import 'watch_tab.dart';

class AnimeDetailsModal extends StatelessWidget {
  final int animeId;
  final String animeTitle;
  final String heroTag;

  const AnimeDetailsModal({
    super.key,
    required this.animeId,
    required this.animeTitle,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      // Starts taking up 90% of the screen, can expand to 95% or shrink down
      initialChildSize: 0.90,
      minChildSize: 0.50,
      maxChildSize: 0.95,
      snap: true,
      // Prevents the sheet from closing itself immediately if the user scrolls down fast
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0D0D0F), // Matches our background layer
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
          ),
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                // The drag handle indicator at the top
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // The main content area where our tabs will render
                Expanded(
                  child: TabBarView(
                    children: [
                      // FIXED: INFO tab is first
                      InfoTab(
                        animeId: animeId,
                        scrollController: scrollController,
                      ),
                      // FIXED: WATCH tab is second
                      WatchTab(
                        animeId: animeId,
                        animeTitle: animeTitle,
                        scrollController: scrollController,
                      ),
                    ],
                  ),
                ),

                // The Saikou-style Bottom Anchored TabBar
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: const TabBar(
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: Colors.white54,
                      tabs: [
                        Tab(
                          iconMargin: EdgeInsets.only(bottom: 4),
                          icon: Icon(Icons.info_rounded),
                          text: "INFO",
                        ),
                        Tab(
                          iconMargin: EdgeInsets.only(bottom: 4),
                          icon: Icon(Icons.play_circle_fill_rounded),
                          text: "WATCH",
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
