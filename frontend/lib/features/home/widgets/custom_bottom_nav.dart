import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: 0,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home), label: "Home"),

        NavigationDestination(icon: Icon(Icons.search), label: "Search"),

        NavigationDestination(
          icon: Icon(Icons.favorite_border),
          label: "My List",
        ),

        NavigationDestination(icon: Icon(Icons.download), label: "Downloads"),

        NavigationDestination(icon: Icon(Icons.person), label: "Profile"),
      ],
    );
  }
}
