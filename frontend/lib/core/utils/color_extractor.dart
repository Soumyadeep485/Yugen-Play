import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

class ColorExtractor {
  ColorExtractor._();

  static Future<Color?> getDominantColor(String imageUrl) async {
    try {
      final PaletteGenerator generator =
          await PaletteGenerator.fromImageProvider(
            NetworkImage(imageUrl),
            size: const Size(100, 150),
            maximumColorCount: 10,
          );

      return generator.vibrantColor?.color ?? generator.dominantColor?.color;
    } catch (e) {
      debugPrint("Color extraction failed: $e");
      return null;
    }
  }
}