import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import 'app_colors.dart';

@immutable
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  const AppThemeTokens({
    required this.palette,
    required this.pageGradient,
    required this.radiusSmall,
    required this.radiusMedium,
    required this.radiusLarge,
    required this.spacingXs,
    required this.spacingSm,
    required this.spacingMd,
    required this.spacingLg,
  });

  final AppColorPalette palette;
  final List<Color> pageGradient;

  // Border radius tokens
  final double radiusSmall;
  final double radiusMedium;
  final double radiusLarge;

  // Spacing tokens
  final double spacingXs;
  final double spacingSm;
  final double spacingMd;
  final double spacingLg;

  @override
  AppThemeTokens copyWith({
    AppColorPalette? palette,
    List<Color>? pageGradient,
    double? radiusSmall,
    double? radiusMedium,
    double? radiusLarge,
    double? spacingXs,
    double? spacingSm,
    double? spacingMd,
    double? spacingLg,
  }) {
    return AppThemeTokens(
      palette: palette ?? this.palette,
      pageGradient: pageGradient ?? this.pageGradient,
      radiusSmall: radiusSmall ?? this.radiusSmall,
      radiusMedium: radiusMedium ?? this.radiusMedium,
      radiusLarge: radiusLarge ?? this.radiusLarge,
      spacingXs: spacingXs ?? this.spacingXs,
      spacingSm: spacingSm ?? this.spacingSm,
      spacingMd: spacingMd ?? this.spacingMd,
      spacingLg: spacingLg ?? this.spacingLg,
    );
  }

  @override
  AppThemeTokens lerp(ThemeExtension<AppThemeTokens>? other, double t) {
    if (other is! AppThemeTokens) {
      return this;
    }

    return AppThemeTokens(
      palette: t < 0.5 ? palette : other.palette,
      pageGradient: t < 0.5 ? pageGradient : other.pageGradient,
      radiusSmall: ui.lerpDouble(radiusSmall, other.radiusSmall, t) ?? radiusSmall,
      radiusMedium: ui.lerpDouble(radiusMedium, other.radiusMedium, t) ?? radiusMedium,
      radiusLarge: ui.lerpDouble(radiusLarge, other.radiusLarge, t) ?? radiusLarge,
      spacingXs: ui.lerpDouble(spacingXs, other.spacingXs, t) ?? spacingXs,
      spacingSm: ui.lerpDouble(spacingSm, other.spacingSm, t) ?? spacingSm,
      spacingMd: ui.lerpDouble(spacingMd, other.spacingMd, t) ?? spacingMd,
      spacingLg: ui.lerpDouble(spacingLg, other.spacingLg, t) ?? spacingLg,
    );
  }
}

extension AppThemeTokensX on ThemeData {
  AppThemeTokens get tokens {
    return extension<AppThemeTokens>() ??
        const AppThemeTokens(
          palette: AppColorPalette(
            primary: Color(0xFF5E9268),
            primaryLight: Color(0xFF7BAA83),
            primaryDark: Color(0xFF46724F),
            background: Color(0xFFF7FCF6),
            surface: Color(0xFFEDF6EC),
            paper: Color(0xFFFFFFFF),
            textPrimary: Color(0xFF223428),
            textSecondary: Color(0xFF4F6756),
            textTertiary: Color(0xFF7C9382),
            border: Color(0xFFDCE9DE),
            success: Color(0xFF4B8E62),
            error: Color(0xFFB56662),
          ),
          pageGradient: [
            Color(0xFFEAF6E8),
            Color(0xFFF6FCF4),
          ],
          radiusSmall: 12,
          radiusMedium: 16,
          radiusLarge: 20,
          spacingXs: 8,
          spacingSm: 12,
          spacingMd: 16,
          spacingLg: 24,
        );
  }
}
