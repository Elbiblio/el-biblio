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
        fontFamily: 'NotoSerif',
      );
    }

    return TextTheme(
      displayLarge: ceremonial(36, 1.2, FontWeight.w700, -0.5),
      displayMedium: ceremonial(30, 1.25, FontWeight.w600, -0.25),
      displaySmall: ceremonial(24, 1.3, FontWeight.w600, 0),
      headlineLarge: ceremonial(24, 1.33, FontWeight.w600, 0),
      headlineMedium: ceremonial(20, 1.4, FontWeight.w600, 0.15),
      headlineSmall: ceremonial(18, 1.33, FontWeight.w500, 0.15),
      titleLarge: ceremonial(18, 1.4, FontWeight.w600, 0.2),
      titleMedium: ceremonial(16, 1.4, FontWeight.w500, 0.25),
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
