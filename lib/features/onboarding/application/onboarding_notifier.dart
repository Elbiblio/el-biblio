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
            lifestyle: 'Student', // Default
            morningTime: '07:30', // Default
            eveningTime: '21:00', // Default
            morningReminderEnabled: true,
            eveningReminderEnabled: true,
            primaryVirtue: settings.primaryVirtue,
            socialPresenceOptIn: false,
            contactsImported: false,
          ),
        );

  void next() {
    final nextStep = switch (state.step) {
      OnboardingStep.welcome => OnboardingStep.threeAnchors,
      OnboardingStep.threeAnchors => OnboardingStep.sampleHabits,
      OnboardingStep.sampleHabits => OnboardingStep.lifestyleSetup,
      OnboardingStep.lifestyleSetup => OnboardingStep.socialPresence,
      OnboardingStep.socialPresence => OnboardingStep.socialPresence,
    };

    state = state.copyWith(step: nextStep);
  }

  void back() {
    final previousStep = switch (state.step) {
      OnboardingStep.welcome => OnboardingStep.welcome,
      OnboardingStep.threeAnchors => OnboardingStep.welcome,
      OnboardingStep.sampleHabits => OnboardingStep.threeAnchors,
      OnboardingStep.lifestyleSetup => OnboardingStep.sampleHabits,
      OnboardingStep.socialPresence => OnboardingStep.lifestyleSetup,
    };

    state = state.copyWith(step: previousStep);
  }

  void setLifestyle(String lifestyle) {
    String suggestedMorning = '07:30';
    String suggestedEvening = '21:00';

    if (lifestyle == 'Student') {
      suggestedMorning = '05:30';
      suggestedEvening = '22:00';
    } else if (lifestyle == 'Physical Work') {
      suggestedMorning = '06:30';
      suggestedEvening = '21:30';
    } else if (lifestyle == 'Work from Home') {
      suggestedMorning = '07:00';
      suggestedEvening = '20:30';
    } else if (lifestyle == 'Not Employed') {
      suggestedMorning = '08:00';
      suggestedEvening = '20:00';
    }

    state = state.copyWith(
      lifestyle: lifestyle,
      morningTime: suggestedMorning,
      eveningTime: suggestedEvening,
    );
  }

  void setMorningTime(String time) {
    state = state.copyWith(morningTime: time);
  }

  void setEveningTime(String time) {
    state = state.copyWith(eveningTime: time);
  }

  void toggleMorningReminder(bool enabled) {
    state = state.copyWith(morningReminderEnabled: enabled);
  }

  void toggleEveningReminder(bool enabled) {
    state = state.copyWith(eveningReminderEnabled: enabled);
  }

  void setPrimaryVirtue(VirtueType value) {
    state = state.copyWith(primaryVirtue: value);
  }

  void setSocialPresenceOptIn(bool optedIn) {
    state = state.copyWith(socialPresenceOptIn: optedIn);
  }

  void setContactsImported(bool imported) {
    state = state.copyWith(contactsImported: imported);
  }
}
