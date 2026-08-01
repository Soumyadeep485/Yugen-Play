import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';

import '../widgets/glassy_top_bar.dart';
import '../widgets/glassy_center_controls.dart';
import '../widgets/glassy_bottom_bar.dart';
import '../widgets/glassy_gesture_overlay.dart';
import '../widgets/glassy_playlist_sheet.dart';
import '../widgets/glassy_settings_sheet.dart';
import '../widgets/glassy_more_options_sheet.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../src/rust/api/torrent.dart';
import '../../controllers/player_controller.dart';
import '../widgets/subtitle_selector_sheet.dart';
import '../widgets/stream_quality_bottom_sheet.dart'; // 👈 Needed for switching quality

class GlassyPlayerScreen extends StatefulWidget {
  final String title;
  final String quality;
  final String streamUrl;
  final PlayerController playerController;

  final String animeId;
  final String episodeId;
  final int episodeNumber;
  final String posterUrl;

  final Future<bool> Function()? onNextEpisode;
  final VoidCallback? onPreviousEpisode;

  const GlassyPlayerScreen({
    super.key,
    required this.title,
    required this.quality,
    required this.streamUrl,
    required this.playerController,
    required this.animeId,
    required this.episodeId,
    required this.episodeNumber,
    required this.posterUrl,
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

  StreamSubscription? _completedSub;
  bool _isTransitioningToNext = false;

  bool _isBuffering = true;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _isLocked = false;

  bool _showForwardRipple = false;
  bool _showRewindRipple = false;
  
  double _playbackSpeed = 1.0;
  BoxFit _currentFit = BoxFit.contain;

  String? _toastMessage;
  Timer? _toastTimer;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _buffer = Duration.zero;

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
      _buffer = _player.state.buffer;
    }

    _resetControlsTimer();

    _completedSub = _player.stream.completed.listen((completed) async {
      if (completed && mounted && widget.onNextEpisode != null) {
        if (!_isTransitioningToNext) {
          setState(() => _isTransitioningToNext = true);
          final success = await widget.onNextEpisode!();
          if (mounted && !success) {
            setState(() => _isTransitioningToNext = false);
          }
        }
      }
    });
  }

