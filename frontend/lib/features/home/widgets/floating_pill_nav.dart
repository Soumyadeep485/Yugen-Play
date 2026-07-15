import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/colors/app_colors.dart';

enum MediaContext { anime, manga }

class FloatingPillNav extends StatelessWidget {
  final MediaContext currentContext;
  final ValueChanged<MediaContext> onContextChanged;
  final VoidCallback onProfilePressed;

  const FloatingPillNav({
    super.key,
    required this.currentContext,
    required this.onContextChanged,
    required this.onProfilePressed,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
              child: Container(
                height: 60,
                width: 260,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    // Anime Context Button
                    Expanded(
                      child: _NavPillButton(
                        label: 'ANIME',
                        isActive: currentContext == MediaContext.anime,
                        onTap: () => onContextChanged(MediaContext.anime),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Manga Context Button
                    Expanded(
                      child: _NavPillButton(
                        label: 'MANGA',
                        isActive: currentContext == MediaContext.manga,
                        onTap: () => onContextChanged(MediaContext.manga),
                      ),
                    ),
                    // Profile/Settings Trigger (Saikou Style)
                    IconButton(
                      icon: const Icon(
                        Icons.person_outline_rounded,
                        color: Colors.white70,
                        size: 24,
                      ),
                      onPressed: onProfilePressed,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavPillButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavPillButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        height: 44,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}
