import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../search/presentation/screens/search_screen.dart';
import '../../../list/presentation/screens/list_screen.dart';
import '../../../library/presentation/screens/library_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const ListScreen(),
    const LibraryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildGlassyNavBar(),
    );
  }

  Widget _buildGlassyNavBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.textPrimary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: AppColors.textPrimary.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(Icons.home_filled, 0),
                  _buildNavItem(Icons.movie_creation_rounded, 1),
                  _buildNavItem(Icons.view_list_rounded, 2),
                  _buildNavItem(Icons.menu_book_rounded, 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutExpo,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          color: isActive ? AppColors.primary : AppColors.textSecondary,
          size: 26,
        ),
      ),
    );
  }
}