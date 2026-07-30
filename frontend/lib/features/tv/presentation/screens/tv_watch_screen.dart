import 'package:flutter/material.dart';

import '../../../../shared/models/anime.dart';
// NOTE: Adjust this import path to point to exactly where your WatchTab file is located!
import '../../../details/presentation/widgets/watch_tab.dart'; 

class TvWatchScreen extends StatelessWidget {
  final Anime anime;

  const TvWatchScreen({super.key, required this.anime});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E13), // Matches the TV dark theme
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(32),
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            ),
          ),
        ),
        title: Text(
          anime.title,
          style: const TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        // This injects your exact episode fetching and chunking logic directly into the TV screen
        child: WatchTab(anime: anime), 
      ),
    );
  }
}