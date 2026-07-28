import 'package:flutter/material.dart';
import '../../../../core/colors/app_colors.dart';

class GlassyPlaylistSheet extends StatelessWidget {
  final String title;

  const GlassyPlaylistSheet({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
  color: const Color(0xFF14141B).withValues(alpha: 0.85), // Glassy, semi-transparent
  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
  border: Border.all(color: Colors.white10),
),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Episodes Playlist", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary),
            title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text("Currently Playing", style: TextStyle(color: Colors.white54, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}