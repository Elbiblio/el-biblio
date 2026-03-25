import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:logger/logger.dart';

import '../../../core/storage/hive_boxes.dart';
import '../domain/models/app_lock_config.dart';
import '../domain/models/app_usage_record.dart';

class AppLockRepository {
  AppLockRepository(this._logger);

  final Logger _logger;

  Box<dynamic> get _box => Hive.box<dynamic>(HiveBoxes.appLockConfigs);
  Box<dynamic> get _usageBox => Hive.box<dynamic>(HiveBoxes.appLockUsage);

  // ---------------------------------------------------------------------------
  // Configs
  // ---------------------------------------------------------------------------

  List<AppLockConfig> getConfigs() {
    try {
      final configs = <AppLockConfig>[];
      for (final key in _box.keys) {
        try {
          final raw = _box.get(key);
          if (raw is String) {
            configs.add(AppLockConfig.decode(raw));
          }
        } catch (e) {
          _logger.w('Failed to decode config for key $key: $e');
        }
      }
      return configs;
    } catch (e) {
      _logger.e('Failed to get configs: $e');
      return [];
    }
  }

  Future<void> saveConfig(AppLockConfig config) async {
    try {
      await _box.put(config.id, config.encode());
    } catch (e) {
      _logger.e('Failed to save config: $e');
    }
  }

  Future<void> deleteConfig(String id) async {
    try {
      await _box.delete(id);
    } catch (e) {
      _logger.e('Failed to delete config: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Usage Records
  // ---------------------------------------------------------------------------

  List<AppUsageRecord> getTodayUsage() {
    try {
      final todayKey = _todayKey();
      final records = <AppUsageRecord>[];
      final raw = _usageBox.get(todayKey);
      if (raw is String) {
        final list = jsonDecode(raw) as List<dynamic>;
        for (final item in list) {
          records.add(
              AppUsageRecord.fromJson(item as Map<String, dynamic>));
        }
      }
      return records;
    } catch (e) {
      _logger.e('Failed to get today usage: $e');
      return [];
    }
  }

  Future<void> recordUsage(String packageName, int minutes) async {
    try {
      final todayKey = _todayKey();
      final records = getTodayUsage();

      final existingIndex =
          records.indexWhere((r) => r.packageName == packageName);

      if (existingIndex >= 0) {
        final existing = records[existingIndex];
        records[existingIndex] = existing.copyWith(
          usedMinutesToday: existing.usedMinutesToday + minutes,
          sessions: [
            ...existing.sessions,
            UsageSession(
              startTime: DateTime.now(),
              durationMinutes: minutes,
            ),
          ],
        );
      } else {
        // Look up the config to get the app name and limit
        final configs = getConfigs();
        final config = configs.firstWhere(
          (c) => c.packageName == packageName,
          orElse: () => AppLockConfig(
            id: packageName,
            appName: packageName,
            packageName: packageName,
            dailyLimitMinutes: 60,
            category: 'other',
          ),
        );

        records.add(AppUsageRecord(
          packageName: packageName,
          appName: config.appName,
          usedMinutesToday: minutes,
          dailyLimitMinutes: config.dailyLimitMinutes,
          date: DateTime.now(),
          sessions: [
            UsageSession(
              startTime: DateTime.now(),
              durationMinutes: minutes,
            ),
          ],
        ));
      }

      final encoded = jsonEncode(records.map((r) => r.toJson()).toList());
      await _usageBox.put(todayKey, encoded);
    } catch (e) {
      _logger.e('Failed to record usage: $e');
    }
  }

  Future<void> saveTodayUsage(List<AppUsageRecord> records) async {
    try {
      final todayKey = _todayKey();
      final encoded = jsonEncode(records.map((r) => r.toJson()).toList());
      await _usageBox.put(todayKey, encoded);
    } catch (e) {
      _logger.e('Failed to save today usage: $e');
    }
  }

  Future<void> resetDailyUsage() async {
    try {
      final todayKey = _todayKey();
      await _usageBox.put(todayKey, jsonEncode([]));
    } catch (e) {
      _logger.e('Failed to reset daily usage: $e');
    }
  }

  Map<String, List<AppUsageRecord>> getWeeklyStats() {
    try {
      final stats = <String, List<AppUsageRecord>>{};
      final now = DateTime.now();

      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: i));
        final key = _dayKey(date);
        final raw = _usageBox.get(key);

        if (raw is String) {
          try {
            final list = jsonDecode(raw) as List<dynamic>;
            stats[key] = list
                .map((item) =>
                    AppUsageRecord.fromJson(item as Map<String, dynamic>))
                .toList();
          } catch (e) {
            _logger.w('Failed to decode usage for $key: $e');
          }
        }
      }

      return stats;
    } catch (e) {
      _logger.e('Failed to get weekly stats: $e');
      return {};
    }
  }

  int getExtensionsUsedToday() {
    try {
      final todayKey = _todayKey();
      final raw = _usageBox.get('extensions_$todayKey');
      if (raw is int) return raw;
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> incrementExtensionsUsed() async {
    try {
      final todayKey = _todayKey();
      final current = getExtensionsUsedToday();
      await _usageBox.put('extensions_$todayKey', current + 1);
    } catch (e) {
      _logger.e('Failed to increment extensions: $e');
    }
  }

  int getGoalStreakDays() {
    try {
      final now = DateTime.now();
      int streak = 0;

      for (int i = 1; i <= 365; i++) {
        final date = now.subtract(Duration(days: i));
        final key = _dayKey(date);
        final raw = _usageBox.get(key);

        if (raw is String) {
          try {
            final list = jsonDecode(raw) as List<dynamic>;
            final records = list
                .map((item) =>
                    AppUsageRecord.fromJson(item as Map<String, dynamic>))
                .toList();

            final allWithinLimits =
                records.every((r) => !r.isLimitReached);
            if (allWithinLimits && records.isNotEmpty) {
              streak++;
            } else {
              break;
            }
          } catch (e) {
            break;
          }
        } else {
          break;
        }
      }

      return streak;
    } catch (e) {
      return 0;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _todayKey() {
    final now = DateTime.now();
    return _dayKey(now);
  }

  String _dayKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return 'usage_${normalized.toIso8601String()}';
  }
}
