import 'package:flutter/material.dart';
import '../../../core/colors/app_colors.dart';
import '../../../core/radius/app_radius.dart';
import '../../search/screens/genres_screen.dart'; // <-- New Import
import '../../calendar/screens/calendar_screen.dart'; // <-- New Import

class FastFiltersMatrix extends StatelessWidget {
  const FastFiltersMatrix({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Horizontal Scroll Pill Selector
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _buildPillButton("This Season", true),
              const SizedBox(width: 8),
              _buildPillButton("Next Season", false),
              const SizedBox(width: 8),
              _buildPillButton("Previous Season", false),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 2. Large Image/Gradient Block Selectors (Genres & Calendar)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _buildMatrixCard(
                  title: "GENRES",
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
                  ),
                  icon: Icons.category_rounded,
                  onTap: () {
                    // Route to the new Genres screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GenresScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMatrixCard(
                  title: "CALENDAR",
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE74C3C), Color(0xFFF39C12)],
                  ),
                  icon: Icons.calendar_month_rounded,
                  onTap: () {
                    // Route to the new Calendar screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CalendarScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPillButton(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.black : Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMatrixCard({
    required String title,
    required LinearGradient gradient,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 65,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Stack(
          children: [
            Container(decoration: BoxDecoration(gradient: gradient)),
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                icon,
                size: 64,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: Center(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
