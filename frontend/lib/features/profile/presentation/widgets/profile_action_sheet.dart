import 'package:flutter/material.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../downloads/presentation/screens/downloads_screen.dart';
import '../../../settings/presentation/screens/extension_manager_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

class ProfileActionSheet extends StatelessWidget {
  const ProfileActionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(
              Icons.extension_outlined,
              color: AppColors.textPrimary,
            ),
            title: const Text(
              "Extension Manager",
              style: TextStyle(color: AppColors.textPrimary),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ExtensionManagerScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.download_outlined,
              color: AppColors.textPrimary,
            ),
            title: const Text(
              "Downloads",
              style: TextStyle(color: AppColors.textPrimary),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DownloadsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.settings_outlined,
              color: AppColors.textPrimary,
            ),
            title: const Text(
              "Settings",
              style: TextStyle(color: AppColors.textPrimary),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
