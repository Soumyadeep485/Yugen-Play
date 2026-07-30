import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/colors/app_colors.dart';

class TvUpdateDialog extends StatefulWidget {
  final String version;
  final String releaseNotes;
  final String downloadUrl;

  const TvUpdateDialog({
    super.key,
    required this.version,
    required this.releaseNotes,
    required this.downloadUrl,
  });

  @override
  State<TvUpdateDialog> createState() => _TvUpdateDialogState();
}

class _TvUpdateDialogState extends State<TvUpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusText = "Downloading update...";

  // Standard download logic preserved from your mobile implementation
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

  // Markdown parser with TV-scaled typography
  List<Widget> _parseReleaseNotes(String text) {
    final List<Widget> widgets = [];
    final lines = text.split('\n');

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('### ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 20.0, bottom: 10.0),
            child: Text(
              trimmed.replaceFirst('### ', ''), 
              style: const TextStyle(
                color: AppColors.primary, 
                fontSize: 20, // Scaled up for TV
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      } else if (trimmed.startsWith('- ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0, left: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "• ", 
                  style: TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold)
                ),
                Expanded(
                  child: Text(
                    trimmed.replaceFirst('- ', ''), 
                    style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Text(
              trimmed,
              style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
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
      insetPadding: const EdgeInsets.all(40), // More breathing room for TV
      child: Center(
        child: Container(
          width: 600, // Constrain width so it doesn't stretch across the massive TV
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1E222A).withValues(alpha: 0.95), // Solid faux-glass
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 40, offset: const Offset(0, 20)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.system_update_rounded, color: AppColors.primary, size: 36),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      "Update Available",
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.version,
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              
              // Scrollable Release Notes
              Flexible(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _parseReleaseNotes(widget.releaseNotes),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),

              // Bottom Actions / Download Progress
              _isDownloading
                  ? Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _progress,
                            backgroundColor: Colors.white10,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _statusText,
                          style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _TvUpdateDialogButton(
                          label: "Later",
                          isPrimary: false,
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 16),
                        _TvUpdateDialogButton(
                          label: "Update Now",
                          isPrimary: true,
                          autofocus: true, // 🚀 Snaps remote focus right to the download button
                          onTap: _startDownload,
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// TV FOCUSABLE BUTTON FOR DIALOG
// ============================================================================
class _TvUpdateDialogButton extends StatefulWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;
  final bool autofocus;

  const _TvUpdateDialogButton({
    required this.label,
    required this.isPrimary,
    required this.onTap,
    this.autofocus = false,
  });

  @override
  State<_TvUpdateDialogButton> createState() => _TvUpdateDialogButtonState();
}

class _TvUpdateDialogButtonState extends State<_TvUpdateDialogButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        autofocus: widget.autofocus,
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutQuart,
          transform: Matrix4.diagonal3Values(_isFocused ? 1.05 : 1.0, _isFocused ? 1.05 : 1.0, 1.0),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            color: _isFocused 
                ? (widget.isPrimary ? Colors.white : Colors.white24)
                : (widget.isPrimary ? AppColors.primary : Colors.transparent),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isFocused ? Colors.white : Colors.transparent,
              width: 2,
            ),
            boxShadow: _isFocused 
                ? [BoxShadow(color: Colors.white.withValues(alpha: 0.3), blurRadius: 15, spreadRadius: 1)]
                : [],
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: _isFocused 
                  ? Colors.black 
                  : (widget.isPrimary ? Colors.black : Colors.white70),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}