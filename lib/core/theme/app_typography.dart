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
        fontFamily: 'Roboto',
      );
    }

    TextStyle verse(
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
        fontFamily: 'serif',
      );
    }

    return TextTheme(
      displayLarge: ui(36, 1.2, FontWeight.w700, -0.5),
      displayMedium: ui(30, 1.25, FontWeight.w600, -0.25),
      displaySmall: ui(24, 1.3, FontWeight.w600, 0),
      headlineLarge: ui(24, 1.33, FontWeight.w600, 0),
      headlineMedium: ui(20, 1.4, FontWeight.w600, 0.15),
      headlineSmall: ui(18, 1.33, FontWeight.w500, 0.15),
      titleLarge: ui(18, 1.4, FontWeight.w600, 0.2),
      titleMedium: ui(16, 1.4, FontWeight.w500, 0.25),
      titleSmall: ui(14, 1.4, FontWeight.w500, 0.25),
      bodyLarge: verse(18, 1.6, FontWeight.w400, 0.3),
      bodyMedium: verse(16, 1.55, FontWeight.w400, 0.2),
      bodySmall: ui(14, 1.45, FontWeight.w400, 0.3),
      labelLarge: ui(16, 1.4, FontWeight.w600, 0.4),
      labelMedium: ui(14, 1.35, FontWeight.w500, 0.25),
      labelSmall: ui(12, 1.3, FontWeight.w500, 0.4),
    );
  }
}
