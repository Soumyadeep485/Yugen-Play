import 'package:flutter/material.dart';
import '../../../../core/utils/device_type.dart';
import '../../../../shared/models/anime.dart';
import '../../../tv/presentation/screens/tv_anime_details_screen.dart';
import 'mobile_anime_details_screen.dart';

class AnimeDetailsScreen extends StatelessWidget {
  final Anime anime;

  const AnimeDetailsScreen({super.key, required this.anime});

  @override
  Widget build(BuildContext context) {
    // 🚦 Traffic Cop: Routes TV users to the TV layout, mobile to the floating pill
    return DeviceType.isTv 
        ? TvAnimeDetailsScreen(anime: anime)
        : MobileAnimeDetailsScreen(anime: anime);
  }
}