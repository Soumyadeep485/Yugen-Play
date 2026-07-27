import 'package:flutter/material.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../shared/models/anime.dart';
import '../../../details/presentation/screens/anime_details_screen.dart';
import '../../services/library_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  final LibraryService _libraryService = LibraryService();
  late TabController _tabController;
  List<Map<String, dynamic>> _libraryItems = [];

  final List<String> _tabs = [
    'All',
    'Watching',
    'Plan to Watch',
    'Completed',
    'Dropped'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadLibrary();

    // Reload the library whenever the user switches tabs to ensure it's fresh
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  void _loadLibrary() {
    setState(() {
      _libraryItems = _libraryService.getLibraryItems();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildGrid(String? statusFilter) {
    // Filter the items in memory based on the current tab
    final filteredItems = statusFilter == 'All'
        ? _libraryItems
        : _libraryItems.where((item) => item['status'] == statusFilter).toList();

    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              "No anime found in $statusFilter",
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        final title = item['title'] ?? 'Unknown';
        final poster = item['posterUrl'] ?? '';
        final status = item['status'] ?? '';

        return GestureDetector(
          onTap: () {
            // Reconstruct the Anime object to pass to the details screen
            final reconstructedAnime = Anime(
              id: item['animeId'],
              title: title,
              coverImage: poster,
              bannerImage: poster,
              status: status, // Passing the saved status back
            );

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AnimeDetailsScreen(anime: reconstructedAnime),
              ),
            ).then((_) {
              // Reload the library when coming back just in case they deleted it
              _loadLibrary();
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.card,
                    image: DecorationImage(
                      image: NetworkImage(poster),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          "My Library",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorWeight: 3,
          dividerColor: Colors.transparent,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((tab) => _buildGrid(tab)).toList(),
      ),
    );
  }
}