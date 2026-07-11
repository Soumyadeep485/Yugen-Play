import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../controllers/playback_controller.dart';

class PlayerVideoSurface extends StatelessWidget {
  final PlaybackController controller;

  const PlayerVideoSurface({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Video(
          controller: controller.videoController,
          // Explicitly pass NoVideoControls so media_kit's default native UI
          // doesn't overlap with your custom 'player_controls.dart' UI
          controls: NoVideoControls,
        ),
      ),
    );
  }
}
