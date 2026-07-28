import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:media_kit/media_kit.dart' hide SubtitleTrack, AudioTrack;
import 'package:media_kit/media_kit.dart' as mk;
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
import '../widgets/stream_quality_bottom_sheet.dart';
import '../widgets/subtitle_selector_sheet.dart';
import '../../../history/services/watch_history_service.dart'; 


class GlassyPlayerScreen extends StatefulWidget {
  final String title;
  final String quality;
  final String streamUrl;
  final PlayerController playerController;

  // 👇 NEW REQUIRED FIELDS FOR HISTORY 👇
  final String animeId;
  final String episodeId;
  final int episodeNumber;
  final String posterUrl;
  final Duration? startPosition; // Where to resume from

  // LOGIC CALLBACKS ADDED HERE
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
    this.startPosition,
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

  Timer? _saveTimer;
  final WatchHistoryService _historyService = WatchHistoryService();

  StreamSubscription? _completedSub;
  bool _isTransitioningToNext = false;

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

    // 👇 BULLETPROOF RESUME LOGIC (V3 - DECODER SAFE) 👇
    if (widget.startPosition != null && widget.startPosition! > const Duration(seconds: 5)) {
      
      // Helper function to safely execute the seek with a micro-delay
      void triggerSafeSeek() {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            try {
              _player.seek(widget.startPosition!);
              debugPrint("Successfully resumed at: ${widget.startPosition}");
            } catch (e) {
              debugPrint("Seek failed: $e");
            }
          }
        });
      }

      // Scenario A: The video loaded instantly and already knows its duration.
      if (_player.state.duration.inMilliseconds > 0) {
        triggerSafeSeek();
      } 
      // Scenario B: Wait for the engine to announce its duration, then seek.
      else {
        StreamSubscription? resumeSub;
        resumeSub = _player.stream.duration.listen((duration) {
          if (duration.inMilliseconds > 0) {
            triggerSafeSeek();
            resumeSub?.cancel(); // Kill the listener
          }
        });
      }
    }

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

    // 👇 AUTO-PLAY NEXT EPISODE LISTENER 👇
    _completedSub = _player.stream.completed.listen((completed) async {
      if (completed && mounted && widget.onNextEpisode != null) {
        if (!_isTransitioningToNext) {
          setState(() => _isTransitioningToNext = true);
          debugPrint("Video finished. Auto-playing next episode...");

          final success = await widget.onNextEpisode!();

// 👇 If the fetch fails and we are still on this screen, unlock the flag!
          if (mounted && !success) {
            setState(() => _isTransitioningToNext = false);
          }
        }
      }
    });
    
    // 👇 START THE BACKGROUND SAVER 👇
    _startHistorySaver();
  }

  void _startHistorySaver() {
    _saveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      // 1. Ask the player engine DIRECTLY for its current stats, bypassing stale UI variables
      final livePosition = _player.state.position;
      final liveDuration = _player.state.duration;

      // 2. Only save if it is actually playing and we have a valid time
      if (mounted && _player.state.playing && livePosition.inMilliseconds > 0 && liveDuration.inMilliseconds > 0) {
        _historyService.saveHistory(
          animeId: widget.animeId,
          animeTitle: widget.title.split('-').first.trim(),
          episodeId: widget.episodeId,
          episodeNumber: widget.episodeNumber,
          posterUrl: widget.posterUrl,
          positionMs: livePosition.inMilliseconds,
          durationMs: liveDuration.inMilliseconds,
        );
      }
    });
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
    _saveTimer?.cancel();
    _controlsTimer?.cancel();
    _toastTimer?.cancel();
    _completedSub?.cancel();
    for (final s in _subscriptions) {
      s.cancel();
    }
    _player.stop();
    _rustEngine?.dispose();

    if (!_isTransitioningToNext) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      //SystemUiMode reset
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
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
  onSettingsPressed: _showTopSettingsPopup, // Timer reset is already handled inside this function
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
        // 👇 INJECT THE ANTI-SPAM LOGIC HERE 👇
        if (!_isTransitioningToNext) {
          setState(() => _isTransitioningToNext = true);
          _player.pause(); // Mute the current stream immediately
          debugPrint("Manual skip triggered.");

          final success = await widget.onNextEpisode!();
          // 👇 Unlock the flag if the fetch fails
          if (mounted && !success) {
            setState(() => _isTransitioningToNext = false);
          }
        }
      } else {
        _showToast("No next episode available");
      }
    },
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

                    if (!_isLocked)
  GlassyBottomBar(
    position: _position,
    duration: _duration,
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
            _hasSetSubtitle = false;
            widget.playerController.selectStream(stream);
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