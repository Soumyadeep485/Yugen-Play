import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/colors/app_colors.dart';

class SourceSelector extends StatefulWidget {
  final String initialSource;
  final Function(String) onSourceChanged;

  const SourceSelector({
    super.key,
    required this.initialSource,
    required this.onSourceChanged,
  });

  @override
  State<SourceSelector> createState() => _SourceSelectorState();
}

class _SourceSelectorState extends State<SourceSelector>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late String _selectedSource;
  final List<String> _sources = [
    "AnimeTosho (Torrent)",
    "Nyaa (Torrent)",
    "GogoAnime (Scraper)",
  ];

  @override
  void initState() {
    super.initState();
    _selectedSource = widget.initialSource;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.05),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.extension,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "SELECT SOURCE",
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedSource,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox(height: 0, width: double.infinity),
                secondChild: Column(
                  children: _sources.map((source) {
                    final isSelected = source == _selectedSource;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedSource = source;
                          _isExpanded = false;
                        });
                        widget.onSourceChanged(source);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 56,
                          vertical: 12,
                        ),
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        child: Text(
                          source,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ],
          ),
        ),
      ),
    );
  }
}