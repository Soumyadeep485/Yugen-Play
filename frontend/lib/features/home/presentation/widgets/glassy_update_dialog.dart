import 'dart:ui'; // 👈 Added for the glass blur effect
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class GlassyUpdateDialog extends StatefulWidget {
  final String version;
  final String releaseNotes;
  final String downloadUrl;

  const GlassyUpdateDialog({
    super.key,
    required this.version,
    required this.releaseNotes,
    required this.downloadUrl,
  });

  @override
  State<GlassyUpdateDialog> createState() => _GlassyUpdateDialogState();
}

class _GlassyUpdateDialogState extends State<GlassyUpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusText = "Downloading update...";

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/update_${widget.version}.apk';

      final dio = Dio();
      await dio.download(
        widget.downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progress = received / total;
              _statusText = "Downloading... ${(_progress * 100).toStringAsFixed(0)}%";
            });
          }
        },
      );

      setState(() => _statusText = "Starting installer...");
      final result = await OpenFilex.open(savePath);
      
      if (result.type != ResultType.done) {
        setState(() => _statusText = "Failed to open installer: ${result.message}");
      }
    } catch (e) {
      setState(() {
        _statusText = "Download failed. Please try again later.";
        _isDownloading = false;
      });
    }
  }

  // 👇 The Custom Markdown Parser
  List<Widget> _parseReleaseNotes(String text) {
    final List<Widget> widgets = [];
    final lines = text.split('\n');

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue; // Skip empty gaps

      if (trimmed.startsWith('### ')) {
        // Render Headings beautifully
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
            child: Text(
              trimmed.replaceFirst('### ', ''), // Strip the Markdown tags
              style: const TextStyle(
                color: Color(0xFFC4C4FF), // Matches your primary button color
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      } else if (trimmed.startsWith('- ')) {
        // Render Bullet Points with proper indentation
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "• ", 
                  style: TextStyle(color: Color(0xFFC4C4FF), fontSize: 16, fontWeight: FontWeight.bold)
                ),
                Expanded(
                  child: Text(
                    trimmed.replaceFirst('- ', ''), // Strip the dash
                    style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // Render normal text
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              trimmed,
              style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      // 👇 Added ClipRRect and BackdropFilter for True Glass effect
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28), // Smoother M3 corners
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              // Lowered opacity so the blur actually shows through
              color: const Color(0xFF14141B).withValues(alpha: 0.8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(Icons.system_update_rounded, color: Color(0xFFC4C4FF), size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Update Available",
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC4C4FF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        widget.version,
                        style: const TextStyle(color: Color(0xFFC4C4FF), fontWeight: FontWeight.w900, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Scrollable & Parsed Release Notes
                Flexible(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      // 👇 Injects our beautifully parsed widgets here
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _parseReleaseNotes(widget.releaseNotes),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),

                // Bottom Actions / Download Progress
                _isDownloading
                    ? Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _progress,
                              backgroundColor: Colors.white10,
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC4C4FF)),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _statusText,
                            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            child: const Text("Later", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _startDownload,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC4C4FF),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text("Update Now", style: TextStyle(fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}