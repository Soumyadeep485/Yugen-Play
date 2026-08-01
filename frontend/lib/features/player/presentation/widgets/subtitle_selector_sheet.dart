import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart' as mk;
import '../../../../core/colors/app_colors.dart';
import '../../controllers/player_controller.dart';

class SubtitleSelectorSheet extends StatefulWidget {
  final PlayerController playerController;

  // 🛑 Default styling for subtitles
  static double fontSize = 32.0;
  static Color fontColor = Colors.white;
  static Color bgColor = Colors.transparent; 

  const SubtitleSelectorSheet({
    super.key,
    required this.playerController,
  });

  @override
  State<SubtitleSelectorSheet> createState() => _SubtitleSelectorSheetState();
}

class _SubtitleSelectorSheetState extends State<SubtitleSelectorSheet> {
  bool _showSettings = false;

  // Helper to safely snap alpha values to match the dropdown items exactly
  double _getSafeAlpha(Color color) {
    final a = color.a;
    if (a >= 0.9) return 1.0;
    if (a >= 0.5) return 0.7;
    if (a >= 0.2) return 0.4;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.playerController.player;
    final currentTrack = player.state.track.subtitle;
    
    // 🛑 NEW: Use the explicitly extracted subtitles just like the TV player!
    final availableSubtitles = widget.playerController.selectedStream?.subtitles ?? [];
    
    // Determine if subtitles are currently turned off
    final isOff = currentTrack == mk.SubtitleTrack.no() || 
                  currentTrack.id == 'auto' || 
                  currentTrack.id == 'none';

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF14141B).withValues(alpha: 0.85),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (_showSettings)
                      IconButton(
                        onPressed: () => setState(() => _showSettings = false),
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    if (_showSettings) const SizedBox(width: 8),
                    Text(
                      _showSettings ? "Subtitle Settings" : "Subtitles",
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (!_showSettings)
                  GestureDetector(
                    onTap: () => setState(() => _showSettings = true),
                    child: const Text(
                      "Subtitle Settings",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 12),

            // TAB 1: TRACK LIST
            if (!_showSettings) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.subtitles_off_rounded,
                  color: isOff ? AppColors.primary : Colors.white54,
                ),
                title: Text(
                  "Off",
                  style: TextStyle(
                    color: isOff ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: isOff ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isOff
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  player.setSubtitleTrack(mk.SubtitleTrack.no());
                  Navigator.pop(context);
                },
              ),
              
              ...availableSubtitles.map((sub) {
                final subJson = sub.toJson();
                final subUrl = subJson['url']?.toString() ?? subJson['file']?.toString() ?? '';
                final subLabel = subJson['label']?.toString() ?? 'English';
                
                // Match the active track against our URI injections
                final isSelected = !isOff && (currentTrack.title == subLabel || currentTrack.id == subUrl);

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.subtitles_rounded,
                    color: isSelected ? AppColors.primary : Colors.white54,
                  ),
                  title: Text(
                    subLabel.isNotEmpty ? subLabel : "English",
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                      : null,
                  onTap: () {
                    player.setSubtitleTrack(mk.SubtitleTrack.uri(subUrl, title: subLabel, language: 'en'));
                    Navigator.pop(context);
                  },
                );
              }),

              if (availableSubtitles.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    "No external subtitles found for this stream.",
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ),
            ],

            // TAB 2: SUBTITLE SETTINGS
            if (_showSettings) ...[
              _buildSettingRow(
                label: "Font Size",
                value: "${SubtitleSelectorSheet.fontSize.toInt()}pt",
                onDecrease: () => setState(() => SubtitleSelectorSheet.fontSize = (SubtitleSelectorSheet.fontSize - 2).clamp(34.0, 58.0)),
                onIncrease: () => setState(() => SubtitleSelectorSheet.fontSize = (SubtitleSelectorSheet.fontSize + 2).clamp(34.0, 58.0)),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Font Color", style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  Row(
                    children: [
                      _buildColorDot(Colors.white),
                      _buildColorDot(Colors.yellowAccent),
                      _buildColorDot(Colors.cyanAccent),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Background Opacity", style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  DropdownButton<double>(
                    dropdownColor: const Color(0xFF1E1E26),
                    value: _getSafeAlpha(SubtitleSelectorSheet.bgColor),
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 0.0, child: Text("0% (None)")),
                      DropdownMenuItem(value: 0.4, child: Text("40%")),
                      DropdownMenuItem(value: 0.7, child: Text("70%")),
                      DropdownMenuItem(value: 1.0, child: Text("100% (Solid)")),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          SubtitleSelectorSheet.bgColor = val == 0.0 
                              ? Colors.transparent 
                              : Colors.black.withValues(alpha: val);
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow({
    required String label,
    required String value,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        Row(
          children: [
            IconButton(
              onPressed: onDecrease,
              icon: const Icon(Icons.remove_circle_outline, color: Colors.white70, size: 20),
            ),
            Text(value, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            IconButton(
              onPressed: onIncrease,
              icon: const Icon(Icons.add_circle_outline, color: Colors.white70, size: 20),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColorDot(Color color) {
    final isSelected = SubtitleSelectorSheet.fontColor == color;
    return GestureDetector(
      onTap: () => setState(() => SubtitleSelectorSheet.fontColor = color),
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: AppColors.primary, width: 2.5) : null,
        ),
      ),
    );
  }
}