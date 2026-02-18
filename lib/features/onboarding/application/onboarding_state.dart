import '../../today/domain/models/daily_anchors.dart';

enum OnboardingStep {
  welcome,
  purposeFraming,
  compassAssessment,
  dailyRhythm,
  socialPresence,
  review,
}

class OnboardingState {
  const OnboardingState({
    required this.step,
    required this.primaryVirtue,
    required this.neglectedVirtue,
    required this.remindersEnabled,
    required this.journalReminderTime,
    required this.notificationWindow,
    required this.socialPresenceOptIn,
    required this.contactsImported,
  });

  final OnboardingStep step;
  final VirtueType primaryVirtue;
  final VirtueType neglectedVirtue;
  final bool remindersEnabled;
  final String journalReminderTime;
  final String notificationWindow;
  final bool socialPresenceOptIn;
  final bool contactsImported;

  bool get isLastStep => step == OnboardingStep.review;

  int get currentStepIndex => switch (step) {
        OnboardingStep.welcome => 0,
        OnboardingStep.purposeFraming => 1,
        OnboardingStep.compassAssessment => 2,
        OnboardingStep.dailyRhythm => 3,
        OnboardingStep.socialPresence => 4,
        OnboardingStep.review => 5,
      };

  int get totalSteps => 6;

  OnboardingState copyWith({
    OnboardingStep? step,
    VirtueType? primaryVirtue,
    VirtueType? neglectedVirtue,
    bool? remindersEnabled,
    String? journalReminderTime,
    String? notificationWindow,
    bool? socialPresenceOptIn,
    bool? contactsImported,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      primaryVirtue: primaryVirtue ?? this.primaryVirtue,
      neglectedVirtue: neglectedVirtue ?? this.neglectedVirtue,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      journalReminderTime: journalReminderTime ?? this.journalReminderTime,
      notificationWindow: notificationWindow ?? this.notificationWindow,
      socialPresenceOptIn: socialPresenceOptIn ?? this.socialPresenceOptIn,
      contactsImported: contactsImported ?? this.contactsImported,
    );
  }

  static const defaultNotificationWindow = 'gentle';
}
