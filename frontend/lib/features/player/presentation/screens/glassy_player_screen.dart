import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:media_kit/media_kit.dart' hide SubtitleTrack, AudioTrack;
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../src/rust/api/torrent.dart';
import '../../controllers/player_controller.dart';
import '../../models/stream_link.dart';
import '../../models/subtitle_track.dart';
import '../widgets/stream_quality_bottom_sheet.dart';
import '../widgets/subtitle_selector_sheet.dart';

class GlassyPlayerScreen extends StatefulWidget {
  final String title;
  final String quality;
  final String streamUrl;
  final PlayerController playerController;
  
  // 🛑 LOGIC CALLBACKS ADDED HERE
  final VoidCallback? onNextEpisode;
  final VoidCallback? onPreviousEpisode;

  const GlassyPlayerScreen({
    super.key,
    required this.title,
    required this.quality,
    required this.streamUrl,
    required this.playerController,
    this.onNextEpisode,
    this.onPreviousEpisode,
  });

  @override
  State<GlassyPlayerScreen> createState() => _GlassyPlayerScreenState();
}

class _GlassyPlayerScreenState extends State<GlassyPlayerScreen> {
  Player get _player => widget.playerController.player;
  VideoController get _videoController => widget.playerController.videoController;

  final List<StreamSubscription> _subscriptions = [];
  TorrentEngine? _rustEngine;
  Timer? _controlsTimer;

  bool _isBuffering = true;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _hasSetSubtitle = false;
  bool _isLocked = false;

  // Visual feedback states
  bool _showForwardRipple = false;
  bool _showRewindRipple = false;
  
  // Customization States
  double _playbackSpeed = 1.0;
  BoxFit _currentFit = BoxFit.contain;

  // Toast State
  String? _toastMessage;
  Timer? _toastTimer;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _setupPlayerListeners();

    if (widget.streamUrl.startsWith('magnet:')) {
      _setupTorrentStream(widget.streamUrl);
    } else {
      _isPlaying = _player.state.playing;
      _isBuffering = _player.state.buffering;
      _position = _player.state.position;
      _duration = _player.state.duration;

      if (_isPlaying && !_hasSetSubtitle) {
        _hasSetSubtitle = true;
        _injectSubtitle();
      }
    }

