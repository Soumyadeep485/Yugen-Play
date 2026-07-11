import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/stream_link.dart';

class PlaybackController extends ChangeNotifier {
  late final Player _player;
  late final VideoController _videoController;

  StreamLink? _currentStream;
  bool _isBuffering = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  double _volume = 100.0;

  final List<StreamSubscription> _subscriptions = [];

  PlaybackController() {
    _player = Player();
    _videoController = VideoController(_player);

    _initStreams();
  }

  VideoController get videoController => _videoController;
  StreamLink? get currentStream => _currentStream;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  Duration get position => _position;
  Duration get duration => _duration;
  double get volume => _volume;

  void _initStreams() {
    _subscriptions.add(
      _player.stream.playing.listen((playing) {
        _isPlaying = playing;
        notifyListeners();
      }),
    );

    _subscriptions.add(
      _player.stream.position.listen((pos) {
        _position = pos;
        notifyListeners();
      }),
    );

    _subscriptions.add(
      _player.stream.duration.listen((dur) {
        _duration = dur;
        notifyListeners();
      }),
    );

    _subscriptions.add(
      _player.stream.buffering.listen((buffering) {
        _isBuffering = buffering;
        notifyListeners();
      }),
    );

    _subscriptions.add(
      _player.stream.volume.listen((vol) {
        _volume = vol;
        notifyListeners();
      }),
    );
  }

  Future<void> setStream(StreamLink stream) async {
    _currentStream = stream;
    notifyListeners();
    await _player.open(Media(stream.url));
  }

  Future<void> play() async {
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> togglePlay() async {
    await _player.playOrPause();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  Future<void> stop() async {
    await _player.stop();
    _currentStream = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _player.dispose();
    super.dispose();
  }
}
