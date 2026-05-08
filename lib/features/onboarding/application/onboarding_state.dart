import '../../companion/domain/models/christian_life_baseline.dart';
import '../../today/domain/models/daily_anchors.dart';

/// Phase 1 — the pre-signup portion of onboarding. Four screens only.
/// Baseline, habits, struggles, commitment, companion, reminders all move
/// to Phase 2/3 (post-signup) so the user gets through signup fast and
/// the deeper work happens inside an authenticated session.
enum OnboardingStep {
  theProblem, // The Noise
  theSolution, // Deeper signal — clarity + pillars
  yourIdentity, // 3-question mini-assessment + inline archetype reveal
  yourAccount, // Signup (merges ready + pre-onboarding signup)
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
    this.assessmentConfidence = 0.0,
    this.tiebreakerShown = false,
    this.primaryArchetypeId,
    this.commitmentCategory,
    this.primaryMissionFocus,
    this.email,
    this.fullName,
    this.phone,
    this.personalDistractions = const [],
    this.bibleReadingCadence,
    this.lastChurchAttendance,
    this.prayerRhythm,
    this.sovereigntyScore = 3,
    this.charityScore = 3,
    this.trustScore = 3,
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

  /// Confidence level of the archetype match (0.0 to 1.0).
  /// Higher values mean the top archetype scored significantly above the rest.
  final double assessmentConfidence;

  /// Whether a tiebreaker (4th) question was shown to resolve a close match.
  final bool tiebreakerShown;

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

  /// Christian-Life Baseline — honest self-snapshot collected on step 5.
  final BibleReadingCadence? bibleReadingCadence;
  final ChurchAttendance? lastChurchAttendance;
  final PrayerRhythm? prayerRhythm;
  final int sovereigntyScore;
  final int charityScore;
  final int trustScore;

  bool get hasBaselineAnswers =>
      bibleReadingCadence != null &&
      lastChurchAttendance != null &&
      prayerRhythm != null;

  ChristianLifeBaseline? get baselineOrNull {
    if (!hasBaselineAnswers) return null;
    return ChristianLifeBaseline(
      bibleReadingCadence: bibleReadingCadence!,
      lastChurchAttendance: lastChurchAttendance!,
      prayerRhythm: prayerRhythm!,
      sovereigntyScore: sovereigntyScore,
      charityScore: charityScore,
      trustScore: trustScore,
      capturedAt: DateTime.now(),
    );
  }

  bool get isLastStep => step == OnboardingStep.yourAccount;

  int get currentStepIndex => switch (step) {
        OnboardingStep.theProblem => 0,
        OnboardingStep.theSolution => 1,
        OnboardingStep.yourIdentity => 2,
        OnboardingStep.yourAccount => 3,
      };

  int get totalSteps => 4;

  Map<String, dynamic> toJson() => {
        'step': step.name,
        'lifestyle': lifestyle,
        'morningTime': morningTime,
        'eveningTime': eveningTime,
        'morningReminderEnabled': morningReminderEnabled,
        'eveningReminderEnabled': eveningReminderEnabled,
        'primaryVirtue': primaryVirtue.name,
        'socialPresenceOptIn': socialPresenceOptIn,
        'contactsImported': contactsImported,
        'miniAssessmentAnswers': miniAssessmentAnswers,
        'assessmentConfidence': assessmentConfidence,
        'tiebreakerShown': tiebreakerShown,
        'primaryArchetypeId': primaryArchetypeId,
        'commitmentCategory': commitmentCategory,
        'primaryMissionFocus': primaryMissionFocus,
        'email': email,
        'fullName': fullName,
        'phone': phone,
        'personalDistractions': personalDistractions,
        'bibleReadingCadence': bibleReadingCadence?.storageValue,
        'lastChurchAttendance': lastChurchAttendance?.storageValue,
        'prayerRhythm': prayerRhythm?.storageValue,
        'sovereigntyScore': sovereigntyScore,
        'charityScore': charityScore,
        'trustScore': trustScore,
      };

