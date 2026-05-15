import '../../companion/domain/models/christian_life_baseline.dart';
import '../../assessment/data/assessment_task_catalog.dart';
import '../../assessment/domain/models/archetype.dart';
import '../../assessment/domain/models/archetype_resonance.dart';
import '../../today/domain/models/daily_anchors.dart';
import '../domain/compass_discovery_catalog.dart';

/// Phase 1 — the pre-signup portion of onboarding. Four screens only.
/// Baseline, habits, struggles, commitment, companion, reminders all move
/// to Phase 2/3 (post-signup) so the user gets through signup fast and
/// the deeper work happens inside an authenticated session.
enum OnboardingStep {
  theProblem, // The Noise
  theSolution, // Deeper signal — clarity + pillars
  yourIdentity, // Exact age + full spiritual compass
  yourAccount, // Signup (merges ready + pre-onboarding signup)
}

class OnboardingCompassData {
  const OnboardingCompassData({
    required this.instances,
    required this.fears,
    required this.maturity,
  });

  final int instances;
  final String fears;
  final int maturity;

  Map<String, dynamic> toJson() => {
    'instances': instances,
    'fears': fears,
    'maturity': maturity,
  };

  factory OnboardingCompassData.fromJson(Map<String, dynamic> map) {
    return OnboardingCompassData(
      instances: (map['instances'] as num?)?.toInt() ?? 0,
      fears: map['fears'] as String? ?? 'none',
      maturity: (map['maturity'] as num?)?.toInt() ?? 0,
    );
  }
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
    this.primaryArchetypeId,
    this.commitmentCategory,
    this.primaryMissionFocus,
    this.exactAge,
    this.selectedArchetypeIds = const [],
    this.compassAssessmentData = const {},
    this.compassSeasonArchetype,
    this.compassPressureArchetype,
    this.compassPostponedArchetype,
    this.compassPeopleNeedArchetype,
    this.compassDistortionFearArchetype,
    this.spiritualAgeScore = 0,
    this.spiritualAgeStage = 'Infant',
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

  /// The primary archetype determined by the full spiritual compass.
  final String? primaryArchetypeId;

  /// The chosen commitment category: 'growth', 'discipline', or 'charity'.
  final String? commitmentCategory;

  final String? primaryMissionFocus;

  /// Exact age is used privately during onboarding to derive `ageBand`.
  /// It is kept only in memory and is not serialized into the onboarding draft.
  final int? exactAge;

  /// Full compass selections. Names match `Archetype.name`.
  final List<String> selectedArchetypeIds;
  final Map<String, OnboardingCompassData> compassAssessmentData;
  final String? compassSeasonArchetype;
  final String? compassPressureArchetype;
  final String? compassPostponedArchetype;
  final String? compassPeopleNeedArchetype;
  final String? compassDistortionFearArchetype;
  final int spiritualAgeScore;
  final String spiritualAgeStage;

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

  String? get derivedAgeBand {
    final age = exactAge;
    if (age == null) return null;
    if (age < 18) return '13_17';
    if (age <= 24) return '18_24';
    if (age <= 34) return '25_34';
    if (age <= 49) return '35_49';
    return '50_plus';
  }

  bool get hasFullCompassResult {
    return exactAge != null &&
        compassSeasonArchetype != null &&
        compassPressureArchetype != null &&
        compassPostponedArchetype != null &&
        compassPeopleNeedArchetype != null &&
        compassDistortionFearArchetype != null &&
        primaryArchetypeId != null &&
        spiritualAgeScore > 0;
  }

  String? get compassSeasonName => primaryArchetypeId == null
      ? null
      : CompassDiscoveryCatalog.seasonNameFor(primaryArchetypeId!);

  String get selectedCompassPath {
    if (spiritualAgeScore < 45) return 'development';
    if (spiritualAgeScore >= 82) return 'engagement';
    return 'recalibration';
  }

  List<AssessmentActionTask> get selectedCompassTasks {
    const catalog = AssessmentTaskCatalog();
    return catalog.tasksForPath(selectedCompassPath).take(3).toList();
  }

