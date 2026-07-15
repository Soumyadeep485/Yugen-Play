import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/colors/app_colors.dart';

class GlassyPlayerScreen extends StatelessWidget {
  final String title;
  final String quality;

  const GlassyPlayerScreen({
    super.key,
    required this.title,
    required this.quality,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Pure black for the video background
      body: Stack(
        children: [
          // 1. The "Video" Layer (Placeholder for actual video player surface)
          Center(
            child: Icon(
              Icons.play_circle_outline_rounded,
              size: 100,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),

          // 2. The Glassy Top Bar (Title & Back Button)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.paddingOf(context).top + 10,
                    bottom: 16,
                    left: 20,
                    right: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.black.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.primary),
                              ),
                              child: Text(
                                quality,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.settings_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. The Glassy Bottom Bar (Controls & Timeline)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.paddingOf(context).bottom + 20,
                    top: 20,
                    left: 20,
                    right: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.black.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Timeline Slider
                      Row(
                        children: [
                          const Text(
                            "00:00",
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 4,
                                activeTrackColor: AppColors.primary,
                                inactiveTrackColor: Colors.white.withValues(
                                  alpha: 0.2,
                                ),
                                thumbColor: AppColors.primary,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 14,
                                ),
                              ),
                              child: Slider(value: 0.0, onChanged: (val) {}),
                            ),
                          ),
                          const Text(
                            "24:00",
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Playback Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.skip_previous_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.replay_10_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                            child: IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.pause_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.forward_10_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.skip_next_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                    ],
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