    _resetControlsTimer();
  }

  Future<void> _injectSubtitle() async {
    final stream = widget.playerController.selectedStream;
    if (stream == null || stream.subtitles.isEmpty) {
      return;
    }

    try {
      final sub = stream.subtitles.firstWhere(
        (s) {
          final json = s.toJson();
          final label = (json['label'] ?? json['name'] ?? '').toString().toLowerCase();
          return label.contains('eng');
        },
        orElse: () => stream.subtitles.first,
      );

      final subJson = sub.toJson();
      final subUrl = subJson['url']?.toString() ?? subJson['file']?.toString() ?? '';
      final subLabel = subJson['label']?.toString() ?? 'English';

      if (subUrl.isNotEmpty) {
        final res = await http.get(Uri.parse(subUrl), headers: stream.headers);
        if (res.statusCode == 200) {
          final tempDir = await getTemporaryDirectory();
          final subFile = File('${tempDir.path}/yugen_sub_${DateTime.now().millisecondsSinceEpoch}.vtt');
          await subFile.writeAsString(res.body);

          _player.setSubtitleTrack(mk.SubtitleTrack.uri(
            subFile.uri.toString(),
            title: subLabel,
            language: 'en',
          ));
        } else {
          _player.setSubtitleTrack(mk.SubtitleTrack.uri(subUrl, title: subLabel, language: 'en'));
        }
      }
    } catch (e) {
      debugPrint("🚨 [MediaKit] Failed to brute-force subtitle: $e");
    }
  }

  void _setupPlayerListeners() {
    _subscriptions.addAll([
      _player.stream.position.listen((pos) {
        if (mounted) {
          setState(() => _position = pos);
        }
      }),
      _player.stream.duration.listen((dur) {
        if (mounted) {
          setState(() => _duration = dur);
        }
      }),
      _player.stream.playing.listen((playing) {
        if (mounted) {
          setState(() => _isPlaying = playing);
          if (playing) {
            _resetControlsTimer();
            if (!_hasSetSubtitle) {
              _hasSetSubtitle = true;
              Future.delayed(const Duration(milliseconds: 1000), () {
                if (mounted) {
                  _injectSubtitle();
                }
              });
            }
          }
        }
      }),
      _player.stream.buffering.listen((buffering) {
        if (mounted) {
          setState(() => _isBuffering = buffering);
          if (!buffering && _isPlaying) {
            _resetControlsTimer();
          }
        }
      }),
      _player.stream.error.listen((error) {
        if (mounted) {
          setState(() => _isBuffering = false);
          _showToast("Stream Error: $error");
        }
      }),
    ]);
  }

  Future<void> _setupTorrentStream(String magnetUrl) async {
    setState(() => _isBuffering = true);
    try {
      final baseTempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${baseTempDir.path}/yugen_stream_cache');

      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
      await cacheDir.create();

      _rustEngine = TorrentEngine.init(downloadDir: cacheDir.path);
      final localStreamUrl = await _rustEngine!.startMagnetStream(magnetLink: magnetUrl);

      await _player.open(Media(localStreamUrl), play: true);
    } catch (e) {
      if (mounted) {
        setState(() => _isBuffering = false);
      }
    }
  }

  // 🛑 2. TAP/FADE BUG FIXED: Timer logic strictly enforced
  void _resetControlsTimer() {
    _controlsTimer?.cancel();
    if (_isPlaying && !_isLocked) {
      _controlsTimer = Timer(const Duration(seconds: 4), () {
        if (mounted && _isPlaying) {
          setState(() => _showControls = false);
        }
      });
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _resetControlsTimer();
    } else {
      _controlsTimer?.cancel();
    }
  }

  void _seekRelative(int seconds) {
    final newPos = _position + Duration(seconds: seconds);
    _player.seek(newPos.isNegative ? Duration.zero : (newPos > _duration ? _duration : newPos));
    _resetControlsTimer();
  }

  void _triggerDoubleTapRipple(bool isForward) {
    _seekRelative(isForward ? 10 : -10);
    setState(() {
      if (isForward) {
        _showForwardRipple = true;
      } else {
        _showRewindRipple = true;
      }
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _showForwardRipple = false;
          _showRewindRipple = false;
        });
      }
    });
  }

  void _showToast(String message) {
    setState(() => _toastMessage = message);
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _toastMessage = null);
      }
    });
  }

  void _cycleFit() {
    _resetControlsTimer();
    setState(() {
      if (_currentFit == BoxFit.contain) {
        _currentFit = BoxFit.cover;
        _showToast("Zoom (Cover)");
      } else if (_currentFit == BoxFit.cover) {
        _currentFit = BoxFit.fill;
        _showToast("Stretched (Fill)");
      } else {
        _currentFit = BoxFit.contain;
        _showToast("Fit to Screen");
      }
    });
  }

  void _cycleSpeed() {
    _resetControlsTimer();
    setState(() {
      if (_playbackSpeed == 1.0) {
        _playbackSpeed = 1.25;
      } else if (_playbackSpeed == 1.25) {
        _playbackSpeed = 1.5;
      } else if (_playbackSpeed == 1.5) {
        _playbackSpeed = 2.0;
      } else {
        _playbackSpeed = 1.0;
      }
      _player.setRate(_playbackSpeed);
      _showToast("Speed: ${_playbackSpeed}x");
    });
  }

  void _showPlaylistSheet() {
    _resetControlsTimer();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF14141B),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Episodes Playlist", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary),
              title: Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text("Currently Playing", style: TextStyle(color: Colors.white54, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  void _showTopSettingsPopup() {
    _resetControlsTimer();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF14141B),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Player Settings", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white54),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Text("Additional player settings will appear here.", style: TextStyle(color: Colors.white38, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Restored missing method
  void _showMoreOptionsSheet() {
    _resetControlsTimer();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF14141B),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("More Options", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white54),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.picture_in_picture_alt_rounded, color: Colors.white),
              title: const Text("Picture in Picture", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showToast("PIP coming soon!");
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.report_problem_rounded, color: Colors.white),
              title: const Text("Report Issue", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showToast("Report sent.");
              },
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _toastTimer?.cancel();
    for (final s in _subscriptions) {
      s.cancel();
    }
    _player.stop();
    _rustEngine?.dispose();

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "${d.inHours > 0 ? '${d.inHours}:' : ''}$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final double maxDuration = _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1.0;
    
    final parts = widget.title.split('-');
    final animeTitle = parts.length > 1 ? parts.sublist(0, parts.length - 1).join('-').trim() : widget.title;
    final epTitle = parts.length > 1 ? parts.last.trim() : 'Episode 1';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. VIDEO VIEW
          Center(
            child: Video(
              controller: _videoController,
              controls: NoVideoControls,
              fit: _currentFit,
              subtitleViewConfiguration: SubtitleViewConfiguration(
                style: TextStyle(
                  fontSize: SubtitleSelectorSheet.fontSize,
                  color: SubtitleSelectorSheet.fontColor,
                  backgroundColor: SubtitleSelectorSheet.bgColor,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  shadows: const [
                    Shadow(offset: Offset(1.5, 1.5), blurRadius: 2.0, color: Colors.black),
                    Shadow(offset: Offset(-1.5, -1.5), blurRadius: 2.0, color: Colors.black),
                    Shadow(offset: Offset(1.5, -1.5), blurRadius: 2.0, color: Colors.black),
                    Shadow(offset: Offset(-1.5, 1.5), blurRadius: 2.0, color: Colors.black),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
              ),
            ),
          ),

          if (_isBuffering)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
            ),

          // ==========================================
          // 2. GESTURE LAYER FOR SKIP RIPPLES
          // ==========================================
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _isLocked ? () => setState(() => _showControls = !_showControls) : _toggleControls,
                    onDoubleTap: _isLocked ? null : () => _triggerDoubleTapRipple(false),
                    child: AnimatedOpacity(
                      opacity: _showRewindRipple ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 150),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: RadialGradient(colors: [Colors.black54, Colors.transparent], center: Alignment.center, radius: 0.8),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.fast_rewind_rounded, color: Colors.white, size: 40),
                              SizedBox(height: 8),
                              Text("-10s", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Blank middle gesture area to catch center taps
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _toggleControls,
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _isLocked ? () => setState(() => _showControls = !_showControls) : _toggleControls,
                    onDoubleTap: _isLocked ? null : () => _triggerDoubleTapRipple(true),
                    child: AnimatedOpacity(
                      opacity: _showForwardRipple ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 150),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: RadialGradient(colors: [Colors.black54, Colors.transparent], center: Alignment.center, radius: 0.8),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.fast_forward_rounded, color: Colors.white, size: 40),
                              SizedBox(height: 8),
                              Text("+10s", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ==========================================
          // 3. UI OVERLAY LAYER (Fixes the stubborn fade bug)
          // ==========================================
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_showControls,
              child: AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: Stack(
                  children: [
                    // 🛑 TAP BACKGROUND TO DISMISS INSTANTLY
                    if (!_isLocked)
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: _toggleControls, // Tapping dark space forces close
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.8),
                                  Colors.transparent,
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.9),
                                ],
                                stops: const [0.0, 0.25, 0.6, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),

                    // TOP BAR
                    if (!_isLocked)
                      Positioned(
                        top: MediaQuery.paddingOf(context).top + 16,
                        left: 20,
                        right: 20,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildGlassyCard(
                              padding: const EdgeInsets.all(8),
                              onTap: () => Navigator.pop(context),
                              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    epTitle.length > 20 ? epTitle : widget.title,
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
                                      _buildChip(widget.playerController.selectedStream?.quality ?? widget.quality),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                _buildGlassyCard(
                                  padding: const EdgeInsets.all(8),
                                  onTap: () {
                                    setState(() => _isLocked = true);
                                    _resetControlsTimer();
                                  },
                                  child: const Icon(Icons.lock_open_rounded, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 12),
                                _buildGlassyCard(
                                  padding: const EdgeInsets.all(8),
                                  onTap: () => _showToast("PIP Mode coming soon!"),
                                  child: const Icon(Icons.picture_in_picture_alt_rounded, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 12),
                                _buildGlassyCard(
                                  padding: const EdgeInsets.all(8),
                                  onTap: _showTopSettingsPopup,
                                  child: const Icon(Icons.settings_rounded, color: Colors.white, size: 20),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    // LOCK BUTTON (When locked)
                    if (_isLocked)
                      Positioned(
                        top: MediaQuery.paddingOf(context).top + 16,
                        right: 20,
                        child: _buildGlassyCard(
                          padding: const EdgeInsets.all(8),
                          onTap: () {
                            setState(() => _isLocked = false);
                            _resetControlsTimer();
                          },
                          child: const Icon(Icons.lock_rounded, color: AppColors.primary, size: 20),
                        ),
                      ),

                    // 🛑 4. LOGICAL CENTER CONTROLS
                    if (!_isLocked)
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildGlassyCard(
                              padding: const EdgeInsets.all(12),
                              onTap: () {
                                _resetControlsTimer();
                                if (widget.onPreviousEpisode != null) {
                                  widget.onPreviousEpisode!();
                                } else {
                                  _showToast("No previous episode available");
                                }
                              },
                              child: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 36),
                            ),
                            const SizedBox(width: 32),
                            _buildGlassyCard(
                              padding: const EdgeInsets.all(16),
                              onTap: () {
                                _player.playOrPause();
                                _resetControlsTimer();
                              },
                              child: Icon(
                                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                            const SizedBox(width: 32),
                            _buildGlassyCard(
                              padding: const EdgeInsets.all(12),
                              onTap: () {
                                _resetControlsTimer();
                                if (widget.onNextEpisode != null) {
                                  widget.onNextEpisode!();
                                } else {
                                  _showToast("No next episode available");
                                }
                              },
                              child: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 36),
                            ),
                          ],
                        ),
                      ),

                    // TOAST NOTIFICATION
                    if (_toastMessage != null)
                      Align(
                        alignment: const Alignment(0, -0.6),
                        child: AnimatedOpacity(
                          opacity: 1.0,
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _toastMessage!,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),

                    // ==========================================
                    // BOTTOM BAR AREA
                    // ==========================================
                    if (!_isLocked)
                      Positioned(
                        bottom: MediaQuery.paddingOf(context).bottom + 16,
                        left: 20,
                        right: 20,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: _buildGlassyCard(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  onTap: () => _seekRelative(85),
                                  child: const Text("+85s", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),

                            // 🛑 5. EXACT PILL SLIDER FROM SCREENSHOT
                            SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 8, // Thicker bar
                                activeTrackColor: const Color(0xFFC4C4FF), // Light periwinkle
                                inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                                thumbColor: const Color(0xFFC4C4FF),
                                thumbShape: const _PillSliderThumbShape(thumbWidth: 6, thumbHeight: 22),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                trackShape: const RoundedRectSliderTrackShape(), // Fully rounded edges
                              ),
                              child: Slider(
                                min: 0.0,
                                max: maxDuration,
                                value: _position.inMilliseconds.toDouble().clamp(0.0, maxDuration),
                                onChanged: (val) {
                                  _resetControlsTimer();
                                  _player.seek(Duration(milliseconds: val.toInt()));
                                },
                              ),
                            ),
                            const SizedBox(height: 8),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    _buildGlassyCard(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      child: Text(_formatDuration(_position), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildGlassyCard(
                                      padding: const EdgeInsets.all(8),
                                      onTap: _showPlaylistSheet,
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
                                          _buildToolbarIcon(Icons.tune_rounded, () {
                                            showModalBottomSheet(
                                              context: context,
                                              backgroundColor: Colors.transparent,
                                              isScrollControlled: true,
                                              builder: (_) => SubtitleSelectorSheet(playerController: widget.playerController),
                                            );
                                          }),
                                          _buildToolbarIcon(Icons.cloud_outlined, () {
                                            showModalBottomSheet(
                                              context: context,
                                              backgroundColor: Colors.transparent,
                                              isScrollControlled: true,
                                              builder: (_) => StreamQualityBottomSheet(
                                                streamLinks: widget.playerController.streamLinks,
                                                selectedStream: widget.playerController.selectedStream,
                                                onStreamSelected: (StreamLink stream) {
                                                  _hasSetSubtitle = false;
                                                  widget.playerController.selectStream(stream);
                                                },
                                              ),
                                            );
                                          }),
                                          _buildToolbarIcon(Icons.speed_rounded, _cycleSpeed),
                                          _buildToolbarIcon(Icons.aspect_ratio_rounded, _cycleFit),
                                          _buildToolbarIcon(Icons.open_in_new_rounded, _showMoreOptionsSheet),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildGlassyCard(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      child: Text(_formatDuration(_duration), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassyCard({required Widget child, required EdgeInsets padding, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap();
        }
        _resetControlsTimer();
      },
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

  Widget _buildToolbarIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        onTap();
        _resetControlsTimer();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// 🛑 CUSTOM VERTICAL PILL THUMB (Replicates Screenshot)
class _PillSliderThumbShape extends SliderComponentShape {
  final double thumbWidth;
  final double thumbHeight;

  const _PillSliderThumbShape({this.thumbWidth = 6.0, this.thumbHeight = 22.0});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(thumbWidth, thumbHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    final Paint paint = Paint()..color = sliderTheme.thumbColor ?? Colors.white;

    final RRect thumbRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: thumbWidth, height: thumbHeight),
      Radius.circular(thumbWidth / 2),
    );

    canvas.drawRRect(thumbRect, paint);
  }
}