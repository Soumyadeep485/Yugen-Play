import 'package:flutter/material.dart';

class GlassyGestureOverlay extends StatelessWidget {
  final bool isLocked;
  final bool showForwardRipple;
  final bool showRewindRipple;
  final VoidCallback onToggleControls;
  final ValueChanged<bool> onDoubleTapSeek;

  const GlassyGestureOverlay({
    super.key,
    required this.isLocked,
    required this.showForwardRipple,
    required this.showRewindRipple,
    required this.onToggleControls,
    required this.onDoubleTapSeek,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Row(
        children: [
          // Rewind Tap Zone
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onToggleControls,
              onDoubleTap: isLocked ? null : () => onDoubleTapSeek(false),
              child: AnimatedOpacity(
                opacity: showRewindRipple ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                        colors: [Colors.black54, Colors.transparent],
                        center: Alignment.center,
                        radius: 0.8),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fast_rewind_rounded,
                            color: Colors.white, size: 40),
                        SizedBox(height: 8),
                        Text("-10s",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Center Void (Just catches single taps to toggle UI)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onToggleControls,
            ),
          ),
          // Forward Tap Zone
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onToggleControls,
              onDoubleTap: isLocked ? null : () => onDoubleTapSeek(true),
              child: AnimatedOpacity(
                opacity: showForwardRipple ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                        colors: [Colors.black54, Colors.transparent],
                        center: Alignment.center,
                        radius: 0.8),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fast_forward_rounded,
                            color: Colors.white, size: 40),
                        SizedBox(height: 8),
                        Text("+10s",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}