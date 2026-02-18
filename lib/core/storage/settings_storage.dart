import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../features/today/domain/models/daily_anchors.dart';
import '../errors/app_exception.dart';
import '../theme/app_theme_variant.dart';
import 'app_settings.dart';
import 'hive_boxes.dart';

class SettingsStorage {
  const SettingsStorage();

  static const _settingsKey = 'app_settings';

  Box<dynamic> get _box => Hive.box<dynamic>(HiveBoxes.settings);

  Future<AppSettings> load() async {
    try {
      final raw = _box.get(_settingsKey);
      return AppSettings.fromMap(raw is Map ? raw : null);
    } catch (error) {
      throw StorageException('Unable to load app settings.', error);
    }
  }

  Future<void> save(AppSettings settings) async {
    try {
      await _box.put(_settingsKey, settings.toMap());
    } catch (error) {
      throw StorageException('Unable to persist app settings.', error);
    }
  }

  Future<void> updateTheme({
    required AppThemeVariant variant,
    required Brightness brightness,
  }) async {
    final current = await load();
    await save(
      current.copyWith(
        themeVariant: variant,
        brightness: brightness,
      ),
    );
  }

  Future<void> completeOnboarding({
    required VirtueType primaryVirtue,
    required VirtueType neglectedVirtue,
    required String journalReminderTime,
    required String notificationWindow,
    required bool remindersEnabled,
  }) async {
    final current = await load();
    await save(
      current.copyWith(
        onboardingCompleted: true,
        primaryVirtue: primaryVirtue,
        neglectedVirtue: neglectedVirtue,
        journalReminderTime: journalReminderTime,
        notificationWindow: notificationWindow,
        remindersEnabled: remindersEnabled,
      ),
    );
  }

  Future<void> updateVirtueFocus({
    required VirtueType primaryVirtue,
    required VirtueType neglectedVirtue,
  }) async {
    final current = await load();
    await save(
      current.copyWith(
        primaryVirtue: primaryVirtue,
        neglectedVirtue: neglectedVirtue,
      ),
    );
  }

  Future<void> updateStreak({
    required int streakCount,
    required DateTime lastCheckIn,
  }) async {
    final current = await load();
    await save(
      current.copyWith(
        streakCount: streakCount,
        lastCheckIn: lastCheckIn,
      ),
    );
  }

  Future<void> updateBibleFontSize(double fontSize) async {
    final current = await load();
    await save(
      current.copyWith(
        bibleFontSize: fontSize,
      ),
    );
  }
}

