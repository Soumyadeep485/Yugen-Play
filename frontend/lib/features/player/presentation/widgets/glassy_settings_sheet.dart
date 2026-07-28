import 'package:flutter/material.dart';

class GlassySettingsSheet extends StatelessWidget {
  const GlassySettingsSheet({super.key});

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Player Settings", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Text("Additional player settings will appear here.", style: TextStyle(color: Colors.white38, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}