  void _setupPlayerListeners() {
    _subscriptions.addAll([
      _player.stream.position.listen((pos) {
        if (mounted) setState(() => _position = pos);
      }),
      _player.stream.duration.listen((dur) {
        if (mounted) setState(() => _duration = dur);
      }),
      _player.stream.buffer.listen((buf) {
        if (mounted) setState(() => _buffer = buf);
      }),
      _player.stream.playing.listen((playing) {
        if (mounted) {
          setState(() => _isPlaying = playing);
          if (playing) _resetControlsTimer();
        }
      }),
      _player.stream.buffering.listen((buffering) {
        if (mounted) {
          setState(() => _isBuffering = buffering);
          if (!buffering && _isPlaying) _resetControlsTimer();
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

      if (await cacheDir.exists()) await cacheDir.delete(recursive: true);
      await cacheDir.create();

      _rustEngine = TorrentEngine.init(downloadDir: cacheDir.path);
      final localStreamUrl = await _rustEngine!.startMagnetStream(magnetLink: magnetUrl);

      await _player.open(Media(localStreamUrl), play: true);
    } catch (e) {
      if (mounted) setState(() => _isBuffering = false);
    }
  }

  void _resetControlsTimer() {
    _controlsTimer?.cancel();
    if (_isPlaying && !_isLocked) {
      _controlsTimer = Timer(const Duration(seconds: 4), () {
        if (mounted && _isPlaying) setState(() => _showControls = false);
      });
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
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
      if (mounted) setState(() { _showForwardRipple = false; _showRewindRipple = false; });
    });
  }

  void _showToast(String message) {
    setState(() => _toastMessage = message);
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _toastMessage = null);
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
      if (_playbackSpeed == 1.0){
         _playbackSpeed = 1.25;
      }else if (_playbackSpeed == 1.25) {
        _playbackSpeed = 1.5;
      }else if (_playbackSpeed == 1.5){
       _playbackSpeed = 2.0;
      }else {
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
      builder: (_) => GlassyPlaylistSheet(title: widget.title),
    );
  }

  void _showTopSettingsPopup() {
    _resetControlsTimer();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const GlassySettingsSheet(),
    );
  }

  void _showMoreOptionsSheet() {
    _resetControlsTimer();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => GlassyMoreOptionsSheet(onToastMessage: _showToast),
    );
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _toastTimer?.cancel();
    _completedSub?.cancel();
    for (final s in _subscriptions) {
      s.cancel();
    }
    
    try {
      _player.stop();
    } catch (_) {}

    _rustEngine?.dispose();

    if (!_isTransitioningToNext) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    
    widget.playerController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {    
    final parts = widget.title.split('-');
    final animeTitle = parts.length > 1 ? parts.sublist(0, parts.length - 1).join('-').trim() : widget.title;
    final epTitle = parts.length > 1 ? parts.last.trim() : 'Episode 1';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
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

          GlassyGestureOverlay(
            isLocked: _isLocked,
            showForwardRipple: _showForwardRipple,
            showRewindRipple: _showRewindRipple,
            onToggleControls: () {
              if (_isLocked) {
                setState(() => _showControls = !_showControls);
              } else {
                _toggleControls();
              }
            },
            onDoubleTapSeek: (isForward) => _triggerDoubleTapRipple(isForward),
          ),

          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_showControls,
              child: AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: Stack(
                  children: [
                    if (!_isLocked)
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: _toggleControls,
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

                    GlassyTopBar(
                      animeTitle: animeTitle,
                      epTitle: epTitle,
                      fullTitle: widget.title,
                      quality: widget.playerController.selectedStream?.quality ?? widget.quality,
                      isLocked: _isLocked,
                      onBack: () {
                        _resetControlsTimer();
                        Navigator.pop(context);
                      },
                      onLockToggle: () {
                        setState(() => _isLocked = !_isLocked);
                        _resetControlsTimer();
                      },
                      onPipPressed: () {
                        _resetControlsTimer();
                        _showToast("PIP Mode coming soon!");
                      },
                      onSettingsPressed: _showTopSettingsPopup,
                    ),

                    if (!_isLocked)
                      GlassyCenterControls(
                        isPlaying: _isPlaying,
                        onPlayPause: () {
                          _player.playOrPause();
                          _resetControlsTimer();
                        },
                        onPrevious: () {
                          _resetControlsTimer();
                          if (widget.onPreviousEpisode != null) {
                            widget.onPreviousEpisode!();
                          } else {
                            _showToast("No previous episode available");
                          }
                        },
                        onNext: () async {
                          _resetControlsTimer();
                          if (widget.onNextEpisode != null) {
                            if (!_isTransitioningToNext) {
                              setState(() => _isTransitioningToNext = true);
                              _player.pause();

                              final success = await widget.onNextEpisode!();
                              if (mounted && !success) {
                                setState(() => _isTransitioningToNext = false);
                              }
                            }
                          } else {
                            _showToast("No next episode available");
                          }
                        },
                      ),

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

                    if (!_isLocked)
                      GlassyBottomBar(
                        position: _position,
                        duration: _duration,
                        buffer: _buffer,
                        introStart: widget.playerController.introStart,
                        introEnd: widget.playerController.introEnd,
                        outroStart: widget.playerController.outroStart,
                        outroEnd: widget.playerController.outroEnd,
                        onSkipIntro: () => _seekRelative(85),
                        onSeek: (newPos) {
                          _resetControlsTimer();
                          _player.seek(newPos);
                        },
                        onPlaylistPressed: _showPlaylistSheet,
                        onSubtitlesPressed: () {
                          _resetControlsTimer();
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (_) => SubtitleSelectorSheet(playerController: widget.playerController),
                          );
                        },
                        onQualityPressed: () {
                          _resetControlsTimer();
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (_) => StreamQualityBottomSheet(
                              streamLinks: widget.playerController.streamLinks,
                              selectedStream: widget.playerController.selectedStream,
                              onStreamSelected: (stream) {
                                // 🛑 NEW: Capture live position and pass it to selectStream so SUB/DUB switches seamlessly!
                                final currentPos = _player.state.position;
                                widget.playerController.selectStream(stream, startPosition: currentPos);
                              },
                            ),
                          );
                        },
                        onSpeedPressed: _cycleSpeed,
                        onFitPressed: _cycleFit,
                        onMoreOptionsPressed: _showMoreOptionsSheet,
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
}