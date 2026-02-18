import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/today/domain/models/daily_anchors.dart';
import '../storage/app_settings.dart';
import '../storage/settings_storage.dart';

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._storage) : super(AppSettings.defaults()) {
    _hydrate();
  }

  final SettingsStorage _storage;

  Future<void> _hydrate() async {
    state = await _storage.load();
  }

  Future<void> resetOnboarding() async {
    final next = AppSettings.defaults();
    state = next;
    await _storage.save(next);
  }

  Future<void> completeOnboarding({
    required VirtueType primaryVirtue,
    required VirtueType neglectedVirtue,
    required String journalReminderTime,
    required String notificationWindow,
    required bool remindersEnabled,
    bool socialPresenceOptIn = false,
    bool contactsImported = false,
  }) async {
    final next = state.copyWith(
      onboardingCompleted: true,
      primaryVirtue: primaryVirtue,
      neglectedVirtue: neglectedVirtue,
      journalReminderTime: journalReminderTime,
      notificationWindow: notificationWindow,
      remindersEnabled: remindersEnabled,
      socialPresenceOptIn: socialPresenceOptIn,
      contactsImported: contactsImported,
    );

    state = next;
    await _storage.save(next);
  }

  Future<void> setVirtueFocus({
    required VirtueType primaryVirtue,
    required VirtueType neglectedVirtue,
  }) async {
    final next = state.copyWith(
      primaryVirtue: primaryVirtue,
      neglectedVirtue: neglectedVirtue,
    );
    state = next;
    await _storage.save(next);
  }

  Future<void> registerDailyCheckIn(DateTime day) async {
    final normalized = DateTime(day.year, day.month, day.day);
    final previous = state.lastCheckIn;

    if (previous != null) {
      final previousDay = DateTime(previous.year, previous.month, previous.day);
      if (previousDay == normalized) {
        return;
      }
    }

    var streak = 1;
    if (previous != null) {
      final previousDay = DateTime(previous.year, previous.month, previous.day);
      final difference = normalized.difference(previousDay).inDays;
      streak = difference == 1 ? state.streakCount + 1 : 1;
    }

    final next = state.copyWith(
      streakCount: streak,
      lastCheckIn: normalized,
    );

    state = next;
    await _storage.save(next);
  }
}
