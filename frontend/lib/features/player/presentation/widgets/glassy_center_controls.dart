import 'package:flutter/material.dart';

class GlassyCenterControls extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const GlassyCenterControls({
    super.key,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildGlassyCard(
            padding: const EdgeInsets.all(12),
            onTap: onPrevious,
            child: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 32),
          _buildGlassyCard(
            padding: const EdgeInsets.all(16),
            onTap: onPlayPause,
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(width: 32),
          _buildGlassyCard(
            padding: const EdgeInsets.all(12),
            onTap: onNext,
            child: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 36),
          ),
        ],
      ),
    );
  }

  // Self-contained UI Helper
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
}