  factory OnboardingState.fromJson(Map<String, dynamic> map) {
    final stepName = map['step'] as String?;
    final step = OnboardingStep.values.firstWhere(
      (s) => s.name == stepName,
      orElse: () => OnboardingStep.theProblem,
    );
    return OnboardingState(
      step: step,
      lifestyle: map['lifestyle'] as String? ?? 'Student',
      morningTime: map['morningTime'] as String? ?? '07:30',
      eveningTime: map['eveningTime'] as String? ?? '21:00',
      morningReminderEnabled: map['morningReminderEnabled'] as bool? ?? true,
      eveningReminderEnabled: map['eveningReminderEnabled'] as bool? ?? true,
      primaryVirtue: VirtueTypeX.fromStorage(map['primaryVirtue'] as String?) ??
          VirtueType.humility,
      socialPresenceOptIn: map['socialPresenceOptIn'] as bool? ?? false,
      contactsImported: map['contactsImported'] as bool? ?? false,
      miniAssessmentAnswers: (map['miniAssessmentAnswers'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      assessmentConfidence:
          (map['assessmentConfidence'] as num?)?.toDouble() ?? 0.0,
      tiebreakerShown: map['tiebreakerShown'] as bool? ?? false,
      primaryArchetypeId: map['primaryArchetypeId'] as String?,
      commitmentCategory: map['commitmentCategory'] as String?,
      primaryMissionFocus: map['primaryMissionFocus'] as String?,
      email: map['email'] as String?,
      fullName: map['fullName'] as String?,
      phone: map['phone'] as String?,
      personalDistractions: (map['personalDistractions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      bibleReadingCadence: map['bibleReadingCadence'] == null
          ? null
          : BibleReadingCadenceX.fromStorage(
              map['bibleReadingCadence'] as String?),
      lastChurchAttendance: map['lastChurchAttendance'] == null
          ? null
          : ChurchAttendanceX.fromStorage(
              map['lastChurchAttendance'] as String?),
      prayerRhythm: map['prayerRhythm'] == null
          ? null
          : PrayerRhythmX.fromStorage(map['prayerRhythm'] as String?),
      sovereigntyScore: (map['sovereigntyScore'] as num?)?.toInt() ?? 3,
      charityScore: (map['charityScore'] as num?)?.toInt() ?? 3,
      trustScore: (map['trustScore'] as num?)?.toInt() ?? 3,
    );
  }

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
    double? assessmentConfidence,
    bool? tiebreakerShown,
    String? primaryArchetypeId,
    String? commitmentCategory,
    String? primaryMissionFocus,
    String? email,
    String? fullName,
    String? phone,
    List<String>? personalDistractions,
    BibleReadingCadence? bibleReadingCadence,
    ChurchAttendance? lastChurchAttendance,
    PrayerRhythm? prayerRhythm,
    int? sovereigntyScore,
    int? charityScore,
    int? trustScore,
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
      assessmentConfidence: assessmentConfidence ?? this.assessmentConfidence,
      tiebreakerShown: tiebreakerShown ?? this.tiebreakerShown,
      primaryArchetypeId: primaryArchetypeId ?? this.primaryArchetypeId,
      commitmentCategory: commitmentCategory ?? this.commitmentCategory,
      primaryMissionFocus: primaryMissionFocus ?? this.primaryMissionFocus,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      personalDistractions: personalDistractions ?? this.personalDistractions,
      bibleReadingCadence: bibleReadingCadence ?? this.bibleReadingCadence,
      lastChurchAttendance: lastChurchAttendance ?? this.lastChurchAttendance,
      prayerRhythm: prayerRhythm ?? this.prayerRhythm,
      sovereigntyScore: sovereigntyScore ?? this.sovereigntyScore,
      charityScore: charityScore ?? this.charityScore,
      trustScore: trustScore ?? this.trustScore,
    );
  }
}
