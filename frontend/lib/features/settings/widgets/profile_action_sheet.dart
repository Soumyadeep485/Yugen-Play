import 'package:flutter/material.dart';
import '../../../core/colors/app_colors.dart';
import '../../downloads/screens/downloads_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/extension_manager_screen.dart';

class ProfileActionSheet extends StatelessWidget {
  const ProfileActionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(
          0xFF1E1E1E,
        ), // Slightly lighter than background to stand out
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // User Profile Header
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: const Text(
              "Guest User",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: Colors.white12),

          // 1. Extension Manager
          _buildActionItem(
            context,
            icon: Icons.extension_rounded,
            title: "Extension Manager",
            onTap: () {
              Navigator.pop(context); // Close the bottom sheet first
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ExtensionManagerScreen(),
                ),
              );
            },
          ),

          // 2. Downloads
          _buildActionItem(
            context,
            icon: Icons.download_rounded,
            title: "Downloads",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DownloadsScreen()),
              );
            },
          ),

          // 3. AniList Sync (Disabled for now)
          _buildActionItem(
            context,
            icon: Icons.sync_rounded,
            title: "AniList Sync",
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("AniList Sync coming in later update."),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),

          // 4. Settings
          _buildActionItem(
            context,
            icon: Icons.settings_rounded,
            title: "Settings",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white70)),
      onTap: onTap,
    );
  }
}