  Map<String, dynamic> get compassActionPlan => {
    'path': selectedCompassPath,
    'tasks': selectedCompassTasks
        .map(
          (task) => {
            'id': task.id,
            'title': task.title,
            'description': task.description,
          },
        )
        .toList(),
    'primary_commitments': _archetypeFor(
      primaryArchetypeId,
    )?.growthCommitments.take(3).toList(),
    'discipline_commitments': _archetypeFor(
      primaryArchetypeId,
    )?.disciplineCommitments.take(3).toList(),
    'charity_commitments': _archetypeFor(
      primaryArchetypeId,
    )?.charityCommitments.take(3).toList(),
  };

  Map<String, dynamic> get compassArchetypeProfile {
    final primary = _archetypeFor(primaryArchetypeId);
    final persona = ArchetypeResonances.resolveFromOrderedNames(
      selectedArchetypeIds,
    );
    if (primary == null) {
      return {
        'tribe': persona.tribe,
        'bible_character': persona.bibleCharacter,
      };
    }
    return {
      'name': primary.name,
      'identity': primary.identity,
      'strengths': primary.strengths,
      'distortions': primary.distortions,
      'tribe': persona.tribe,
      'bible_character': persona.bibleCharacter,
      'typical_distractions': primary.typicalDistractions,
      'modern_addictions': primary.modernAddictions,
      'inversion_strategy': primary.inversionStrategy,
      'primary_vice': primary.primaryVice?.name,
      'secondary_vice': primary.secondaryVice?.name,
    };
  }

