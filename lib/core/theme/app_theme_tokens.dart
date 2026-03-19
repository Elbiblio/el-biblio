import 'package:flutter/material.dart';

import 'app_colors.dart';

@immutable
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  const AppThemeTokens({
    required this.palette,
    required this.pageGradient,
  });

  final AppColorPalette palette;
  final List<Color> pageGradient;

  @override
  AppThemeTokens copyWith({
    AppColorPalette? palette,
    List<Color>? pageGradient,
  }) {
    return AppThemeTokens(
      palette: palette ?? this.palette,
      pageGradient: pageGradient ?? this.pageGradient,
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
        );
  }
}
