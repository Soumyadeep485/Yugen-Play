import 'package:flutter/material.dart';
import 'package:frontend/features/extensions/services/anikoto_extension_service.dart';
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
  bool _isRacing = false;
  String _statusText = "Discovering available servers...";
  String? _errorMessage;

  List<ServerData> _subServers = [];
  List<ServerData> _dubServers = [];

  @override
  void initState() {
    super.initState();
    _startDiscovery();
  }

  Future<void> _startDiscovery() async {
    try {
      final rawServers = await _playerController.fetchRawServersForEpisode(
        episode: widget.episode,
        animeId: widget.animeId,
        animeTitle: widget.animeTitle,
        posterUrl: widget.posterUrl,
        totalEpisodes: widget.totalEpisodes,
      );

      if (!mounted) return;

      if (rawServers.isEmpty) {
        setState(() {
          _isDiscovering = false;
          _errorMessage = "No stream servers found for this episode.";
        });
        return;
      }

      _subServers = rawServers.where((s) => !s.isDub).toList();
      _dubServers = rawServers.where((s) => s.isDub).toList();

      if (widget.autoSelectDub != null) {
        final targetServers = widget.autoSelectDub! ? _dubServers : _subServers;
        final fallbackServers = widget.autoSelectDub! ? _subServers : _dubServers;

        if (targetServers.isNotEmpty) {
          _raceSelectedCategory(targetServers, widget.autoSelectDub! ? "DUB" : "SUB");
          return;
        } else if (fallbackServers.isNotEmpty) {
          _raceSelectedCategory(fallbackServers, widget.autoSelectDub! ? "SUB" : "DUB");
          return;
        }
      }

      setState(() {
        _isDiscovering = false;
        _statusText = "Select audio preference:";
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDiscovering = false;
          _errorMessage = "Failed to discover servers.";
        });
      }
    }
  }

  Future<void> _raceSelectedCategory(List<ServerData> servers, String categoryName) async {
    setState(() {
      _isRacing = true;
      _statusText = "Racing $categoryName servers for fastest response...";
    });

    // 🛑 Background Extraction: Extract remaining raw servers so player quality sheet is full
    final unselected = _playerController.rawServers.where((s) => !servers.contains(s)).toList();
    if (unselected.isNotEmpty) {
      for (final s in unselected) {
        AnikotoExtensionService().extractFromSingleServer(s).then((stream) {
          if (stream != null) _playerController.addStreamLink(stream);
        }).catchError((_) {});
      }
    }

    final winningStream = await _playerController.raceServers(servers);

    if (!mounted) return;

    if (winningStream != null) {
      _playerController.selectStream(winningStream, startPosition: widget.startPosition); 
      Navigator.pop(context); 
      widget.onStreamReady(winningStream);
    } else {
      setState(() {
        _isRacing = false;
        _errorMessage = "Failed to connect to $categoryName servers.";
      });
    }
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
                if (_isDiscovering || _isRacing)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
                  )
                else
                  const Icon(Icons.tune_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: 14),
                const Text(
                  "Preparing stream",
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

            if (!_isDiscovering && !_isRacing && _errorMessage == null)
              Row(
                children: [
                  if (_subServers.isNotEmpty)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _raceSelectedCategory(_subServers, "SUB"),
                        icon: const Icon(Icons.subtitles_rounded, size: 18),
                        label: Text("SUB (${_subServers.length})"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  if (_subServers.isNotEmpty && _dubServers.isNotEmpty)
                    const SizedBox(width: 12),
                  if (_dubServers.isNotEmpty)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _raceSelectedCategory(_dubServers, "DUB"),
                        icon: const Icon(Icons.mic_rounded, size: 18),
                        label: Text("DUB (${_dubServers.length})"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}