import '../../today/domain/models/daily_anchors.dart';

enum OnboardingStep {
  welcome,
  threeAnchors,
  sampleHabits,
  lifestyleSetup,
  socialPresence,
}

class OnboardingState {
  const OnboardingState({
    required this.step,
    required this.lifestyle,
    required this.morningTime,
    required this.eveningTime,
    required this.morningReminderEnabled,
    required this.eveningReminderEnabled,
    required this.primaryVirtue,
    required this.socialPresenceOptIn,
    required this.contactsImported,
  });

  final OnboardingStep step;
  final String lifestyle;
  final String morningTime;
  final String eveningTime;
  final bool morningReminderEnabled;
  final bool eveningReminderEnabled;
  final VirtueType primaryVirtue;
  final bool socialPresenceOptIn;
  final bool contactsImported;

  bool get isLastStep => step == OnboardingStep.socialPresence;

  int get currentStepIndex => switch (step) {
        OnboardingStep.welcome => 0,
        OnboardingStep.threeAnchors => 1,
        OnboardingStep.sampleHabits => 2,
        OnboardingStep.lifestyleSetup => 3,
        OnboardingStep.socialPresence => 4,
      };

  int get totalSteps => 5;

  OnboardingState copyWith({
    OnboardingStep? step,
    String? lifestyle,
    String? morningTime,
    String? eveningTime,
    bool? morningReminderEnabled,
    bool? eveningReminderEnabled,
    VirtueType? primaryVirtue,
    bool? socialPresenceOptIn,
    bool? contactsImported,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      lifestyle: lifestyle ?? this.lifestyle,
      morningTime: morningTime ?? this.morningTime,
      eveningTime: eveningTime ?? this.eveningTime,
      morningReminderEnabled: morningReminderEnabled ?? this.morningReminderEnabled,
      eveningReminderEnabled: eveningReminderEnabled ?? this.eveningReminderEnabled,
      primaryVirtue: primaryVirtue ?? this.primaryVirtue,
      socialPresenceOptIn: socialPresenceOptIn ?? this.socialPresenceOptIn,
      contactsImported: contactsImported ?? this.contactsImported,
    );
  }
}
