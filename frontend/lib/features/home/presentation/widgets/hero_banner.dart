import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../shared/models/anime.dart';
import '../../../details/presentation/screens/anime_details_screen.dart';

class HeroBanner extends StatefulWidget {
  final List<Anime> animeList;
  // 🛑 NEW: Passes the image URL instead of a color
  final Function(String)? onImageChanged; 

  const HeroBanner({super.key, required this.animeList, this.onImageChanged});

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();
    
    // 🛑 Pass the very first image URL as soon as the widget loads
    if (widget.animeList.isNotEmpty && widget.onImageChanged != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final anime = widget.animeList[0];
        final imageUrl = anime.bannerImage ?? anime.coverImage ?? '';
        widget.onImageChanged!(imageUrl);
      });
    }
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (_pageController.hasClients && widget.animeList.isNotEmpty) {
        int nextPage = _currentPage + 1;
        if (nextPage >= widget.animeList.length) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.animeList.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 380,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              
              // 🛑 Instantly pass the new image URL when swiped
              if (widget.onImageChanged != null) {
                final anime = widget.animeList[index];
                final imageUrl = anime.bannerImage ?? anime.coverImage ?? '';
                widget.onImageChanged!(imageUrl);
              }
            },
            itemCount: widget.animeList.length,
            itemBuilder: (context, index) {
              final anime = widget.animeList[index];
              final bannerUrl = anime.bannerImage ?? anime.coverImage ?? '';
              final synopsis = (anime.description != null && anime.description!.isNotEmpty) 
                  ? anime.description!.replaceAll("<br>", "\n") 
                  : "No synopsis available.";

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AnimeDetailsScreen(anime: anime),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            image: DecorationImage(
                              image: NetworkImage(bannerUrl),
                              fit: BoxFit.cover,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              anime.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (anime.rating != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.white70, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    (anime.rating! / 10).toStringAsFixed(1),
                                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                synopsis,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8), fontSize: 12, height: 1.4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_outward_rounded, color: Colors.white38, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.animeList.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 8 : 6,
              height: _currentPage == index ? 8 : 6,
              decoration: BoxDecoration(
                color: _currentPage == index ? AppColors.primary : Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}