import 'package:flutter/material.dart';
import 'pill_slider_thumb_shape.dart';

class GlassyBottomBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final Duration buffer;
  
  // 🚀 NEW: Dynamic Timestamps for Intro and Outro
  final Duration? introStart;
  final Duration? introEnd;
  final Duration? outroStart;
  final Duration? outroEnd;

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
    required this.buffer,
    this.introStart,
    this.introEnd,
    this.outroStart,
    this.outroEnd,
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
  double? _dragValue;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "${d.inHours > 0 ? '${d.inHours}:' : ''}$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final double maxDuration = widget.duration.inMilliseconds > 0 ? widget.duration.inMilliseconds.toDouble() : 1.0;
    final currentSliderValue = _dragValue ?? widget.position.inMilliseconds.toDouble().clamp(0.0, maxDuration);
    final displayPosition = Duration(milliseconds: currentSliderValue.toInt());
    final double bufferProgress = (widget.buffer.inMilliseconds / maxDuration).clamp(0.0, 1.0);

    // 🚀 SMART SKIP LOGIC
    final bool hasIntro = widget.introStart != null && widget.introEnd != null;
    final bool hasOutro = widget.outroStart != null && widget.outroEnd != null;

    final bool inIntro = hasIntro && currentSliderValue >= widget.introStart!.inMilliseconds && currentSliderValue < widget.introEnd!.inMilliseconds;
    final bool inOutro = hasOutro && currentSliderValue >= widget.outroStart!.inMilliseconds && currentSliderValue < widget.outroEnd!.inMilliseconds;

    final bool showDynamicSkip = inIntro || inOutro;
    final String skipText = inIntro ? "Skip Intro" : (inOutro ? "Skip Outro" : "+85s");
    
    // Shows +85s fallback if NO data exists. Otherwise, only shows button when inside the intro/outro zones.
    final bool showButton = showDynamicSkip || (!hasIntro && !hasOutro);

    return Positioned(
      bottom: MediaQuery.paddingOf(context).bottom + 16,
      left: 20,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 🚀 SMART SKIP BUTTON
          Align(
            alignment: Alignment.centerRight,
            child: AnimatedOpacity(
              opacity: showButton ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: IgnorePointer(
                  ignoring: !showButton,
                  child: _buildGlassyCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    onTap: () {
                      if (inIntro) {
                        widget.onSeek(widget.introEnd!);
                      } else if (inOutro) {
                        widget.onSeek(widget.outroEnd!);
                      } else {
                        widget.onSkipIntro(); // Fallback to +85s
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(skipText, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        if (showDynamicSkip) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.fast_forward_rounded, color: Colors.white, size: 16),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 🚀 LAYERED PILL SLIDER WITH HIGHLIGHTS
          Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0), 
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final trackWidth = constraints.maxWidth;

                    // Helper to mathematically place the yellow highlights
                    double getLeft(Duration start) => (start.inMilliseconds / maxDuration).clamp(0.0, 1.0) * trackWidth;
                    double getWidth(Duration start, Duration end) => ((end.inMilliseconds - start.inMilliseconds) / maxDuration).clamp(0.0, 1.0) * trackWidth;

                    return Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.centerLeft,
                      children: [
                        // 1. Buffer Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: bufferProgress,
                            minHeight: 8,
                            backgroundColor: Colors.white.withValues(alpha: 0.15), 
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.4)), 
                          ),
                        ),

                        // 2. Intro Highlight
                        if (hasIntro)
                          Positioned(
                            left: getLeft(widget.introStart!),
                            width: getWidth(widget.introStart!, widget.introEnd!),
                            height: 8,
                            child: Container(color: Colors.amber.withValues(alpha: 0.85)),
                          ),

                        // 3. Outro Highlight
                        if (hasOutro)
                          Positioned(
                            left: getLeft(widget.outroStart!),
                            width: getWidth(widget.outroStart!, widget.outroEnd!),
                            height: 8,
                            child: Container(color: Colors.amber.withValues(alpha: 0.85)),
                          ),
                      ],
                    );
                  },
                ),
              ),
              
              // 4. The Interactive Slider
              SliderTheme(
                data: const SliderThemeData(
                  trackHeight: 8,
                  activeTrackColor: Color(0xFFC4C4FF),
                  inactiveTrackColor: Colors.transparent, // Transparent to show buffer & highlights behind it
                  thumbColor: Color(0xFFC4C4FF),
                  thumbShape: PillSliderThumbShape(thumbWidth: 6, thumbHeight: 22),
                  overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
                  trackShape: RoundedRectSliderTrackShape(),
                ),
                child: Slider(
                  min: 0.0,
                  max: maxDuration,
                  value: currentSliderValue,
                  onChangeStart: (val) => setState(() => _dragValue = val),
                  onChanged: (val) => setState(() => _dragValue = val),
                  onChangeEnd: (val) {
                    widget.onSeek(Duration(milliseconds: val.toInt()));
                    setState(() => _dragValue = null);
                  },
                ),
              ),
            ],
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