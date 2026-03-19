import 'package:flutter/material.dart';

extension BuildContextX on BuildContext {
  double responsiveFont(double baseSize) {
    final width = MediaQuery.sizeOf(this).width;
    final scale = (width / 390).clamp(0.9, 1.15);
    return baseSize * scale;
  }
}
