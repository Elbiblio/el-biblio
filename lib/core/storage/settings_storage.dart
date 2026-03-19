import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../features/today/domain/models/daily_anchors.dart';
import '../../shared/domain/models/activity.dart';
import '../errors/app_exception.dart';
import '../theme/app_theme_mode.dart';
import 'app_settings.dart';
import 'hive_boxes.dart';

class SettingsStorage {
  const SettingsStorage();

  static const _settingsKey = 'app_settings';

  Box<dynamic> get _box => Hive.box<dynamic>(HiveBoxes.settings);

  Future<AppSettings> load() async {
    try {
      final raw = _box.get(_settingsKey);
      if (raw is Map) {
        return AppSettings.fromMap(Map<String, dynamic>.from(raw));
      }
      return AppSettings.defaults();
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
    required AppThemeMode mode,
    required Brightness brightness,
  }) async {
    final current = await load();
    await save(
      current.copyWith(
        themeMode: mode,
        brightness: brightness,
      ),
    );
  }

  Future<void> completeOnboarding() async {
    final current = await load();
    await save(
      current.copyWith(
        onboardingCompleted: true,
      ),
    );
  }

  Future<void> updateVirtueFocus({
    required VirtueType primaryVirtue,
  }) async {
    final current = await load();
    await save(
      current.copyWith(
        primaryVirtue: primaryVirtue,
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

  Future<void> markAssessmentPromptSeen() async {
    final current = await load();
    await save(
      current.copyWith(
        hasSeenAssessmentPrompt: true,
      ),
    );
  }

  // Reading history local storage methods
  static const _readingHistoryKey = 'reading_history';
  
  Future<void> saveReadingHistory(List<Activity> history) async {
    try {
      final historyJson = history.map((activity) => activity.toJson()).toList();
      await _box.put(_readingHistoryKey, historyJson);
    } catch (error) {
      throw StorageException('Unable to persist reading history.', error);
    }
  }

  Future<List<Activity>> loadReadingHistory() async {
    try {
      final raw = _box.get(_readingHistoryKey);
      if (raw == null || raw is! List) {
        return [];
      }
      return raw.map((json) => Activity.fromJson(json)).toList();
    } catch (error) {
      // Return empty list on error rather than throwing
      debugPrint('Error loading reading history: $error');
      return [];
    }
  }

  Future<void> updateTTSVoice(String voiceKey) async {
    final current = await load();
    await save(current.copyWith(selectedTTSVoice: voiceKey));
  }

  Future<void> markPrayerGuideShown() async {
    final current = await load();
    await save(
      current.copyWith(
        lastPrayerGuideDate: DateTime.now(),
      ),
    );
  }

  bool shouldShowPrayerGuide(AppSettings settings) {
    final now = DateTime.now();
    final lastShown = settings.lastPrayerGuideDate;
    
    // If never shown before, show it
    if (lastShown == null) {
      return true;
    }
    
    // Check if it's a different day than last shown
    final today = DateTime(now.year, now.month, now.day);
    final lastShownDay = DateTime(lastShown.year, lastShown.month, lastShown.day);
    
    return today.isAfter(lastShownDay);
  }

  bool isMorningHours() {
    final now = DateTime.now();
    final hour = now.hour;
    return hour >= 5 && hour < 12; // 5 AM to 12 PM
  }
}
