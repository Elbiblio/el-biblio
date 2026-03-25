import '../domain/models/app_lock_config.dart';
import '../domain/models/app_usage_record.dart';

class AppLockState {
  final List<AppLockConfig> configs;
  final List<AppUsageRecord> todayUsage;
  final Map<String, List<AppUsageRecord>> weeklyStats;
  final bool isLoading;
  final String? error;
  final int extensionsUsedToday;
  final int goalStreakDays;

  const AppLockState({
    this.configs = const [],
    this.todayUsage = const [],
    this.weeklyStats = const {},
    this.isLoading = false,
    this.error,
    this.extensionsUsedToday = 0,
    this.goalStreakDays = 0,
  });

  factory AppLockState.initial() {
    return const AppLockState(isLoading: true);
  }

  int get totalMonitoredApps => configs.where((c) => c.isEnabled).length;

  int get totalUsedMinutesToday =>
      todayUsage.fold(0, (sum, r) => sum + r.usedMinutesToday);

  int get totalLimitMinutesToday =>
      todayUsage.fold(0, (sum, r) => sum + r.dailyLimitMinutes);

  int get totalTimeSavedMinutes {
    // Estimate time saved as total limit minus actual usage for apps under limit
    int saved = 0;
    for (final record in todayUsage) {
      if (!record.isLimitReached) {
        saved += record.remainingMinutes;
      }
    }
    return saved;
  }

  int get appsAtLimit => todayUsage.where((r) => r.isLimitReached).length;

  int get appsApproachingLimit =>
      todayUsage.where((r) => r.usagePercentage >= 0.8 && !r.isLimitReached).length;

  bool get isDoingWell =>
      todayUsage.isNotEmpty && todayUsage.every((r) => r.usagePercentage < 0.8);

  AppLockState copyWith({
    List<AppLockConfig>? configs,
    List<AppUsageRecord>? todayUsage,
    Map<String, List<AppUsageRecord>>? weeklyStats,
    bool? isLoading,
    String? error,
    int? extensionsUsedToday,
    int? goalStreakDays,
  }) {
    return AppLockState(
      configs: configs ?? this.configs,
      todayUsage: todayUsage ?? this.todayUsage,
      weeklyStats: weeklyStats ?? this.weeklyStats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      extensionsUsedToday: extensionsUsedToday ?? this.extensionsUsedToday,
      goalStreakDays: goalStreakDays ?? this.goalStreakDays,
    );
  }
}
