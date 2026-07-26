import 'package:flutter/material.dart';
import '../../../../core/colors/app_colors.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String username;
  final VoidCallback onSearchPressed;

  const HomeAppBar({
    super.key,
    this.username = "Guest",
    required this.onSearchPressed,
  });

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? "Good morning"
        : hour < 17
        ? "Good afternoon"
        : "Good evening";

    return AppBar(
      automaticallyImplyLeading: false,
      title: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "$greeting,",
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.2,
              ),
            ),
            Text(
              username,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.textPrimary.withValues(alpha: 0.05),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.search_rounded,
                color: AppColors.textPrimary,
                size: 26,
              ),
              onPressed: onSearchPressed,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}