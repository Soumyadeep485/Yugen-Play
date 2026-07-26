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
    final navItems = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.tv_rounded, 'label': 'Anime'},
      {'icon': Icons.extension_rounded, 'label': 'Sources'},
      {'icon': Icons.bookmark_rounded, 'label': 'Library'},
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 20, left: 24, right: 24),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: AppColors.card.withValues(alpha: 0.65),
          border: Border.all(
            color: AppColors.textPrimary.withValues(alpha: 0.12),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutQuint,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: isActive
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1,
                )
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
