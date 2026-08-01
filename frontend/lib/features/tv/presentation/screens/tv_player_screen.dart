import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart' hide SubtitleTrack;
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../player/controllers/player_controller.dart';

class TvPlayerScreen extends StatefulWidget {
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

  const TvPlayerScreen({
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
  State<TvPlayerScreen> createState() => _TvPlayerScreenState();
}

class _TvPlayerScreenState extends State<TvPlayerScreen> {
  Player get _player => widget.playerController.player;
  VideoController get _videoController => widget.playerController.videoController;

  final List<StreamSubscription> _subscriptions = [];
  Timer? _controlsTimer;

  bool _isBuffering = true;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _isTransitioningToNext = false;

  bool _isSubtitlesEnabled = false;
  dynamic _selectedSubtitle;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _buffer = Duration.zero; 

  final FocusNode _backgroundFocusNode = FocusNode();
  final FocusNode _playPauseFocusNode = FocusNode(); 

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _setupPlayerListeners();
    _player.setSubtitleTrack(mk.SubtitleTrack.no());

    _isPlaying = _player.state.playing;
    _isBuffering = _player.state.buffering;
    _position = _player.state.position;
    _duration = _player.state.duration;
    _buffer = _player.state.buffer; 

    _resetControlsTimer();

    _subscriptions.add(_player.stream.completed.listen((completed) async {
      if (completed && mounted && widget.onNextEpisode != null && !_isTransitioningToNext) {
        setState(() => _isTransitioningToNext = true);
        final success = await widget.onNextEpisode!();
        if (mounted && !success) setState(() => _isTransitioningToNext = false);
      }
    }));
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
        if (mounted) setState(() => _isBuffering = buffering);
      }),
    ]);
  }

  void _resetControlsTimer() {
    _controlsTimer?.cancel();
    if (_isPlaying) {
      _controlsTimer = Timer(const Duration(seconds: 4), () {
        if (mounted && _isPlaying) {
          setState(() => _showControls = false);
          _backgroundFocusNode.requestFocus();
        }
      });
    }
  }

  void _seekRelative(int seconds) {
    final newPos = _position + Duration(seconds: seconds);
    _player.seek(newPos.isNegative ? Duration.zero : (newPos > _duration ? _duration : newPos));
    
    bool wasHidden = !_showControls;
    setState(() => _showControls = true);
    
    if (wasHidden) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _playPauseFocusNode.requestFocus());
    }
    _resetControlsTimer();
  }

  void _toggleSubtitles(bool enable, [dynamic sub]) {
    setState(() {
      _isSubtitlesEnabled = enable;
      _selectedSubtitle = enable ? sub : null;
    });

    if (!enable || sub == null) {
      _player.setSubtitleTrack(mk.SubtitleTrack.no());
    } else {
      final subJson = sub.toJson();
      final subUrl = subJson['url']?.toString() ?? subJson['file']?.toString() ?? '';
      final subLabel = subJson['label']?.toString() ?? 'English';
      
      _player.setSubtitleTrack(mk.SubtitleTrack.uri(subUrl, title: subLabel, language: 'en'));
    }
  }

  void _showSubtitleSelectorModal() {
    _resetControlsTimer();
    final availableSubtitles = widget.playerController.selectedStream?.subtitles ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, 
      builder: (context) {
        return FocusScope(
          autofocus: true,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF14141B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Subtitles",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TvSubtitleOptionTile(
                          title: "Off",
                          isSelected: !_isSubtitlesEnabled,
                          onTap: () {
                            _toggleSubtitles(false);
                            Navigator.pop(context);
                          },
                        ),
                        ...availableSubtitles.map((sub) {
                          final subJson = sub.toJson();
                          final subUrl = subJson['url']?.toString() ?? subJson['file']?.toString() ?? '';
                          final subLabel = subJson['label']?.toString() ?? 'English';
                          
                          final selectedJson = _selectedSubtitle?.toJson();
                          final selectedUrl = selectedJson?['url']?.toString() ?? selectedJson?['file']?.toString() ?? '';
                          
                          final isSelected = _isSubtitlesEnabled && selectedUrl == subUrl;
                          
                          return _TvSubtitleOptionTile(
                            title: subLabel.isNotEmpty ? subLabel : "English",
                            isSelected: isSelected,
                            onTap: () {
                              _toggleSubtitles(true, sub);
                              Navigator.pop(context);
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _backgroundFocusNode.dispose();
    _playPauseFocusNode.dispose();
    for (final s in _subscriptions) {
      s.cancel();
    }
    
    try {
      _player.stop();
    } catch (_) {}

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    widget.playerController.dispose();

    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final parts = widget.title.split('-');
    final animeTitle = parts.length > 1 ? parts.sublist(0, parts.length - 1).join('-').trim() : widget.title;
    final epTitle = parts.length > 1 ? parts.last.trim() : 'Episode 1';

    final introStart = widget.playerController.introStart;
    final introEnd = widget.playerController.introEnd;
    final outroStart = widget.playerController.outroStart;
    final outroEnd = widget.playerController.outroEnd;

    final hasIntro = introStart != null && introEnd != null;
    final hasOutro = outroStart != null && outroEnd != null;

    final inIntro = hasIntro && _position >= introStart && _position < introEnd;
    final inOutro = hasOutro && _position >= outroStart && _position < outroEnd;

    final String skipText = inIntro ? "Skip Intro" : (inOutro ? "Skip Outro" : "+85s");

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: Video(
              controller: _videoController,
              controls: NoVideoControls,
              fit: BoxFit.contain,
              subtitleViewConfiguration: const SubtitleViewConfiguration(
                style: TextStyle(
                  fontSize: 38,
                  color: Colors.white,
                  backgroundColor: Colors.transparent,
                  fontWeight: FontWeight.w800,
                  shadows: [
                    Shadow(offset: Offset(2, 2), blurRadius: 4.0, color: Colors.black),
                  ],
                ),
                padding: EdgeInsets.only(bottom: 60.0),
              ),
            ),
          ),

          if (_isBuffering)
            const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3)),

          Positioned.fill(
            child: Focus(
              focusNode: _backgroundFocusNode,
              autofocus: true,
              canRequestFocus: !_showControls, 
              onKeyEvent: (node, event) {
                if (!_showControls && event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.audioVolumeUp || 
                      event.logicalKey == LogicalKeyboardKey.audioVolumeDown || 
                      event.logicalKey == LogicalKeyboardKey.audioVolumeMute ||
                      event.logicalKey == LogicalKeyboardKey.goBack ||
                      event.logicalKey == LogicalKeyboardKey.escape) {
                    return KeyEventResult.ignored;
                  }

                  if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                    _seekRelative(-10);
                    return KeyEventResult.handled;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                    _seekRelative(10);
                    return KeyEventResult.handled;
                  }

                  if (event.logicalKey == LogicalKeyboardKey.mediaPlayPause ||
                      event.logicalKey == LogicalKeyboardKey.mediaPlay ||
                      event.logicalKey == LogicalKeyboardKey.mediaPause) {
                    _player.playOrPause();
                    setState(() => _showControls = true);
                    WidgetsBinding.instance.addPostFrameCallback((_) => _playPauseFocusNode.requestFocus());
                    _resetControlsTimer();
                    return KeyEventResult.handled;
                  }
                  
                  setState(() => _showControls = true);
                  WidgetsBinding.instance.addPostFrameCallback((_) => _playPauseFocusNode.requestFocus());
                  _resetControlsTimer();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (!_showControls) {
                    setState(() => _showControls = true);
                    WidgetsBinding.instance.addPostFrameCallback((_) => _playPauseFocusNode.requestFocus());
                    _resetControlsTimer();
                  }
                },
                child: const SizedBox.expand(),
              ),
            ),
          ),

          if (_showControls)
            Positioned.fill(
              child: FocusScope(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24).copyWith(bottom: 60),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent],
                        ),
                      ),
                      child: Row(
                        children: [
                          _TvPlayerControlButton(
                            icon: Icons.arrow_back_rounded,
                            onTap: () => Navigator.pop(context),
                            autofocus: false,
                            onFocus: _resetControlsTimer,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  animeTitle,
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  epTitle,
                                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.quality.toUpperCase(),
                              style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _TvPlayerControlButton(
                          icon: Icons.skip_previous_rounded,
                          onTap: () {
                            _resetControlsTimer();
                            if (widget.onPreviousEpisode != null) widget.onPreviousEpisode!();
                          },
                          autofocus: false,
                          onFocus: _resetControlsTimer,
                          size: 32,
                          padding: 16,
                        ),
                        const SizedBox(width: 24),
                        _TvPlayerControlButton(
                          icon: Icons.replay_10_rounded,
                          onTap: () => _seekRelative(-10),
                          autofocus: false,
                          onFocus: _resetControlsTimer,
                          size: 32,
                          padding: 16,
                        ),
                        const SizedBox(width: 24),
                        _TvPlayerControlButton(
                          icon: _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          onTap: () {
                            _player.playOrPause();
                            _resetControlsTimer();
                          },
                          autofocus: true,
                          focusNode: _playPauseFocusNode,
                          onFocus: _resetControlsTimer,
                          size: 56,
                          padding: 24,
                        ),
                        const SizedBox(width: 24),
                        _TvPlayerControlButton(
                          icon: Icons.forward_10_rounded,
                          onTap: () => _seekRelative(10),
                          autofocus: false,
                          onFocus: _resetControlsTimer,
                          size: 32,
                          padding: 16,
                        ),
                        const SizedBox(width: 24),
                        _TvPlayerControlButton(
                          icon: Icons.skip_next_rounded,
                          onTap: () async {
                            _resetControlsTimer();
                            if (widget.onNextEpisode != null && !_isTransitioningToNext) {
                              setState(() => _isTransitioningToNext = true);
                              _player.pause();
                              final success = await widget.onNextEpisode!();
                              if (mounted && !success) setState(() => _isTransitioningToNext = false);
                            }
                          },
                          autofocus: false,
                          onFocus: _resetControlsTimer,
                          size: 32,
                          padding: 16,
                        ),
                      ],
                    ),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24).copyWith(top: 60),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent],
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(_formatDuration(_position), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 20),
                          
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final trackWidth = constraints.maxWidth;
                                final maxDur = _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1.0;
                                final posProgress = (_position.inMilliseconds / maxDur).clamp(0.0, 1.0);
                                final bufProgress = (_buffer.inMilliseconds / maxDur).clamp(0.0, 1.0);

                                double getLeft(Duration start) => (start.inMilliseconds / maxDur).clamp(0.0, 1.0) * trackWidth;
                                double getWidth(Duration start, Duration end) => ((end.inMilliseconds - start.inMilliseconds) / maxDur).clamp(0.0, 1.0) * trackWidth;

                                return Container(
                                  height: 10, 
                                  decoration: BoxDecoration(
                                    color: Colors.white12, 
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    alignment: Alignment.centerLeft,
                                    children: [
                                      FractionallySizedBox(
                                        widthFactor: bufProgress,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.4),
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                        ),
                                      ),
                                      if (hasIntro)
                                        Positioned(
                                          left: getLeft(introStart),
                                          width: getWidth(introStart, introEnd),
                                          height: 10,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.amber.withValues(alpha: 0.85),
                                              borderRadius: BorderRadius.circular(5),
                                            ),
                                          ),
                                        ),
                                      if (hasOutro)
                                        Positioned(
                                          left: getLeft(outroStart),
                                          width: getWidth(outroStart, outroEnd),
                                          height: 10,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.amber.withValues(alpha: 0.85),
                                              borderRadius: BorderRadius.circular(5),
                                            ),
                                          ),
                                        ),
                                      FractionallySizedBox(
                                        widthFactor: posProgress,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          
                          const SizedBox(width: 20),
                          Text(_formatDuration(_duration), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                          const SizedBox(width: 32),

                          _TvPlayerControlButton(
                            icon: _isSubtitlesEnabled ? Icons.subtitles_rounded : Icons.subtitles_off_rounded,
                            onTap: _showSubtitleSelectorModal,
                            autofocus: false,
                            onFocus: _resetControlsTimer,
                            size: 24,
                            padding: 12,
                          ),
                          const SizedBox(width: 16),

                          _TvPlayerTextButton(
                            label: skipText,
                            onFocus: _resetControlsTimer,
                            onTap: () {
                              if (inIntro) {
                                _player.seek(introEnd);
                                _resetControlsTimer();
                              } else if (inOutro) {
                                _player.seek(outroEnd);
                                _resetControlsTimer();
                              } else {
                                _seekRelative(85); 
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TvPlayerControlButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool autofocus;
  final FocusNode? focusNode;
  final VoidCallback? onFocus;
  final double size;
  final double padding;

  const _TvPlayerControlButton({
    required this.icon,
    required this.onTap,
    required this.autofocus,
    this.focusNode,
    this.onFocus,
    this.size = 28,
    this.padding = 12,
  });

  @override
  State<_TvPlayerControlButton> createState() => _TvPlayerControlButtonState();
}

class _TvPlayerControlButtonState extends State<_TvPlayerControlButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        autofocus: widget.autofocus,
        focusNode: widget.focusNode,
        onFocusChange: (focused) {
          setState(() => _isFocused = focused);
          if (focused && widget.onFocus != null) widget.onFocus!();
        },
        borderRadius: BorderRadius.circular(100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutQuart,
          transform: Matrix4.diagonal3Values(_isFocused ? 1.15 : 1.0, _isFocused ? 1.15 : 1.0, 1.0),
          transformAlignment: Alignment.center,
          padding: EdgeInsets.all(widget.padding),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isFocused ? AppColors.primary : Colors.white.withValues(alpha: 0.15),
            boxShadow: _isFocused 
                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 5))] 
                : [],
          ),
          child: Icon(
            widget.icon,
            color: Colors.white,
            size: widget.size,
          ),
        ),
      ),
    );
  }
}

