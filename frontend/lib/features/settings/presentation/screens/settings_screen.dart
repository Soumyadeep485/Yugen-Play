import 'package:flutter/material.dart';
import 'package:frontend/core/colors/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          "Settings",
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
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
          Divider(color: AppColors.textSecondary.withValues(alpha: 0.2), height: 32),
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
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textSecondary.withValues(alpha: 0.5),
        size: 20,
      ),
      onTap: () {}, // Will wire to specific setting pages later
    );
  }
}