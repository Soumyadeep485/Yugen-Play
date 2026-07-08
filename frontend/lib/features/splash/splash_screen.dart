import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "Yugen Play",
          style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
