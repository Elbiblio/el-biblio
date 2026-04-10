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

      // On Android, try to fetch real usage stats first.
      // getTodayUsage() returns [] only when permission is denied or the query
      // fails — real stats with all-zero usage (e.g. early morning) are
      // returned as a non-empty list and must be trusted as-is.
      List<AppUsageRecord> todayUsage;
      if (Platform.isAndroid) {
        final realUsage = await _usageService.getTodayUsage(configs);
        todayUsage = realUsage.isNotEmpty
            ? realUsage
            : _repository.getTodayUsage(); // fall back to manual Hive tracking
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
      todayUsage = realUsage.isNotEmpty
          ? realUsage
          : _repository.getTodayUsage();
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
    // Store the extra 5 minutes against this package separately so the
    // extension survives real-stats refreshes (which always use config limits).
    await _repository.addPackageExtensionMinutes(packageName, 5);

    await loadAll();
    return true;
  }

  List<AppUsageRecord> _syncUsageWithConfigs(
    List<AppUsageRecord> usage,
    List<AppLockConfig> configs,
  ) {
    // Per-package extension minutes are stored separately so they survive
    // real-stats refreshes (where AppUsage returns fresh records with the
    // original config limit).
    final extensions = _repository.getPackageExtensionMinutesToday();

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
      final extraMinutes = extensions[config.packageName] ?? 0;
      synced.add(existing.copyWith(
        appName: config.appName,
        dailyLimitMinutes: config.dailyLimitMinutes + extraMinutes,
      ));
    }
    return synced;
  }
}
