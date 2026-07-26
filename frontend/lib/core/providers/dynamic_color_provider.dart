import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/color_extractor.dart';

final dynamicColorProvider = FutureProvider.family<Color?, String>((
  ref,
  imageUrl,
) async {
  return await ColorExtractor.getDominantColor(imageUrl);
});