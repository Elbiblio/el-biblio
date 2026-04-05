import 'dart:io';

import 'package:app_usage/app_usage.dart';
import 'package:logger/logger.dart';

import '../domain/models/app_lock_config.dart';
import '../domain/models/app_usage_record.dart';

/// Service that fetches real Android app usage stats via the app_usage plugin.
/// Returns empty results on non-Android platforms.
class AppUsageService {
  AppUsageService(this._logger);

  final Logger _logger;

  /// Check if usage stats permission is granted by attempting a small query.
  /// Returns false on non-Android platforms.
  Future<bool> hasPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      final now = DateTime.now();
      // Try a short window - if permission is denied this will throw
      await AppUsage().getAppUsage(
        now.subtract(const Duration(hours: 1)),
        now,
      );
      return true;
    } catch (e) {
      _logger.d('Usage stats permission check failed: $e');
      return false;
    }
  }

  /// Get today's app usage for the monitored apps in [configs].
  /// Returns empty list on non-Android platforms or if permission is denied.
  Future<List<AppUsageRecord>> getTodayUsage(List<AppLockConfig> configs) async {
    if (!Platform.isAndroid) return [];

    final enabledConfigs = configs.where((c) => c.isEnabled).toList();
    if (enabledConfigs.isEmpty) return [];

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final infos = await AppUsage().getAppUsage(startOfDay, now);

      // Build a lookup map by package name for fast matching
      final usageMap = <String, Duration>{};
      for (final info in infos) {
        usageMap[info.packageName] = info.usage;
      }

      final records = <AppUsageRecord>[];
      for (final config in enabledConfigs) {
        final usage = usageMap[config.packageName] ?? Duration.zero;
        records.add(AppUsageRecord(
          packageName: config.packageName,
          appName: config.appName,
          usedMinutesToday: usage.inMinutes,
          dailyLimitMinutes: config.dailyLimitMinutes,
          date: now,
        ));
      }

      return records;
    } catch (e) {
      _logger.w('Failed to get app usage stats: $e');
      // Return empty records with 0 usage so the UI still renders
      return enabledConfigs.map((config) => AppUsageRecord(
        packageName: config.packageName,
        appName: config.appName,
        usedMinutesToday: 0,
        dailyLimitMinutes: config.dailyLimitMinutes,
        date: DateTime.now(),
      )).toList();
    }
  }
}
