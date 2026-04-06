import '../../today/domain/models/daily_anchors.dart';

enum OnboardingStep {
  theProblem, // was: theNoise
  theSolution, // merges: clarityPromise + fourPillars
  yourIdentity, // merges: discoverIdentity + identityRevealed
  yourPath, // merges: startingCommitment + lifestyleSetup
  yourAccount, // merges: ready + pre-onboarding signup
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
    this.miniAssessmentAnswers = const [],
    this.primaryArchetypeId,
    this.commitmentCategory,
    this.primaryMissionFocus,
    this.email,
    this.fullName,
    this.phone,
    this.personalDistractions = const [],
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

  /// Answers from the 3-question mini-assessment (indices into option lists).
  final List<int> miniAssessmentAnswers;

  /// The archetype determined by the mini-assessment.
  final String? primaryArchetypeId;

  /// The chosen commitment category: 'growth', 'discipline', or 'charity'.
  final String? commitmentCategory;

  final String? primaryMissionFocus;

  /// Account signup fields.
  final String? email;
  final String? fullName;
  final String? phone;

  /// User-selected personal distractions/addictions.
  final List<String> personalDistractions;

  bool get isLastStep => step == OnboardingStep.yourAccount;

  int get currentStepIndex => switch (step) {
        OnboardingStep.theProblem => 0,
        OnboardingStep.theSolution => 1,
        OnboardingStep.yourIdentity => 2,
        OnboardingStep.yourPath => 3,
        OnboardingStep.yourAccount => 4,
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
    List<int>? miniAssessmentAnswers,
    String? primaryArchetypeId,
    String? commitmentCategory,
    String? primaryMissionFocus,
    String? email,
    String? fullName,
    String? phone,
    List<String>? personalDistractions,
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
      miniAssessmentAnswers: miniAssessmentAnswers ?? this.miniAssessmentAnswers,
      primaryArchetypeId: primaryArchetypeId ?? this.primaryArchetypeId,
      commitmentCategory: commitmentCategory ?? this.commitmentCategory,
      primaryMissionFocus: primaryMissionFocus ?? this.primaryMissionFocus,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      personalDistractions: personalDistractions ?? this.personalDistractions,
    );
  }
}
