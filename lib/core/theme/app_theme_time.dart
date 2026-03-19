enum AppThemeTimeOfDay { morning, afternoon, evening }

extension AppThemeTimeOfDayResolver on AppThemeTimeOfDay {
  static AppThemeTimeOfDay fromDateTime(DateTime dateTime) {
    final hour = dateTime.hour;
    if (hour >= 5 && hour < 12) {
      return AppThemeTimeOfDay.morning;
    }
    if (hour >= 12 && hour < 18) {
      return AppThemeTimeOfDay.afternoon;
    }
    return AppThemeTimeOfDay.evening;
  }
}
