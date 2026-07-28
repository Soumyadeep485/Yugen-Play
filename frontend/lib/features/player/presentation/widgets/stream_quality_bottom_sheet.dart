import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../core/colors/app_colors.dart';
import '../../models/stream_link.dart';

class StreamQualityBottomSheet extends StatelessWidget {
  final List<StreamLink> streamLinks;
  final StreamLink? selectedStream;
  final ValueChanged<StreamLink> onStreamSelected;
  final bool isLoading;

  const StreamQualityBottomSheet({
    super.key,
    required this.streamLinks,
    this.selectedStream,
    required this.onStreamSelected,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final subLinks = streamLinks.where((link) => !link.quality.toLowerCase().contains('dub')).toList();
    final dubLinks = streamLinks.where((link) => link.quality.toLowerCase().contains('dub')).toList();

    // 1. SafeArea prevents it from drawing underneath the Android navigation bar
    return SafeArea(
      // 2. Padding creates the "Floating" effect away from the screen edges
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 24.0),
        child: ClipRRect(
          // 3. Fully rounded corners on all 4 sides!
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              // 4. Tightened up the inner padding to eliminate wasted space
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: const Color(0xFF14141B).withValues(alpha: 0.8), 
                // Full border wraps the floating pill
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15), 
                  width: 1,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Hugs the content tightly
                  children: [
                    // Condensed Drag Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    
                    const Text(
                      "Select Server", 
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 16),

                    if (subLinks.isNotEmpty) ...[
                      _buildSectionHeader(Icons.subtitles_rounded, "SUBTITLED"),
                      const SizedBox(height: 10),
                      ...subLinks.map((stream) => _buildStreamTile(stream, context)),
                      const SizedBox(height: 16), // Tighter spacing between sections
                    ],

                    if (dubLinks.isNotEmpty) ...[
                      _buildSectionHeader(Icons.mic_rounded, "DUBBED"),
                      const SizedBox(height: 10),
                      ...dubLinks.map((stream) => _buildStreamTile(stream, context)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 16),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 12, // Slightly smaller and cleaner
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildStreamTile(StreamLink stream, BuildContext context) {
    final isSelected = selectedStream?.url == stream.url;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Material(
        color: Colors.transparent, 
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            onStreamSelected(stream);
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.primary.withValues(alpha: 0.2),
          highlightColor: AppColors.primary.withValues(alpha: 0.1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            // Tightened the vertical padding inside the tiles to save screen height
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected 
                    ? AppColors.primary.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.05),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppColors.primary.withValues(alpha: 0.2) 
                        : Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.dns_rounded, 
                    color: isSelected ? AppColors.primary : Colors.white54,
                    size: 18, // Slightly smaller icon
                  ),
                ),
                const SizedBox(width: 14),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stream.sourceName,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2), // Tighter gap between text
                      Text(
                        stream.quality,
                        style: TextStyle(
                          color: isSelected ? Colors.white70 : Colors.white38,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}