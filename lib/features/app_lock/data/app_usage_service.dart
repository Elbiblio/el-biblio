import 'dart:io';

import 'package:app_usage/app_usage.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

import '../domain/models/app_lock_config.dart';
import '../domain/models/app_usage_record.dart';

/// Service that fetches Android app usage stats via the app_usage plugin.
/// Returns empty results on non-Android platforms.
class AppUsageService {
  AppUsageService(this._logger);

  final Logger _logger;

  static const MethodChannel _usageAccessChannel = MethodChannel(
    'com.elbiblio.app/usage_access',
  );

  /// Checks whether usage stats access is granted.
  /// Returns false on non-Android platforms.
  Future<bool> hasPermission() async {
    if (!Platform.isAndroid) return false;

    // Preferred path: native check without opening settings UI.
    try {
      final granted = await _usageAccessChannel.invokeMethod<bool>(
        'isUsageAccessGranted',
      );
      if (granted != null) return granted;
    } on MissingPluginException catch (e) {
      _logger.w('Usage access channel missing; falling back: $e');
    } on PlatformException catch (e) {
      _logger.w('Usage access check failed: ${e.code}');
    } catch (e) {
      _logger.w('Unexpected usage access check error: $e');
    }

    // Fallback path for older app builds without the channel.
    try {
      final now = DateTime.now();
      await AppUsage().getAppUsage(now.subtract(const Duration(hours: 1)), now);
      return true;
    } on PlatformException catch (e) {
      _logger.d('Usage stats permission not granted: ${e.code}');
      return false;
    } on ArgumentError catch (e) {
      _logger.w('Invalid usage query window while checking permission: $e');
      return false;
    } catch (e) {
      _logger.w('Unexpected error checking usage stats permission: $e');
      return false;
    }
  }

  /// Opens Android usage access settings.
  /// Returns false on non-Android platforms or if launch fails.
  Future<bool> openUsageSettings() async {
    if (!Platform.isAndroid) return false;

    try {
      final opened = await _usageAccessChannel.invokeMethod<bool>(
        'openUsageAccessSettings',
      );
      return opened ?? false;
    } on PlatformException catch (e) {
      _logger.w('Failed to open usage settings: ${e.code}');
      return false;
    } catch (e) {
      _logger.w('Unexpected error opening usage settings: $e');
      return false;
    }
  }

  /// Gets today's app usage for monitored [configs].
  /// Returns empty list on non-Android platforms or if permission is denied.
  Future<List<AppUsageRecord>> getTodayUsage(
    List<AppLockConfig> configs,
  ) async {
    if (!Platform.isAndroid) return [];

    final enabledConfigs = configs.where((c) => c.isEnabled).toList();
    if (enabledConfigs.isEmpty) return [];

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final infos = await AppUsage().getAppUsage(startOfDay, now);

      // Build a lookup map by package name for fast matching.
      final usageMap = <String, Duration>{};
      for (final info in infos) {
        usageMap[info.packageName] = info.usage;
      }

      final records = <AppUsageRecord>[];
      for (final config in enabledConfigs) {
        final usage = usageMap[config.packageName] ?? Duration.zero;
        records.add(
          AppUsageRecord(
            packageName: config.packageName,
            appName: config.appName,
            usedMinutesToday: usage.inMinutes,
            dailyLimitMinutes: config.dailyLimitMinutes,
            date: now,
          ),
        );
      }

      return records;
    } on PlatformException catch (e) {
      _logger.d('Usage stats permission not granted: ${e.code}');
      // Return [] so the notifier can fall back to manual Hive tracking.
      return [];
    } on ArgumentError catch (e) {
      _logger.w('Invalid usage query window: $e');
      return [];
    } catch (e) {
      _logger.w('Unexpected error reading usage stats: $e');
      return [];
    }
  }
}
