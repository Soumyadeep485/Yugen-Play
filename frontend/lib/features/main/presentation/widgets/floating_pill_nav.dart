import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/colors/app_colors.dart';

class FloatingPillNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FloatingPillNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 1. The updated list with the Search icon
    final navItems = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.search_rounded, 'label': 'Search'}, 
      {'icon': Icons.extension_rounded, 'label': 'Sources'},
      {'icon': Icons.bookmark_rounded, 'label': 'Library'},
    ];

    return Padding(
      // Tighter side padding pulls the pill inward so it actually looks like it's floating
      padding: const EdgeInsets.only(bottom: 24, left: 32, right: 32),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: const Color(0xFF14141B).withValues(alpha: 0.8), // Darker, cleaner glass
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                // 2. spaceBetween fixes the awkward spacing
                mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                children: List.generate(navItems.length, (index) {
                  return _buildNavItem(
                    icon: navItems[index]['icon'] as IconData,
                    label: navItems[index]['label'] as String,
                    index: index,
                    context: context,
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required BuildContext context,
  }) {
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive 
                ? AppColors.primary.withValues(alpha: 0.4) 
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.primary : Colors.white54,
              size: 24,
            ),
            // 3. Bulletproof Animation Logic
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              alignment: Alignment.centerLeft, // Anchors the text so it slides right
              child: SizedBox(
                // Forces the width to exactly 0 when inactive to prevent layout jumps
                width: isActive ? null : 0, 
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 8),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}