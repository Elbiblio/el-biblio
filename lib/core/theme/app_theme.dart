import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_theme_mode.dart';
import 'app_theme_time.dart';
import 'app_theme_tokens.dart';
import 'app_typography.dart';

class AppTheme {
  const AppTheme({
    required this.mode,
    required this.brightness,
    required this.timeOfDay,
  });

  final AppThemeMode mode;
  final Brightness brightness;
  final AppThemeTimeOfDay timeOfDay;

  AppTheme copyWith({
    AppThemeMode? mode,
    Brightness? brightness,
    AppThemeTimeOfDay? timeOfDay,
  }) {
    return AppTheme(
      mode: mode ?? this.mode,
      brightness: brightness ?? this.brightness,
      timeOfDay: timeOfDay ?? this.timeOfDay,
    );
  }
}

class AppThemeFactory {
  const AppThemeFactory._();

  static ThemeData build(
    AppTheme appTheme, {
    required double textScaleFactor,
  }) {
    final palette = AppColors.paletteFor(
      appTheme.timeOfDay,
      brightness: appTheme.brightness,
    );
    final pageGradient = AppColors.gradientFor(
      appTheme.timeOfDay,
      brightness: appTheme.brightness,
    );

    final colorScheme = ColorScheme(
      brightness: appTheme.brightness,
      primary: palette.primary,
      onPrimary: Colors.white,
      secondary: palette.primaryLight,
      onSecondary: Colors.white,
      error: palette.error,
      onError: Colors.white,
      surface: palette.surface,
      onSurface: palette.textPrimary,
      tertiary: palette.primaryDark,
      onTertiary: Colors.white,
    );

    final textTheme = AppTypography.textTheme(textScaleFactor).apply(
      bodyColor: palette.textPrimary,
      displayColor: palette.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: appTheme.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,
      cardColor: palette.paper,
      dividerColor: palette.border,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall,
      ),
      cardTheme: CardThemeData(
        color: palette.paper,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: palette.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.primary, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: Colors.white,
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: palette.primary),
          foregroundColor: palette.primary,
          minimumSize: const Size(0, 52),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: palette.primary,
        thumbColor: palette.primary,
        inactiveTrackColor: palette.primaryLight.withValues(alpha: 0.24),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.surface,
        selectedColor: palette.primary.withValues(alpha: 0.16),
        labelStyle: textTheme.labelMedium ?? const TextStyle(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: palette.border),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      extensions: [
        AppThemeTokens(
          palette: palette,
          pageGradient: pageGradient,
        ),
      ],
    );
  }
}
