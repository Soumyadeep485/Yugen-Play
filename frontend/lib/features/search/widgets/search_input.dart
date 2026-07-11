import 'package:flutter/material.dart';

class SearchInput extends StatelessWidget {
  const SearchInput({super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: const TextStyle(color: Colors.white),

      decoration: InputDecoration(
        hintText: "Search anime...",
        hintStyle: const TextStyle(color: Colors.white54),

        prefixIcon: const Icon(Icons.search, color: Colors.white70),

        filled: true,
        fillColor: const Color(0xFF1A1A1D),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
