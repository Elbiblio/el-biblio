enum AppThemeVariant { sage, wooden, ocean }

extension AppThemeVariantX on AppThemeVariant {
  String get displayName => switch (this) {
        AppThemeVariant.sage => 'Sage Garden',
        AppThemeVariant.wooden => 'Classic Parchment',
        AppThemeVariant.ocean => 'Ocean Breeze',
      };

  static AppThemeVariant fromStorage(String? value) {
    for (final variant in AppThemeVariant.values) {
      if (variant.name == value) {
        return variant;
      }
    }
    return AppThemeVariant.sage;
  }
}
