import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/settings_storage.dart';
import 'app_theme.dart';
import 'app_theme_variant.dart';

class ThemeNotifier extends StateNotifier<AppTheme> {
  ThemeNotifier(this._settingsStorage)
      : super(
          const AppTheme(
            variant: AppThemeVariant.sage,
            brightness: Brightness.light,
          ),
        ) {
    _hydrate();
  }

  final SettingsStorage _settingsStorage;

  Future<void> _hydrate() async {
    final settings = await _settingsStorage.load();
    state = state.copyWith(
      variant: settings.themeVariant,
      brightness: settings.brightness,
    );
  }

  Future<void> setVariant(AppThemeVariant variant) async {
    state = state.copyWith(variant: variant);
    await _settingsStorage.updateTheme(
      variant: variant,
      brightness: state.brightness,
    );
  }

  Future<void> setBrightness(Brightness brightness) async {
    state = state.copyWith(brightness: brightness);
    await _settingsStorage.updateTheme(
      variant: state.variant,
      brightness: brightness,
    );
  }
}
