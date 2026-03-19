import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/settings_storage.dart';
import 'app_theme.dart';
import 'app_theme_mode.dart';
import 'app_theme_time.dart';

class ThemeNotifier extends StateNotifier<AppTheme> {
  ThemeNotifier(this._settingsStorage)
      : super(
          const AppTheme(
            mode: AppThemeMode.adaptive,
            brightness: Brightness.light,
            timeOfDay: AppThemeTimeOfDay.afternoon,
          ),
        ) {
    _hydrate();
    _timer = Timer.periodic(const Duration(minutes: 5), (_) {
      _refreshResolvedTimeOfDay();
    });
  }

  final SettingsStorage _settingsStorage;
  Timer? _timer;

  AppThemeTimeOfDay _resolveTimeOfDay(AppThemeMode mode) {
    if (mode == AppThemeMode.afternoon) {
      return AppThemeTimeOfDay.afternoon;
    }
    return AppThemeTimeOfDayResolver.fromDateTime(DateTime.now());
  }

  void _refreshResolvedTimeOfDay() {
    final nextTime = _resolveTimeOfDay(state.mode);
    if (nextTime == state.timeOfDay) {
      return;
    }
    state = state.copyWith(timeOfDay: nextTime);
  }

  Future<void> _hydrate() async {
    final settings = await _settingsStorage.load();
    state = state.copyWith(
      mode: settings.themeMode,
      brightness: settings.brightness,
      timeOfDay: _resolveTimeOfDay(settings.themeMode),
    );
  }

  Future<void> setMode(AppThemeMode mode) async {
    state = state.copyWith(
      mode: mode,
      timeOfDay: _resolveTimeOfDay(mode),
    );
    await _settingsStorage.updateTheme(
      mode: mode,
      brightness: state.brightness,
    );
  }

  Future<void> setBrightness(Brightness brightness) async {
    state = state.copyWith(brightness: brightness);
    await _settingsStorage.updateTheme(
      mode: state.mode,
      brightness: brightness,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
