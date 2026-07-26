import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../src/rust/api/torrent.dart';
import '../../controllers/player_controller.dart';
import '../../models/stream_link.dart';
// 🛑 Ensure this matches the actual file name we fixed earlier
import '../widgets/stream_quality_bottom_sheet.dart';

class GlassyPlayerScreen extends StatefulWidget {
  final String title;
  final String quality;
  final String streamUrl;
  final PlayerController playerController;

  const GlassyPlayerScreen({
    super.key,
    required this.title,
    required this.quality,
    required this.streamUrl,
    required this.playerController,
  });

  @override
  State<GlassyPlayerScreen> createState() => _GlassyPlayerScreenState();
}

class _GlassyPlayerScreenState extends State<GlassyPlayerScreen> {
  // 🛑 Access the shared player from the controller instead of making a new one
  Player get _player => widget.playerController.player;
  VideoController get _videoController =>
      widget.playerController.videoController;

  final List<StreamSubscription> _subscriptions = [];

  TorrentEngine? _rustEngine;

  Timer? _statsTimer;
  Timer? _controlsTimer;

  bool _isBuffering = true;
  bool _isPlaying = false;
  bool _showControls = true;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  final String _downloadSpeed = "0.00 KB/s";
  final String _uploadSpeed = "0 B/s";

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _setupPlayerListeners();

    // 🛑 If it's a standard HTTP stream, the PlayerController already started playing it.
    // We only need manual setup here if it's a magnet link for the Rust engine.
    if (widget.streamUrl.startsWith('magnet:')) {
      _setupTorrentStream(widget.streamUrl);
    } else {
      // Sync initial states from the already-running player
      _isPlaying = _player.state.playing;
      _isBuffering = _player.state.buffering;
      _position = _player.state.position;
      _duration = _player.state.duration;
    }

    _startControlsTimer();
  }

  void _setupPlayerListeners() {
    _subscriptions.addAll([
      _player.stream.position.listen((pos) {
        if (mounted) setState(() => _position = pos);
      }),
      _player.stream.duration.listen((dur) {
        if (mounted) setState(() => _duration = dur);
      }),
      _player.stream.playing.listen((playing) {
        if (mounted) setState(() => _isPlaying = playing);
      }),
      _player.stream.buffering.listen((buffering) {
        if (mounted) setState(() => _isBuffering = buffering);
      }),
      _player.stream.error.listen((error) {
        debugPrint("🚨 [MediaKit] Playback Error: $error");
        if (mounted) {
          setState(() => _isBuffering = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Stream Error: $error")));
        }
      }),
    ]);
  }

  // 🛑 Isolated Torrent Logic (HTTP logic removed because PlayerController handles it)
  Future<void> _setupTorrentStream(String magnetUrl) async {
    setState(() => _isBuffering = true);

    try {
      debugPrint("🚀 [Rust] Routing magnet link to Torrent Engine...");
      final baseTempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${baseTempDir.path}/yugen_stream_cache');

      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
      await cacheDir.create();

      _rustEngine = TorrentEngine.init(downloadDir: cacheDir.path);
      final localStreamUrl = await _rustEngine!.startMagnetStream(
        magnetLink: magnetUrl,
      );

      debugPrint("🎬 [MediaKit] Opening Local Torrent Stream: $localStreamUrl");
      await _player.open(Media(localStreamUrl), play: true);
    } catch (e) {
      debugPrint("🚨 [Rust] Torrent stream error: $e");
      if (mounted) {
        setState(() => _isBuffering = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to load torrent: $e")));
      }
    }
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _isPlaying && !_isBuffering) {
        setState(() {
          _showControls = false;
          _controlsTimer = null;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) _startControlsTimer();
    });
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    _controlsTimer?.cancel();

    for (final s in _subscriptions) {
      s.cancel();
    }

    // 🛑 Do NOT call _player.dispose() here!
    // The PlayerController owns it. We just stop playback when the screen closes.
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

  void _showQualitySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StreamQualityBottomSheet(
        // 🛑 Updated to match your file name
        streamLinks: widget.playerController.streamLinks,
        selectedStream: widget.playerController.selectedStream,
        onStreamSelected: (StreamLink stream) {
          // PlayerController will automatically call player.open() with the new stream and headers
          widget.playerController.selectStream(stream);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double maxDuration = _duration.inMilliseconds > 0
        ? _duration.inMilliseconds.toDouble()
        : 1.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            Center(
              child: Video(
                controller: _videoController,
                controls:
                    NoVideoControls, // Disables default UI for your glassy overlay
              ),
            ),

            if (_isBuffering)
              Container(
                color: Colors.black87,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Loading Stream...",
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (widget.streamUrl.startsWith('magnet:')) ...[
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.arrow_downward_rounded,
                              color: Colors.greenAccent,
                              size: 16,
                            ),
                            Text(
                              " $_downloadSpeed   ",
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const Icon(
                              Icons.arrow_upward_rounded,
                              color: Colors.blueAccent,
                              size: 16,
                            ),
                            Text(
                              " $_uploadSpeed",
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: !_showControls,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: GestureDetector(
                    onTap: _startControlsTimer,
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
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: _showQualitySelector,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              widget
                                                      .playerController
                                                      .selectedStream
                                                      ?.quality ??
                                                  widget.quality,
                                              style: const TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              color: AppColors.primary,
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: !_showControls,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: GestureDetector(
                    onTap: _startControlsTimer,
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
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _formatDuration(_position),
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderThemeData(
                                        trackHeight: 4,
                                        activeTrackColor: AppColors.primary,
                                        inactiveTrackColor: AppColors
                                            .textSecondary
                                            .withValues(alpha: 0.2),
                                        thumbColor: AppColors.primary,
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 6,
                                        ),
                                        overlayShape:
                                            const RoundSliderOverlayShape(
                                              overlayRadius: 14,
                                            ),
                                      ),
                                      child: Slider(
                                        min: 0.0,
                                        max: maxDuration,
                                        value: _position.inMilliseconds
                                            .toDouble()
                                            .clamp(0.0, maxDuration),
                                        onChanged: (val) {
                                          _player.seek(
                                            Duration(milliseconds: val.toInt()),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(_duration),
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  IconButton(
                                    onPressed: () {},
                                    icon: const Icon(
                                      Icons.skip_previous_rounded,
                                      color: AppColors.textPrimary,
                                      size: 32,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      final newPos =
                                          _position -
                                          const Duration(seconds: 10);
                                      _player.seek(
                                        newPos.isNegative
                                            ? Duration.zero
                                            : newPos,
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.replay_10_rounded,
                                      color: AppColors.textPrimary,
                                      size: 28,
                                    ),
                                  ),
                                  Container(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primary,
                                    ),
                                    child: IconButton(
                                      onPressed: () => _player.playOrPause(),
                                      icon: Icon(
                                        _isPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 36,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      final newPos =
                                          _position +
                                          const Duration(seconds: 10);
                                      _player.seek(
                                        newPos > _duration ? _duration : newPos,
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.forward_10_rounded,
                                      color: AppColors.textPrimary,
                                      size: 28,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {},
                                    icon: const Icon(
                                      Icons.skip_next_rounded,
                                      color: AppColors.textPrimary,
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
