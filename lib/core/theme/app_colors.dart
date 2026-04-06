import 'package:flutter/material.dart';

import 'app_theme_time.dart';

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
    this.pillarIdentity,
    this.pillarCommitment,
    this.pillarDistraction,
    this.pillarGrowth,
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
  final Color? pillarIdentity;
  final Color? pillarCommitment;
  final Color? pillarDistraction;
  final Color? pillarGrowth;

  Color get identityColor => pillarIdentity ?? primary;
  Color get commitmentColor => pillarCommitment ?? success;
  Color get distractionColor => pillarDistraction ?? primaryLight;
  Color get growthColor => pillarGrowth ?? const Color(0xFFFF9800);
}

class AppColors {
  const AppColors._();

  static const AppColorPalette _morningLight = AppColorPalette(
    primary: Color(0xFF4B82C3),
    primaryLight: Color(0xFF74A3DA),
    primaryDark: Color(0xFF335E96),
    background: Color(0xFFF4F6F9),
    surface: Color(0xFFEDF2F8),
    paper: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1D2A3A),
    textSecondary: Color(0xFF5F6F84),
    textTertiary: Color(0xFF8B9BAF),
    border: Color(0xFFD8E2EE),
    success: Color(0xFF4C8864),
    error: Color(0xFFB55F68),
    pillarIdentity: Color(0xFF7B68EE),
    pillarCommitment: Color(0xFF4CAF50),
    pillarDistraction: Color(0xFF2196F3),
    pillarGrowth: Color(0xFFFF9800),
  );

  static const AppColorPalette _morningDark = AppColorPalette(
    primary: Color(0xFF7CAEE3),
    primaryLight: Color(0xFF9DC4EB),
    primaryDark: Color(0xFF5D88BE),
    background: Color(0xFF151B24),
    surface: Color(0xFF1F2833),
    paper: Color(0xFF253242),
    textPrimary: Color(0xFFE6EDF7),
    textSecondary: Color(0xFFB7C5D7),
    textTertiary: Color(0xFF92A4B8),
    border: Color(0xFF344558),
    success: Color(0xFF6FBB8C),
    error: Color(0xFFE08A94),
    pillarIdentity: Color(0xFF9B8BF2),
    pillarCommitment: Color(0xFF6FCF76),
    pillarDistraction: Color(0xFF4FB3F5),
    pillarGrowth: Color(0xFFFFB74D),
  );

  static const AppColorPalette _afternoonLight = AppColorPalette(
    primary: Color(0xFF5A8E67),
    primaryLight: Color(0xFF81AE8A),
    primaryDark: Color(0xFF416B4C),
    background: Color(0xFFF5F6F4),
    surface: Color(0xFFEDF2EC),
    paper: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF24342A),
    textSecondary: Color(0xFF54675A),
    textTertiary: Color(0xFF819488),
    border: Color(0xFFDCE5DD),
    success: Color(0xFF4B8E62),
    error: Color(0xFFB56662),
    pillarIdentity: Color(0xFF7B68EE),
    pillarCommitment: Color(0xFF4CAF50),
    pillarDistraction: Color(0xFF2196F3),
    pillarGrowth: Color(0xFFFF9800),
  );

  static const AppColorPalette _afternoonDark = AppColorPalette(
    primary: Color(0xFF93BA9D),
    primaryLight: Color(0xFFAFCEB7),
    primaryDark: Color(0xFF6C9274),
    background: Color(0xFF151B17),
    surface: Color(0xFF202923),
    paper: Color(0xFF273229),
    textPrimary: Color(0xFFE6EFE6),
    textSecondary: Color(0xFFBDCCBE),
    textTertiary: Color(0xFF99AA9A),
    border: Color(0xFF374539),
    success: Color(0xFF74BC8E),
    error: Color(0xFFE1918D),
    pillarIdentity: Color(0xFF9B8BF2),
    pillarCommitment: Color(0xFF6FCF76),
    pillarDistraction: Color(0xFF4FB3F5),
    pillarGrowth: Color(0xFFFFB74D),
  );

  static const AppColorPalette _eveningLight = AppColorPalette(
    primary: Color(0xFFA97A46),
    primaryLight: Color(0xFFC49762),
    primaryDark: Color(0xFF865B32),
    background: Color(0xFFF7F2E8),
    surface: Color(0xFFF1E8DA),
    paper: Color(0xFFFBF5EA),
    textPrimary: Color(0xFF3B2A18),
    textSecondary: Color(0xFF70583D),
    textTertiary: Color(0xFF987E5F),
    border: Color(0xFFE3D4BD),
    success: Color(0xFF5A8A66),
    error: Color(0xFFB86461),
    pillarIdentity: Color(0xFF7B68EE),
    pillarCommitment: Color(0xFF4CAF50),
    pillarDistraction: Color(0xFF2196F3),
    pillarGrowth: Color(0xFFFF9800),
  );

  static const AppColorPalette _eveningDark = AppColorPalette(
    primary: Color(0xFFCCAA7A),
    primaryLight: Color(0xFFDEBF94),
    primaryDark: Color(0xFFA47D50),
    background: Color(0xFF1E1711),
    surface: Color(0xFF2A2118),
    paper: Color(0xFF34291E),
    textPrimary: Color(0xFFF3E8DA),
    textSecondary: Color(0xFFD7C6B0),
    textTertiary: Color(0xFFB79F84),
    border: Color(0xFF4B3B2B),
    success: Color(0xFF7BB58B),
    error: Color(0xFFE5938D),
    pillarIdentity: Color(0xFF9B8BF2),
    pillarCommitment: Color(0xFF6FCF76),
    pillarDistraction: Color(0xFF4FB3F5),
    pillarGrowth: Color(0xFFFFB74D),
  );

  static AppColorPalette paletteFor(
    AppThemeTimeOfDay timeOfDay, {
    Brightness brightness = Brightness.light,
  }) {
    return switch ((timeOfDay, brightness)) {
      (AppThemeTimeOfDay.morning, Brightness.light) => _morningLight,
      (AppThemeTimeOfDay.morning, Brightness.dark) => _morningDark,
      (AppThemeTimeOfDay.afternoon, Brightness.light) => _afternoonLight,
      (AppThemeTimeOfDay.afternoon, Brightness.dark) => _afternoonDark,
      (AppThemeTimeOfDay.evening, Brightness.light) => _eveningLight,
      (AppThemeTimeOfDay.evening, Brightness.dark) => _eveningDark,
    };
  }

  static List<Color> gradientFor(
    AppThemeTimeOfDay timeOfDay, {
    Brightness brightness = Brightness.light,
  }) {
    return switch ((timeOfDay, brightness)) {
      (AppThemeTimeOfDay.morning, Brightness.light) => const [
          Color(0xFFEAF2FF),
          Color(0xFFF5F9FF),
        ],
      (AppThemeTimeOfDay.afternoon, Brightness.light) => const [
          Color(0xFFE9F2E5),
          Color(0xFFF5F8F1),
        ],
      (AppThemeTimeOfDay.evening, Brightness.light) => const [
          Color(0xFFF6E9D3),
          Color(0xFFFCF4E5),
        ],
      (AppThemeTimeOfDay.morning, Brightness.dark) => const [
          Color(0xFF162230),
          Color(0xFF111B26),
        ],
      (AppThemeTimeOfDay.afternoon, Brightness.dark) => const [
          Color(0xFF17241A),
          Color(0xFF121D14),
        ],
      (AppThemeTimeOfDay.evening, Brightness.dark) => const [
          Color(0xFF2B2015),
          Color(0xFF20170F),
        ],
    };
  }
}
