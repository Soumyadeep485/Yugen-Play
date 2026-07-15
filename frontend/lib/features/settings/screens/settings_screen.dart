import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Settings",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        children: [
          _buildSettingsTile(
            Icons.palette_rounded,
            "Appearance",
            "Theme, layout, and colors",
          ),
          _buildSettingsTile(
            Icons.play_circle_outline_rounded,
            "Player",
            "Video quality, subtitles, and audio",
          ),
          _buildSettingsTile(
            Icons.storage_rounded,
            "Storage",
            "Download location and cache management",
          ),
          _buildSettingsTile(
            Icons.security_rounded,
            "Privacy",
            "Tracking and data usage",
          ),
          const Divider(color: Colors.white12, height: 32),
          _buildSettingsTile(
            Icons.info_outline_rounded,
            "About",
            "Version 1.0.0-alpha",
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white38, fontSize: 12),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Colors.white24,
        size: 20,
      ),
      onTap: () {}, // Will wire to specific setting pages later
    );
  }
}
