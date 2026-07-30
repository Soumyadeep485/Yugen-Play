import 'package:flutter/material.dart';


import 'tv_library_screen.dart';
import '../../../list/presentation/screens/list_screen.dart';
import 'tv_search_screen.dart';
import 'tv_home_screen.dart';

class TvRootScreen extends StatefulWidget {
  const TvRootScreen({super.key});

  @override
  State<TvRootScreen> createState() => _TvRootScreenState();
}

class _TvRootScreenState extends State<TvRootScreen> {
  int _selectedIndex = 0;

  // Reordered to match the Top Nav structure
  final List<Widget> _screens = [
    const TvHomeScreen(),      // 0: HOME
    const TvLibraryScreen(),     // 1: LIBRARY
    const ListScreen(),        // 2: SCHEDULE / LISTS
    const TvSearchScreen(),    // 3: SEARCH
    const Center(child: Text("Settings", style: TextStyle(color: Colors.white))), // 4: SETTINGS (Placeholder)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Sleek pure black foundation
      body: Column(
        children: [
          // ==========================================
          // TOP NAVIGATION BAR (Matches Screenshot)
          // ==========================================
          Padding(
            padding: const EdgeInsets.only(top: 32, left: 40, right: 40, bottom: 16),
            child: FocusTraversalGroup(
              policy: WidgetOrderTraversalPolicy(), // Strict Left-to-Right D-Pad routing
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // FAR LEFT: Search Icon
                  _TvNavIconButton(
                    icon: Icons.search_rounded,
                    isSelected: _selectedIndex == 3,
                    onTap: () => setState(() => _selectedIndex = 3),
                  ),

                  // CENTER: Text Tabs
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _TvNavTextButton(
                        label: "HOME",
                        isSelected: _selectedIndex == 0,
                        onTap: () => setState(() => _selectedIndex = 0),
                      ),
                      const SizedBox(width: 32),
                      _TvNavTextButton(
                        label: "LIBRARY",
                        isSelected: _selectedIndex == 1,
                        onTap: () => setState(() => _selectedIndex = 1),
                      ),
                      const SizedBox(width: 32),
                      _TvNavTextButton(
                        label: "SCHEDULE",
                        isSelected: _selectedIndex == 2,
                        onTap: () => setState(() => _selectedIndex = 2),
                      ),
                    ],
                  ),

                  // FAR RIGHT: Settings Icon
                  _TvNavIconButton(
                    icon: Icons.settings_rounded,
                    isSelected: _selectedIndex == 4,
                    onTap: () => setState(() => _selectedIndex = 4),
                  ),
                ],
              ),
            ),
          ),

          // ==========================================
          // MAIN CONTENT AREA
          // ==========================================
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TV TOP NAV HELPER WIDGETS
// ============================================================================

class _TvNavTextButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TvNavTextButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TvNavTextButton> createState() => _TvNavTextButtonState();
}

class _TvNavTextButtonState extends State<_TvNavTextButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _isFocused ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isFocused ? Colors.white : Colors.transparent,
              width: 2,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              // Matches screenshot: White & bold if selected, Grey if not
              color: widget.isSelected || _isFocused ? Colors.white : Colors.white54,
              fontSize: 16,
              fontWeight: widget.isSelected || _isFocused ? FontWeight.bold : FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _TvNavIconButton extends StatefulWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TvNavIconButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TvNavIconButton> createState() => _TvNavIconButtonState();
}

class _TvNavIconButtonState extends State<_TvNavIconButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        borderRadius: BorderRadius.circular(32), // Circular focus for icons
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isFocused ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: _isFocused ? Colors.white : Colors.transparent,
              width: 2,
            ),
          ),
          child: Icon(
            widget.icon,
            // Matches screenshot: White if active/focused, Grey if inactive
            color: widget.isSelected || _isFocused ? Colors.white : Colors.white54,
            size: 28,
          ),
        ),
      ),
    );
  }
}