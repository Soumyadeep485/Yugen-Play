import 'package:flutter/material.dart';
import '../../../shared/models/anime.dart';
import '../../../core/radius/app_radius.dart';

class HeroBanner extends StatelessWidget {
  final Anime anime;

  const HeroBanner({super.key, required this.anime});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),

        child: SizedBox(
          height: 260,

          child: Stack(
            fit: StackFit.expand,

            children: [
              Image.network(anime.imageUrl, fit: BoxFit.cover),

              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,

                    colors: [Colors.transparent, Color.fromARGB(190, 0, 0, 0)],
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
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "★ ${anime.rating} • ${anime.genre}",
                      style: TextStyle(color: Colors.white70),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {},

                          icon: const Icon(Icons.play_arrow),

                          label: const Text("Watch"),
                        ),

                        const SizedBox(width: 12),

                        OutlinedButton.icon(
                          onPressed: () {},

                          icon: const Icon(Icons.add),

                          label: const Text("My List"),
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
}
