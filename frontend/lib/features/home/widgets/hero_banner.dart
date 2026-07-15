import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../shared/models/anime.dart';
import '../../../core/radius/app_radius.dart';
import '../../../shared/widgets/premium_network_image.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../../shared/widgets/buttons/secondary_button.dart';
import '../../details/anime_details_screen.dart';

class HeroBanner extends StatelessWidget {
  final Anime anime;

  const HeroBanner({super.key, required this.anime});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: SizedBox(
          height: (screenHeight * 0.38).clamp(300.0, 420.0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: 'HeroBanner_${anime.id}',
                child: PremiumNetworkImage(
                  imageUrl: anime.imageUrl,
                  memCacheHeight: 800,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.25),
                      Colors.black.withValues(alpha: 0.65),
                      Colors.black,
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anime.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            height: 1.05,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (anime.rating > 0)
                          _buildGlassyChip(
                            "⭐ ${anime.rating.toStringAsFixed(1)}",
                          ),
                        ...anime.genres
                            .take(3)
                            .map((genre) => _buildGlassyChip(genre)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: SizedBox(
                            height: 48,
                            child: PrimaryButton(
                              text: "Watch Now",
                              icon: Icons.play_arrow_rounded,
                              onPressed: () {
                                Navigator.of(context, rootNavigator: true).push(
                                  MaterialPageRoute(
                                    builder: (_) => AnimeDetailsScreen(
                                      animeId: anime.id,
                                      heroTag: 'HeroBanner_${anime.id}',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 4,
                          child: SizedBox(
                            height: 48,
                            child: SecondaryButton(
                              text: "My List",
                              icon: Icons.add_rounded,
                              onPressed: () {},
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassyChip(String text) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
