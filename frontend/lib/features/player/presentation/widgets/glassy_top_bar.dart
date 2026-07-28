import 'package:flutter/material.dart';
import '../../../../core/colors/app_colors.dart';

class GlassyTopBar extends StatelessWidget {
  final String animeTitle;
  final String epTitle;
  final String fullTitle;
  final String quality;
  final bool isLocked;
  final VoidCallback onBack;
  final VoidCallback onLockToggle;
  final VoidCallback onPipPressed;
  final VoidCallback onSettingsPressed;

  const GlassyTopBar({
    super.key,
    required this.animeTitle,
    required this.epTitle,
    required this.fullTitle,
    required this.quality,
    required this.isLocked,
    required this.onBack,
    required this.onLockToggle,
    required this.onPipPressed,
    required this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    // If the screen is locked, only show the locked icon on the right
    if (isLocked) {
      return Positioned(
        top: MediaQuery.paddingOf(context).top + 16,
        right: 20,
        child: _buildGlassyCard(
          padding: const EdgeInsets.all(8),
          onTap: onLockToggle,
          child: const Icon(Icons.lock_rounded, color: AppColors.primary, size: 20),
        ),
      );
    }

    // Unlocked Top Bar UI
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 16,
      left: 20,
      right: 20,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGlassyCard(
            padding: const EdgeInsets.all(8),
            onTap: onBack,
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  epTitle.length > 20 ? epTitle : fullTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildChip(animeTitle),
                    const SizedBox(width: 6),
                    _buildChip(epTitle),
                    const SizedBox(width: 6),
                    _buildChip(quality),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildGlassyCard(
                padding: const EdgeInsets.all(8),
                onTap: onLockToggle,
                child: const Icon(Icons.lock_open_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              _buildGlassyCard(
                padding: const EdgeInsets.all(8),
                onTap: onPipPressed,
                child: const Icon(Icons.picture_in_picture_alt_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              _buildGlassyCard(
                padding: const EdgeInsets.all(8),
                onTap: onSettingsPressed,
                child: const Icon(Icons.settings_rounded, color: Colors.white, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Self-contained UI Helpers
  Widget _buildGlassyCard({required Widget child, required EdgeInsets padding, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: const Color(0xFF14141B).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(14),
        ),
        child: child,
      ),
    );
  }

  Widget _buildChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF332D41),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFFB39DDB), fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}