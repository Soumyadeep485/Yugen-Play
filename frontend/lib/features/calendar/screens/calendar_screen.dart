import 'package:flutter/material.dart';
import '../../../core/radius/app_radius.dart';
import '../../../core/colors/app_colors.dart';
import '../../../shared/widgets/premium_network_image.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // Helper to generate a list of 7 DateTime objects for the current week (Mon-Sun)
  List<DateTime> _getCurrentWeek() {
    final now = DateTime.now();
    // In Dart, DateTime.monday == 1, sunday == 7.
    // Subtracting (weekday - 1) days takes us back to Monday.
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  // Formats the DateTime into your requested style: "Wed, 15-07-26"
  String _formatDate(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayName = weekdays[date.weekday - 1];
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = (date.year % 100).toString().padLeft(2, '0');

    return "$dayName, $day-$month-$year";
  }

  @override
  Widget build(BuildContext context) {
    final currentWeek = _getCurrentWeek();
    // Set the initial tab to today's day of the week
    final int initialTabIndex = DateTime.now().weekday - 1;

    return DefaultTabController(
      length: 7,
      initialIndex: initialTabIndex,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D0F),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D0D0F),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            "Calendar",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.white54,
            tabs: currentWeek
                .map((date) => Tab(text: _formatDate(date)))
                .toList(),
          ),
        ),
        body: TabBarView(
          children: List.generate(7, (dayIndex) {
            // When your API is ready, you will fetch the schedule for 'currentWeek[dayIndex]' here.

            return GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio:
                    0.50, // Taller to fit the episode and time text
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
              ),
              itemCount: 15, // Dummy count to fill the screen
              itemBuilder: (context, index) {
                // Passing structured data to the UI block
                return _buildCalendarCard(
                  title: "Oshi no Ko Season 2",
                  imageUrl: "", // Pass real URL here later
                  rating: 8.0,
                  episode: 3,
                  time: "23:00",
                );
              },
            );
          }),
        ),
      ),
    );
  }

  /// Data-driven Calendar Card ready for API integration
  Widget _buildCalendarCard({
    required String title,
    required String imageUrl,
    required double rating,
    required int episode,
    required String time,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Render the real image if a URL is provided, otherwise show the placeholder
                if (imageUrl.isNotEmpty)
                  PremiumNetworkImage(imageUrl: imageUrl, memCacheHeight: 350)
                else
                  Container(
                    color: Colors.white.withValues(alpha: 0.05),
                    child: const Icon(
                      Icons.image_rounded,
                      color: Colors.white24,
                      size: 32,
                    ),
                  ),

                // Saikou-style Rating Badge (Bottom Right, Pink/Accent Color)
                if (rating > 0)
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFFF2A7A,
                        ), // Hot pink accent for calendar
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.white,
                            size: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Episode Indicator Row
        Row(
          children: [
            const Icon(Icons.tv_rounded, color: Colors.white54, size: 12),
            const SizedBox(width: 4),
            Text(
              "EPISODE $episode",
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Anime Title
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),

        // Air Time
        Text(
          "~ | $time | ~",
          style: TextStyle(
            color: AppColors.primary.withValues(alpha: 0.8),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
