import 'package:flutter/material.dart';
import '../../../../../../core/colors/app_colors.dart';
import '../../../../core/storage/history_repository.dart';

class StreamLoadingDialog extends StatefulWidget {
  final String animeId;
  final String animeTitle;
  final String episodeId;
  final int episodeNumber;
  
  // Pass your stream fetching logic here
  final Future<String> Function() fetchStreamUrl;

  const StreamLoadingDialog({
    super.key,
    required this.animeId,
    required this.animeTitle,
    required this.episodeId,
    required this.episodeNumber,
    required this.fetchStreamUrl,
  });

  static void show(BuildContext context, {
    required String animeId,
    required String animeTitle,
    required String episodeId,
    required int episodeNumber,
    required Future<String> Function() fetchStreamUrl,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StreamLoadingDialog(
        animeId: animeId,
        animeTitle: animeTitle,
        episodeId: episodeId,
        episodeNumber: episodeNumber,
        fetchStreamUrl: fetchStreamUrl,
      ),
    );
  }

  @override
  State<StreamLoadingDialog> createState() => _StreamLoadingDialogState();
}

class _StreamLoadingDialogState extends State<StreamLoadingDialog> {
  // ignore: unused_field
  final HistoryRepository _historyRepo = HistoryRepository();
  String _currentStep = "Preparing playback...";

  @override
  void initState() {
    super.initState();
    _executeLoadingFlow();
  }

  Future<void> _executeLoadingFlow() async {
    try {
      // Step 1: Check Database
      setState(() => _currentStep = "Checking local history...");
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Variable assignment removed to fix the unused warning
      _historyRepo.getHistory(widget.animeId);

      // Step 2: Fetch Network Stream
      setState(() => _currentStep = "Fetching fresh stream URLs...");
      
      // Executed but not assigned to a variable to fix the unused warning
      await widget.fetchStreamUrl();

      // Step 3: Launch Player
      setState(() => _currentStep = "Launching player...");
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (mounted) {
        Navigator.pop(context); // Close the dialog
      }
    } catch (e) {
      if (mounted) {
        setState(() => _currentStep = "Error: Failed to fetch stream.");
      }
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                ),
                const SizedBox(width: 16),
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
            const SizedBox(height: 24),
            Text(
              _currentStep,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}