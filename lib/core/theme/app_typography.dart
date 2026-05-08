import 'package:flutter/material.dart';

class AppTypography {
  const AppTypography._();

  static TextTheme textTheme(double scaleFactor) {
    final clampedScale = scaleFactor.clamp(0.9, 1.3);

    TextStyle ui(
      double size,
      double height,
      FontWeight weight,
      double letterSpacing,
    ) {
      return TextStyle(
        fontSize: size * clampedScale,
        height: height,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        fontFamily: 'Inter',
      );
    }

    TextStyle ceremonial(
      double size,
      double height,
      FontWeight weight,
      double letterSpacing,
    ) {
      return TextStyle(
        fontSize: size * clampedScale,
        height: height,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        fontFamily: 'InstrumentSerif',
      );
    }

    return TextTheme(
      displayLarge: ceremonial(36, 1.2, FontWeight.w700, 0),
      displayMedium: ceremonial(30, 1.25, FontWeight.w600, 0),
      displaySmall: ceremonial(24, 1.3, FontWeight.w600, 0),
      headlineLarge: ceremonial(24, 1.33, FontWeight.w600, 0),
      headlineMedium: ceremonial(20, 1.4, FontWeight.w600, 0),
      headlineSmall: ceremonial(18, 1.33, FontWeight.w500, 0),
      titleLarge: ui(18, 1.4, FontWeight.w700, 0),
      titleMedium: ui(16, 1.4, FontWeight.w600, 0),
      titleSmall: ui(14, 1.4, FontWeight.w600, 0),
      bodyLarge: ui(18, 1.55, FontWeight.w400, 0),
      bodyMedium: ui(16, 1.5, FontWeight.w400, 0),
      bodySmall: ui(14, 1.45, FontWeight.w400, 0),
      labelLarge: ui(16, 1.4, FontWeight.w700, 0),
      labelMedium: ui(14, 1.35, FontWeight.w600, 0),
      labelSmall: ui(12, 1.3, FontWeight.w600, 0),
    );
  }
}
