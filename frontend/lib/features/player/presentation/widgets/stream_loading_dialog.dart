import 'package:flutter/material.dart';
import 'package:frontend/features/player/controllers/player_controller.dart';
import 'package:frontend/features/player/models/episode.dart';
import 'package:frontend/features/player/models/stream_link.dart';
import '../../../../core/colors/app_colors.dart';

class StreamLoadingDialog extends StatefulWidget {
  final PlayerController playerController; 
  final Episode episode;
  final String animeId;
  final String animeTitle;
  final String posterUrl;
  final int? totalEpisodes;
  final Duration? startPosition;
  final bool? autoSelectDub;
  final Function(StreamLink stream) onStreamReady;

  const StreamLoadingDialog({
    super.key,
    required this.playerController, 
    required this.episode,
    required this.animeId,
    required this.animeTitle,
    required this.posterUrl,
    this.totalEpisodes,
    this.startPosition,
    this.autoSelectDub,
    required this.onStreamReady,
  });

  static Future<void> show(
    BuildContext context, {
    required PlayerController playerController, 
    required Episode episode,
    required String animeId,
    required String animeTitle,
    required String posterUrl,
    int? totalEpisodes,
    Duration? startPosition,
    bool? autoSelectDub,
    required Function(StreamLink stream) onStreamReady,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StreamLoadingDialog(
        playerController: playerController, 
        episode: episode,
        animeId: animeId,
        animeTitle: animeTitle,
        posterUrl: posterUrl,
        totalEpisodes: totalEpisodes,
        startPosition: startPosition,
        autoSelectDub: autoSelectDub,
        onStreamReady: onStreamReady,
      ),
    );
  }

  @override
  State<StreamLoadingDialog> createState() => _StreamLoadingDialogState();
}

class _StreamLoadingDialogState extends State<StreamLoadingDialog> {
  PlayerController get _playerController => widget.playerController; 

  bool _isDiscovering = true;
  String _statusText = "Extracting streams from extension...";
  String? _errorMessage;

  List<StreamLink> _allStreams = [];

  @override
  void initState() {
    super.initState();
    _startDiscovery();
  }

  Future<void> _startDiscovery() async {
    try {
      // 🚀 Directly loads finalized streams from the dynamic extension
      final streams = await _playerController.loadStreamsForEpisode(
        episode: widget.episode,
        animeId: widget.animeId,
        animeTitle: widget.animeTitle,
        posterUrl: widget.posterUrl,
        totalEpisodes: widget.totalEpisodes,
      );

      if (!mounted) return;

      if (streams.isEmpty) {
        setState(() {
          _isDiscovering = false;
          _errorMessage = _playerController.errorMessage ?? "No streams found for this episode.";
        });
        return;
      }

      setState(() {
        _allStreams = streams;
        _isDiscovering = false;
        _statusText = "Select a server:";
      });
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDiscovering = false;
          _errorMessage = "Failed to extract streams.";
        });
      }
    }
  }

  void _selectStream(StreamLink stream) {
    _playerController.selectStream(stream, startPosition: widget.startPosition); 
    Navigator.pop(context); 
    widget.onStreamReady(stream);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF14141B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (_isDiscovering)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
                  )
                else
                  const Icon(Icons.dns_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: 14),
                const Text(
                  "Available Servers",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                )
              ],
            ),
            const SizedBox(height: 20),

            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
            ] else ...[
              Text(
                _statusText,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),
            ],

            if (!_isDiscovering && _errorMessage == null)
              // 🚀 THE FIX: Flexible completely prevents the bottom overflow on TVs
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _allStreams.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final stream = _allStreams[index];
                    final isDub = stream.quality.toLowerCase().contains('dub') || stream.sourceName.toLowerCase().contains('dub');
                    
                    return ElevatedButton.icon(
                      onPressed: () => _selectStream(stream),
                      icon: Icon(isDub ? Icons.mic_rounded : Icons.subtitles_rounded, size: 18),
                      label: Text(
                        stream.quality, 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: isDub ? Colors.white24 : AppColors.primary.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}