class _TvPlayerTextButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onFocus;

  const _TvPlayerTextButton({
    required this.label,
    required this.onTap,
    this.onFocus,
  });

  @override
  State<_TvPlayerTextButton> createState() => _TvPlayerTextButtonState();
}

class _TvPlayerTextButtonState extends State<_TvPlayerTextButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onFocusChange: (focused) {
          setState(() => _isFocused = focused);
          if (focused && widget.onFocus != null) widget.onFocus!();
        },
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutQuart,
          transform: Matrix4.diagonal3Values(_isFocused ? 1.1 : 1.0, _isFocused ? 1.1 : 1.0, 1.0),
          transformAlignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _isFocused ? AppColors.primary : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            boxShadow: _isFocused 
                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 4))] 
                : [],
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _TvSubtitleOptionTile extends StatefulWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _TvSubtitleOptionTile({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TvSubtitleOptionTile> createState() => _TvSubtitleOptionTileState();
}

class _TvSubtitleOptionTileState extends State<_TvSubtitleOptionTile> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        autofocus: widget.isSelected, 
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(vertical: 6), 
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          transform: Matrix4.diagonal3Values(_isFocused ? 1.05 : 1.0, _isFocused ? 1.05 : 1.0, 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: _isFocused 
                ? AppColors.primary 
                : (widget.isSelected ? AppColors.primary.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05)),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isFocused 
                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(0, 3))] 
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: widget.isSelected || _isFocused ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.isSelected)
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}