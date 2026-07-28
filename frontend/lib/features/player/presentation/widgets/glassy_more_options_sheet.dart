import 'package:flutter/material.dart';

class GlassyMoreOptionsSheet extends StatelessWidget {
  final ValueChanged<String> onToastMessage;

  const GlassyMoreOptionsSheet({super.key, required this.onToastMessage});

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
              const Text("More Options", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.picture_in_picture_alt_rounded, color: Colors.white),
            title: const Text("Picture in Picture", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              onToastMessage("PIP coming soon!");
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.report_problem_rounded, color: Colors.white),
            title: const Text("Report Issue", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              onToastMessage("Report sent.");
            },
          )
        ],
      ),
    );
  }
}