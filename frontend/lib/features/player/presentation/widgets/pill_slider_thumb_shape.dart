import 'package:flutter/material.dart';

class PillSliderThumbShape extends SliderComponentShape {
  final double thumbWidth;
  final double thumbHeight;

  const PillSliderThumbShape({
    this.thumbWidth = 6.0,
    this.thumbHeight = 22.0,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(thumbWidth, thumbHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    final Paint paint = Paint()..color = sliderTheme.thumbColor ?? Colors.white;

    final RRect thumbRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: thumbWidth, height: thumbHeight),
      Radius.circular(thumbWidth / 2),
    );

    canvas.drawRRect(thumbRect, paint);
  }
}