  Map<String, dynamic> get compassSubmissionPayload => {
    'assessment_version': 'situational_distortion_compass_v2',
    'selected_archetypes': selectedArchetypeIds,
    'primary_archetype': primaryArchetypeId,
    'top_archetypes': selectedArchetypeIds,
    'assessment_data': {
      for (final id in selectedArchetypeIds)
        if (compassAssessmentData[id] != null)
          id: compassAssessmentData[id]!.toJson(),
    },
    'average_maturity': spiritualAgeScore,
    'development_maturity': spiritualAgeScore,
    'selected_path': selectedCompassPath,
    'selected_tasks': selectedCompassTasks.map((task) => task.id).toList(),
    'spiritual_age_score': spiritualAgeScore,
    'spiritual_age_stage': spiritualAgeStage,
    'age_band': derivedAgeBand,
    'metadata': {
      'action_plan': compassActionPlan,
      'primary_archetype_profile': compassArchetypeProfile,
      'discovery_answers': {
        'current_season': compassSeasonArchetype,
        'pressure_pattern': compassPressureArchetype,
        'postponed_pattern': compassPostponedArchetype,
        'people_need_pattern': compassPeopleNeedArchetype,
        'distortion_fear': compassDistortionFearArchetype,
        'season_signal': compassSeasonName,
      },
      'spiritual_growth_story': {
        'stage': spiritualAgeStage,
        'soil_seed_fruit':
            'The Spirit plants living seed in the soil of a person. Maturity comes through seasons of tending, pruning, endurance, and fruit.',
        'struggle_forms': [
          'physical',
          'mental',
          'addiction',
          'financial',
          'relational',
          'spiritual',
        ],
      },
    },
    'completed_at': DateTime.now().toIso8601String(),
  };

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
    'primaryArchetypeId': primaryArchetypeId,
    'commitmentCategory': commitmentCategory,
    'primaryMissionFocus': primaryMissionFocus,
    'selectedArchetypeIds': selectedArchetypeIds,
    'compassAssessmentData': compassAssessmentData.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
    'compassSeasonArchetype': compassSeasonArchetype,
    'compassPressureArchetype': compassPressureArchetype,
    'compassPostponedArchetype': compassPostponedArchetype,
    'compassPeopleNeedArchetype': compassPeopleNeedArchetype,
    'compassDistortionFearArchetype': compassDistortionFearArchetype,
    'spiritualAgeScore': spiritualAgeScore,
    'spiritualAgeStage': spiritualAgeStage,
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
      primaryVirtue:
          VirtueTypeX.fromStorage(map['primaryVirtue'] as String?) ??
          VirtueType.humility,
      socialPresenceOptIn: map['socialPresenceOptIn'] as bool? ?? false,
      contactsImported: map['contactsImported'] as bool? ?? false,
      primaryArchetypeId: map['primaryArchetypeId'] as String?,
      commitmentCategory: map['commitmentCategory'] as String?,
      primaryMissionFocus: map['primaryMissionFocus'] as String?,
      exactAge: null,
      selectedArchetypeIds:
          (map['selectedArchetypeIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      compassAssessmentData:
          (map['compassAssessmentData'] as Map?)?.map(
            (key, value) => MapEntry(
              key.toString(),
              OnboardingCompassData.fromJson(
                Map<String, dynamic>.from(value as Map),
              ),
            ),
          ) ??
          const {},
      compassSeasonArchetype: map['compassSeasonArchetype'] as String?,
      compassPressureArchetype: map['compassPressureArchetype'] as String?,
      compassPostponedArchetype: map['compassPostponedArchetype'] as String?,
      compassPeopleNeedArchetype: map['compassPeopleNeedArchetype'] as String?,
      compassDistortionFearArchetype:
          map['compassDistortionFearArchetype'] as String?,
      spiritualAgeScore: (map['spiritualAgeScore'] as num?)?.toInt() ?? 0,
      spiritualAgeStage: map['spiritualAgeStage'] as String? ?? 'Infant',
      email: map['email'] as String?,
      fullName: map['fullName'] as String?,
      phone: map['phone'] as String?,
      personalDistractions:
          (map['personalDistractions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      bibleReadingCadence: map['bibleReadingCadence'] == null
          ? null
          : BibleReadingCadenceX.fromStorage(
              map['bibleReadingCadence'] as String?,
            ),
      lastChurchAttendance: map['lastChurchAttendance'] == null
          ? null
          : ChurchAttendanceX.fromStorage(
              map['lastChurchAttendance'] as String?,
            ),
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
    String? primaryArchetypeId,
    String? commitmentCategory,
    String? primaryMissionFocus,
    int? exactAge,
    bool clearExactAge = false,
    List<String>? selectedArchetypeIds,
    Map<String, OnboardingCompassData>? compassAssessmentData,
    String? compassSeasonArchetype,
    String? compassPressureArchetype,
    String? compassPostponedArchetype,
    String? compassPeopleNeedArchetype,
    String? compassDistortionFearArchetype,
    int? spiritualAgeScore,
    String? spiritualAgeStage,
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
      morningReminderEnabled:
          morningReminderEnabled ?? this.morningReminderEnabled,
      eveningReminderEnabled:
          eveningReminderEnabled ?? this.eveningReminderEnabled,
      primaryVirtue: primaryVirtue ?? this.primaryVirtue,
      socialPresenceOptIn: socialPresenceOptIn ?? this.socialPresenceOptIn,
      contactsImported: contactsImported ?? this.contactsImported,
      primaryArchetypeId: primaryArchetypeId ?? this.primaryArchetypeId,
      commitmentCategory: commitmentCategory ?? this.commitmentCategory,
      primaryMissionFocus: primaryMissionFocus ?? this.primaryMissionFocus,
      exactAge: clearExactAge ? null : (exactAge ?? this.exactAge),
      selectedArchetypeIds: selectedArchetypeIds ?? this.selectedArchetypeIds,
      compassAssessmentData:
          compassAssessmentData ?? this.compassAssessmentData,
      compassSeasonArchetype:
          compassSeasonArchetype ?? this.compassSeasonArchetype,
      compassPressureArchetype:
          compassPressureArchetype ?? this.compassPressureArchetype,
      compassPostponedArchetype:
          compassPostponedArchetype ?? this.compassPostponedArchetype,
      compassPeopleNeedArchetype:
          compassPeopleNeedArchetype ?? this.compassPeopleNeedArchetype,
      compassDistortionFearArchetype:
          compassDistortionFearArchetype ?? this.compassDistortionFearArchetype,
      spiritualAgeScore: spiritualAgeScore ?? this.spiritualAgeScore,
      spiritualAgeStage: spiritualAgeStage ?? this.spiritualAgeStage,
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

Archetype? _archetypeFor(String? name) {
  if (name == null) return null;
  return Archetype.allArchetypes.cast<Archetype?>().firstWhere(
    (archetype) => archetype?.name == name,
    orElse: () => null,
  );
}
