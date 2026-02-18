import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/app_providers.dart';
import '../../../core/storage/app_settings.dart';
import '../../today/domain/models/daily_anchors.dart';
import 'onboarding_state.dart';

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  final settings = ref.watch(settingsProvider);
  return OnboardingNotifier(settings);
});

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier(AppSettings settings)
      : super(
          OnboardingState(
            step: OnboardingStep.welcome,
            primaryVirtue: settings.primaryVirtue,
            neglectedVirtue: settings.neglectedVirtue,
            remindersEnabled: settings.remindersEnabled,
            journalReminderTime: settings.journalReminderTime,
            notificationWindow: settings.notificationWindow,
            socialPresenceOptIn: false,
            contactsImported: false,
          ),
        );

  void next() {
    final nextStep = switch (state.step) {
      OnboardingStep.welcome => OnboardingStep.purposeFraming,
      OnboardingStep.purposeFraming => OnboardingStep.compassAssessment,
      OnboardingStep.compassAssessment => OnboardingStep.dailyRhythm,
      OnboardingStep.dailyRhythm => OnboardingStep.socialPresence,
      OnboardingStep.socialPresence => OnboardingStep.review,
      OnboardingStep.review => OnboardingStep.review,
    };

    state = state.copyWith(step: nextStep);
  }

  void back() {
    final previousStep = switch (state.step) {
      OnboardingStep.welcome => OnboardingStep.welcome,
      OnboardingStep.purposeFraming => OnboardingStep.welcome,
      OnboardingStep.compassAssessment => OnboardingStep.purposeFraming,
      OnboardingStep.dailyRhythm => OnboardingStep.compassAssessment,
      OnboardingStep.socialPresence => OnboardingStep.dailyRhythm,
      OnboardingStep.review => OnboardingStep.socialPresence,
    };

    state = state.copyWith(step: previousStep);
  }

  void setVirtueFocus({
    required VirtueType primary,
    required VirtueType neglected,
  }) {
    state = state.copyWith(
      primaryVirtue: primary,
      neglectedVirtue: neglected,
    );
  }

  void setPrimaryVirtue(VirtueType value) {
    if (value == state.neglectedVirtue) {
      return;
    }
    state = state.copyWith(primaryVirtue: value);
  }

  void setNeglectedVirtue(VirtueType value) {
    if (value == state.primaryVirtue) {
      return;
    }
    state = state.copyWith(neglectedVirtue: value);
  }

  void setRemindersEnabled(bool enabled) {
    state = state.copyWith(remindersEnabled: enabled);
  }

  void setJournalReminderTime(String value) {
    state = state.copyWith(journalReminderTime: value);
  }

  void setNotificationWindow(String value) {
    state = state.copyWith(notificationWindow: value);
  }

  void setSocialPresenceOptIn(bool optedIn) {
    state = state.copyWith(socialPresenceOptIn: optedIn);
  }

  void setContactsImported(bool imported) {
    state = state.copyWith(contactsImported: imported);
  }
}
