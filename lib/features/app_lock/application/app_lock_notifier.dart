import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_lock_repository.dart';
import '../domain/models/app_lock_config.dart';
import '../domain/models/app_usage_record.dart';
import 'app_lock_state.dart';

class AppLockNotifier extends StateNotifier<AppLockState> {
  AppLockNotifier(this._repository) : super(AppLockState.initial()) {
    loadAll();
  }

  final AppLockRepository _repository;

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true);
    try {
      final configs = _repository.getConfigs();
      final todayUsage = _repository.getTodayUsage();
      final weeklyStats = _repository.getWeeklyStats();
      final extensions = _repository.getExtensionsUsedToday();
      final streak = _repository.getGoalStreakDays();

      // Sync today usage with current configs to ensure limits are up to date
      final syncedUsage = _syncUsageWithConfigs(todayUsage, configs);

      state = state.copyWith(
        configs: configs,
        todayUsage: syncedUsage,
        weeklyStats: weeklyStats,
        extensionsUsedToday: extensions,
        goalStreakDays: streak,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load app lock data.',
      );
    }
  }

  Future<void> addConfig(AppLockConfig config) async {
    await _repository.saveConfig(config);
    await loadAll();
  }

  Future<void> updateConfig(AppLockConfig config) async {
    await _repository.saveConfig(config);
    await loadAll();
  }

  Future<void> deleteConfig(String id) async {
    await _repository.deleteConfig(id);
    await loadAll();
  }

  Future<void> toggleConfig(String id) async {
    final config = state.configs.firstWhere((c) => c.id == id);
    await _repository.saveConfig(config.copyWith(isEnabled: !config.isEnabled));
    await loadAll();
  }

  Future<void> refreshUsage() async {
    final todayUsage = _repository.getTodayUsage();
    final syncedUsage = _syncUsageWithConfigs(todayUsage, state.configs);
    state = state.copyWith(todayUsage: syncedUsage);
  }

  Future<void> simulateUsage(String packageName, int minutes) async {
    await _repository.recordUsage(packageName, minutes);
    await loadAll();
  }

  Future<bool> requestExtension(String packageName) async {
    final extensions = _repository.getExtensionsUsedToday();
    if (extensions >= 3) return false;

    await _repository.incrementExtensionsUsed();

    // Add 5 minutes to the usage record's limit (effectively giving more time)
    final records = _repository.getTodayUsage();
    final index = records.indexWhere((r) => r.packageName == packageName);
    if (index >= 0) {
      records[index] = records[index].copyWith(
        dailyLimitMinutes: records[index].dailyLimitMinutes + 5,
      );
      await _repository.saveTodayUsage(records);
    }

    await loadAll();
    return true;
  }

  List<AppUsageRecord> _syncUsageWithConfigs(
    List<AppUsageRecord> usage,
    List<AppLockConfig> configs,
  ) {
    final synced = <AppUsageRecord>[];
    for (final config in configs.where((c) => c.isEnabled)) {
      final existing = usage.firstWhere(
        (u) => u.packageName == config.packageName,
        orElse: () => AppUsageRecord(
          packageName: config.packageName,
          appName: config.appName,
          usedMinutesToday: 0,
          dailyLimitMinutes: config.dailyLimitMinutes,
          date: DateTime.now(),
        ),
      );
      synced.add(existing.copyWith(
        appName: config.appName,
        dailyLimitMinutes: config.dailyLimitMinutes,
      ));
    }
    return synced;
  }
}
