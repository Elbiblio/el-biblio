import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_lock_repository.dart';
import '../data/app_usage_service.dart';
import '../domain/models/app_lock_config.dart';
import '../domain/models/app_usage_record.dart';
import 'app_lock_state.dart';

class AppLockNotifier extends StateNotifier<AppLockState> {
  AppLockNotifier(this._repository, this._usageService) : super(AppLockState.initial()) {
    loadAll();
  }

  final AppLockRepository _repository;
  final AppUsageService _usageService;

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true);
    try {
      final configs = _repository.getConfigs();
      final weeklyStats = _repository.getWeeklyStats();
      final extensions = _repository.getExtensionsUsedToday();
      final streak = _repository.getGoalStreakDays();

      // On Android, try to fetch real usage stats first
      List<AppUsageRecord> todayUsage;
      if (Platform.isAndroid) {
        final realUsage = await _usageService.getTodayUsage(configs);
        if (realUsage.isNotEmpty && realUsage.any((r) => r.usedMinutesToday > 0)) {
          todayUsage = realUsage;
        } else {
          // Fall back to Hive-based manual tracking
          todayUsage = _repository.getTodayUsage();
        }
      } else {
        // Non-Android: use Hive-based manual tracking
        todayUsage = _repository.getTodayUsage();
      }

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
    List<AppUsageRecord> todayUsage;
    if (Platform.isAndroid) {
      final realUsage = await _usageService.getTodayUsage(state.configs);
      if (realUsage.isNotEmpty && realUsage.any((r) => r.usedMinutesToday > 0)) {
        todayUsage = realUsage;
      } else {
        todayUsage = _repository.getTodayUsage();
      }
    } else {
      todayUsage = _repository.getTodayUsage();
    }
    final syncedUsage = _syncUsageWithConfigs(todayUsage, state.configs);
    state = state.copyWith(todayUsage: syncedUsage);
  }

  /// Check if a specific app has exceeded its daily limit.
  bool isAppLimitReached(String packageName) {
    final record = state.todayUsage.where((r) => r.packageName == packageName).firstOrNull;
    return record != null && record.isLimitReached;
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
