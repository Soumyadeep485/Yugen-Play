import 'package:flutter/material.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../shared/models/anime.dart';
import '../../services/library_service.dart';

class LibraryStatusSheet extends StatefulWidget {
  final Anime anime;
  final String? initialStatus;
  final Function(String?) onStatusUpdated;

  const LibraryStatusSheet({
    super.key,
    required this.anime,
    required this.initialStatus,
    required this.onStatusUpdated,
  });

  @override
  State<LibraryStatusSheet> createState() => _LibraryStatusSheetState();
}

class _LibraryStatusSheetState extends State<LibraryStatusSheet> {
  final LibraryService _libraryService = LibraryService();
  final List<String> _statuses = ['Watching', 'Plan to Watch', 'Completed', 'Dropped'];
  late String? _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.initialStatus;
  }

  Future<void> _updateStatus(String status) async {
    await _libraryService.saveToLibrary(anime: widget.anime, status: status);
    setState(() => _currentStatus = status);
    widget.onStatusUpdated(status);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _removeFromLibrary() async {
    await _libraryService.removeFromLibrary(widget.anime.id.toString());
    setState(() => _currentStatus = null);
    widget.onStatusUpdated(null);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Add to Library",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_currentStatus != null)
                IconButton(
                  onPressed: _removeFromLibrary,
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  tooltip: "Remove from Library",
                )
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _statuses.length,
            itemBuilder: (context, index) {
              final status = _statuses[index];
              final isSelected = _currentStatus == status;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  status,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                    : null,
                onTap: () => _updateStatus(status),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}