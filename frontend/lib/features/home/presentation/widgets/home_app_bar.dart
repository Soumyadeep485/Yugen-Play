import 'package:flutter/material.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../profile/presentation/widgets/profile_bottom_sheet.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  // 🛑 Made nullable so your home_screen.dart doesn't crash
  final VoidCallback? onSearchPressed;

  const HomeAppBar({
    super.key,
    this.onSearchPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      leadingWidth: 70,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (_) => const ProfileBottomSheet(),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white70),
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Anime",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "Good morning",
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
      // 🛑 THE SEARCH ICON (ACTIONS ARRAY) HAS BEEN COMPLETELY ANNIHILATED
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}