import 'package:flutter/material.dart';

import 'app_theme_variant.dart';

class AppColorPalette {
  const AppColorPalette({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.background,
    required this.surface,
    required this.paper,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.success,
    required this.error,
  });

  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color background;
  final Color surface;
  final Color paper;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color border;
  final Color success;
  final Color error;
}

class AppColors {
  const AppColors._();

  // Sage Garden - Light (primary request)
  static const sagePrimary = Color(0xFF638B6C);
  static const sagePrimaryLight = Color(0xFF85A889);
  static const sagePrimaryDark = Color(0xFF4A6B51);
  static const sageBackground = Color(0xFFFDFAF6);
  static const sageSurface = Color(0xFFF5F7F3);
  static const sagePaper = Color(0xFFF2F5E9);

  // Typography
  static const textPrimary = Color(0xFF2C3830);
  static const textSecondary = Color(0xFF5A6157);
  static const textTertiary = Color(0xFF7D857A);

  static const AppColorPalette _sageLight = AppColorPalette(
    primary: sagePrimary,
    primaryLight: sagePrimaryLight,
    primaryDark: sagePrimaryDark,
    background: sageBackground,
    surface: sageSurface,
    paper: sagePaper,
    textPrimary: textPrimary,
    textSecondary: textSecondary,
    textTertiary: textTertiary,
    border: Color(0xFFE2E5E0),
    success: Color(0xFF5B8B6C),
    error: Color(0xFFB66B68),
  );

  static const AppColorPalette _sageDark = AppColorPalette(
    primary: Color(0xFF85A889),
    primaryLight: Color(0xFFA6C2A9),
    primaryDark: Color(0xFF4A6B51),
    background: Color(0xFF1A1C19),
    surface: Color(0xFF2A2E28),
    paper: Color(0xFF1E2A1E),
    textPrimary: Color(0xFFE6E9E4),
    textSecondary: Color(0xFFC4C9C1),
    textTertiary: Color(0xFFA0A59D),
    border: Color(0xFF4A4E48),
    success: Color(0xFF7BAF8C),
    error: Color(0xFFE8908D),
  );

  static const AppColorPalette _woodenLight = AppColorPalette(
    primary: Color(0xFF8B5E3C),
    primaryLight: Color(0xFFA67C52),
    primaryDark: Color(0xFF6B4423),
    background: Color(0xFFFDF8F3),
    surface: Color(0xFFF5EDE4),
    paper: Color(0xFFF5EDE4),
    textPrimary: Color(0xFF2C1810),
    textSecondary: Color(0xFF5A4A3E),
    textTertiary: Color(0xFF7D6B5E),
    border: Color(0xFFE8D5C4),
    success: Color(0xFF4A7B58),
    error: Color(0xFFA94442),
  );

  static const AppColorPalette _woodenDark = AppColorPalette(
    primary: Color(0xFFA67C52),
    primaryLight: Color(0xFFC19A70),
    primaryDark: Color(0xFF6B4423),
    background: Color(0xFF1A1410),
    surface: Color(0xFF2A2420),
    paper: Color(0xFF2A241E),
    textPrimary: Color(0xFFF0E6DF),
    textSecondary: Color(0xFFD4C9C0),
    textTertiary: Color(0xFFB0A59C),
    border: Color(0xFF4A3E34),
    success: Color(0xFF7BAF8C),
    error: Color(0xFFE8908D),
  );

  static const AppColorPalette _oceanLight = AppColorPalette(
    primary: Color(0xFF4A6FA5),
    primaryLight: Color(0xFF6B8BB8),
    primaryDark: Color(0xFF385582),
    background: Color(0xFFF8FBFF),
    surface: Color(0xFFF0F5FA),
    paper: Color(0xFFF0F5F9),
    textPrimary: Color(0xFF2C3542),
    textSecondary: Color(0xFF5A6370),
    textTertiary: Color(0xFF7D8694),
    border: Color(0xFFE2E8F0),
    success: Color(0xFF4B957A),
    error: Color(0xFFB86268),
  );

  static const AppColorPalette _oceanDark = AppColorPalette(
    primary: Color(0xFF6B8BB8),
    primaryLight: Color(0xFF8CA5CA),
    primaryDark: Color(0xFF385582),
    background: Color(0xFF1A1E24),
    surface: Color(0xFF2A3038),
    paper: Color(0xFF1A2833),
    textPrimary: Color(0xFFE6ECF2),
    textSecondary: Color(0xFFC4CCD6),
    textTertiary: Color(0xFFA0AAB4),
    border: Color(0xFF4A5260),
    success: Color(0xFF7BAF8C),
    error: Color(0xFFE8908D),
  );

  static AppColorPalette paletteFor(
    AppThemeVariant variant, {
    Brightness brightness = Brightness.light,
  }) {
    return switch ((variant, brightness)) {
      (AppThemeVariant.sage, Brightness.light) => _sageLight,
      (AppThemeVariant.sage, Brightness.dark) => _sageDark,
      (AppThemeVariant.wooden, Brightness.light) => _woodenLight,
      (AppThemeVariant.wooden, Brightness.dark) => _woodenDark,
      (AppThemeVariant.ocean, Brightness.light) => _oceanLight,
      (AppThemeVariant.ocean, Brightness.dark) => _oceanDark,
    };
  }
}
