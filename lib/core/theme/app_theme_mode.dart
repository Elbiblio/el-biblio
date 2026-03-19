enum AppThemeMode { adaptive, afternoon }

extension AppThemeModeX on AppThemeMode {
  String get displayName => switch (this) {
        AppThemeMode.adaptive => 'Adaptive (Morning/Afternoon/Evening)',
        AppThemeMode.afternoon => 'Afternoon All Day',
      };

  static AppThemeMode fromStorage(String? value) {
    for (final mode in AppThemeMode.values) {
      if (mode.name == value) {
        return mode;
      }
    }
    return AppThemeMode.adaptive;
  }
}
