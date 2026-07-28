import 'package:flutter/material.dart';
import 'pill_slider_thumb_shape.dart';

class GlassyBottomBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final VoidCallback onSkipIntro;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onPlaylistPressed;
  final VoidCallback onSubtitlesPressed;
  final VoidCallback onQualityPressed;
  final VoidCallback onSpeedPressed;
  final VoidCallback onFitPressed;
  final VoidCallback onMoreOptionsPressed;

  const GlassyBottomBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSkipIntro,
    required this.onSeek,
    required this.onPlaylistPressed,
    required this.onSubtitlesPressed,
    required this.onQualityPressed,
    required this.onSpeedPressed,
    required this.onFitPressed,
    required this.onMoreOptionsPressed,
  });

  @override
  State<GlassyBottomBar> createState() => _GlassyBottomBarState();
}

class _GlassyBottomBarState extends State<GlassyBottomBar> {
  // Local state to track the slider while the user is actively dragging
  double? _dragValue;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "${d.inHours > 0 ? '${d.inHours}:' : ''}$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final double maxDuration = widget.duration.inMilliseconds > 0 ? widget.duration.inMilliseconds.toDouble() : 1.0;
    
    // If we are dragging, use the local drag value. Otherwise, use the actual player position.
    final currentSliderValue = _dragValue ?? widget.position.inMilliseconds.toDouble().clamp(0.0, maxDuration);
    final displayPosition = Duration(milliseconds: currentSliderValue.toInt());

    return Positioned(
      bottom: MediaQuery.paddingOf(context).bottom + 16,
      left: 20,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // +85s Skip Intro Button
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildGlassyCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                onTap: widget.onSkipIntro,
                child: const Text("+85s", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          ),

          // Custom Pill Slider
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 8,
              activeTrackColor: const Color(0xFFC4C4FF),
              inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
              thumbColor: const Color(0xFFC4C4FF),
              thumbShape: const PillSliderThumbShape(thumbWidth: 6, thumbHeight: 22),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              trackShape: const RoundedRectSliderTrackShape(),
            ),
            child: Slider(
              min: 0.0,
              max: maxDuration,
              value: currentSliderValue,
              onChangeStart: (val) {
                // Pause player stream updates and lock to finger
                setState(() => _dragValue = val);
              },
              onChanged: (val) {
                // Update UI instantly at 120fps (Does NOT seek the player yet)
                setState(() => _dragValue = val);
              },
              onChangeEnd: (val) {
                // Send the final seek command ONLY when the user lets go
                widget.onSeek(Duration(milliseconds: val.toInt()));
                setState(() => _dragValue = null);
              },
            ),
          ),
          const SizedBox(height: 8),

          // Time Indicators and Toolbar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildGlassyCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    // Use the dynamic displayPosition so the timestamp updates instantly while scrubbing
                    child: Text(_formatDuration(displayPosition), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  _buildGlassyCard(
                    padding: const EdgeInsets.all(8),
                    onTap: widget.onPlaylistPressed,
                    child: const Icon(Icons.playlist_play_rounded, color: Colors.white, size: 20),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildGlassyCard(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      children: [
                        _buildToolbarIcon(Icons.tune_rounded, widget.onSubtitlesPressed),
                        _buildToolbarIcon(Icons.cloud_outlined, widget.onQualityPressed),
                        _buildToolbarIcon(Icons.speed_rounded, widget.onSpeedPressed),
                        _buildToolbarIcon(Icons.aspect_ratio_rounded, widget.onFitPressed),
                        _buildToolbarIcon(Icons.open_in_new_rounded, widget.onMoreOptionsPressed),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildGlassyCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Text(_formatDuration(widget.duration), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Encapsulated UI Helpers
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

  Widget _buildToolbarIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}