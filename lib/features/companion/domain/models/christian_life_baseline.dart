/// Honest baseline of the user's current Christian-life habits and posture,
/// captured once during onboarding and refreshable from the profile screen.
///
/// Feeds weekly-plan generation, first-commitment difficulty, and the
/// companion's initial tone. Treated as a snapshot in time — never shamed.
class ChristianLifeBaseline {
  const ChristianLifeBaseline({
    required this.bibleReadingCadence,
    required this.lastChurchAttendance,
    required this.prayerRhythm,
    required this.sovereigntyScore,
    required this.charityScore,
    required this.trustScore,
    required this.capturedAt,
    this.source = 'onboarding',
  });

  final BibleReadingCadence bibleReadingCadence;
  final ChurchAttendance lastChurchAttendance;
  final PrayerRhythm prayerRhythm;

  /// 1–5 self-rating for belief in God's sovereignty.
  final int sovereigntyScore;

  /// 1–5 self-rating for charity / giving posture.
  final int charityScore;

  /// 1–5 self-rating for faith/trust in others.
  final int trustScore;

  final DateTime capturedAt;

  /// `onboarding` | `recalibration`.
  final String source;

  /// Weakest dimension — used by the companion to anchor its first nudge and
  /// by the backend planner to right-size the first commitment.
  BaselineDimension get weakestDimension {
    final cadenceScore = bibleReadingCadence.normalizedScore;
    final churchScore = lastChurchAttendance.normalizedScore;
    final prayerScore = prayerRhythm.normalizedScore;
    final entries = <MapEntry<BaselineDimension, double>>[
      MapEntry(BaselineDimension.bibleReading, cadenceScore),
      MapEntry(BaselineDimension.churchAttendance, churchScore),
      MapEntry(BaselineDimension.prayer, prayerScore),
      MapEntry(BaselineDimension.sovereignty, sovereigntyScore / 5.0),
      MapEntry(BaselineDimension.charity, charityScore / 5.0),
      MapEntry(BaselineDimension.trust, trustScore / 5.0),
    ];
    entries.sort((a, b) => a.value.compareTo(b.value));
    return entries.first.key;
  }

  Map<String, dynamic> toMap() => {
        'bibleReadingCadence': bibleReadingCadence.storageValue,
        'lastChurchAttendance': lastChurchAttendance.storageValue,
        'prayerRhythm': prayerRhythm.storageValue,
        'sovereigntyScore': sovereigntyScore,
        'charityScore': charityScore,
        'trustScore': trustScore,
        'capturedAt': capturedAt.toIso8601String(),
        'source': source,
      };

  factory ChristianLifeBaseline.fromMap(Map<String, dynamic> map) {
    return ChristianLifeBaseline(
      bibleReadingCadence: BibleReadingCadenceX.fromStorage(
        map['bibleReadingCadence'] as String?,
      ),
      lastChurchAttendance: ChurchAttendanceX.fromStorage(
        map['lastChurchAttendance'] as String?,
      ),
      prayerRhythm: PrayerRhythmX.fromStorage(map['prayerRhythm'] as String?),
      sovereigntyScore: (map['sovereigntyScore'] as num?)?.toInt() ?? 3,
      charityScore: (map['charityScore'] as num?)?.toInt() ?? 3,
      trustScore: (map['trustScore'] as num?)?.toInt() ?? 3,
      capturedAt: DateTime.tryParse(map['capturedAt'] as String? ?? '') ??
          DateTime.now(),
      source: map['source'] as String? ?? 'onboarding',
    );
  }

  /// JSON payload for the backend `/christian-life-baselines` endpoint and
  /// for inclusion in the signup payload.
  Map<String, dynamic> toApiPayload() => {
        'bible_reading_cadence': bibleReadingCadence.storageValue,
        'last_church_attendance': lastChurchAttendance.storageValue,
        'prayer_rhythm': prayerRhythm.storageValue,
        'sovereignty_score': sovereigntyScore,
        'charity_score': charityScore,
        'trust_score': trustScore,
        'captured_at': capturedAt.toIso8601String(),
        'source': source,
      };

  ChristianLifeBaseline copyWith({
    BibleReadingCadence? bibleReadingCadence,
    ChurchAttendance? lastChurchAttendance,
    PrayerRhythm? prayerRhythm,
    int? sovereigntyScore,
    int? charityScore,
    int? trustScore,
    DateTime? capturedAt,
    String? source,
  }) {
    return ChristianLifeBaseline(
      bibleReadingCadence: bibleReadingCadence ?? this.bibleReadingCadence,
      lastChurchAttendance: lastChurchAttendance ?? this.lastChurchAttendance,
      prayerRhythm: prayerRhythm ?? this.prayerRhythm,
      sovereigntyScore: sovereigntyScore ?? this.sovereigntyScore,
      charityScore: charityScore ?? this.charityScore,
      trustScore: trustScore ?? this.trustScore,
      capturedAt: capturedAt ?? this.capturedAt,
      source: source ?? this.source,
    );
  }
}

enum BaselineDimension {
  bibleReading,
  churchAttendance,
  prayer,
  sovereignty,
  charity,
  trust,
}

extension BaselineDimensionLabel on BaselineDimension {
  String get humanLabel => switch (this) {
        BaselineDimension.bibleReading => 'time in the Word',
        BaselineDimension.churchAttendance => 'gathering with the church',
        BaselineDimension.prayer => 'prayer rhythm',
        BaselineDimension.sovereignty => 'trust in God\'s sovereignty',
        BaselineDimension.charity => 'generosity',
        BaselineDimension.trust => 'trust in community',
      };
}

enum BibleReadingCadence {
  rarely,
  fewTimesMonth,
  weekly,
  severalTimesWeek,
  daily,
}

extension BibleReadingCadenceX on BibleReadingCadence {
  String get storageValue => switch (this) {
        BibleReadingCadence.rarely => 'rarely',
        BibleReadingCadence.fewTimesMonth => 'few_times_month',
        BibleReadingCadence.weekly => 'weekly',
        BibleReadingCadence.severalTimesWeek => 'several_times_week',
        BibleReadingCadence.daily => 'daily',
      };

  String get label => switch (this) {
        BibleReadingCadence.rarely => 'Rarely',
        BibleReadingCadence.fewTimesMonth => 'A few times a month',
        BibleReadingCadence.weekly => 'Weekly',
        BibleReadingCadence.severalTimesWeek => 'Several times a week',
        BibleReadingCadence.daily => 'Daily',
      };

  double get normalizedScore => switch (this) {
        BibleReadingCadence.rarely => 0.1,
        BibleReadingCadence.fewTimesMonth => 0.3,
        BibleReadingCadence.weekly => 0.55,
        BibleReadingCadence.severalTimesWeek => 0.8,
        BibleReadingCadence.daily => 1.0,
      };

  static BibleReadingCadence fromStorage(String? raw) {
    return BibleReadingCadence.values.firstWhere(
      (v) => v.storageValue == raw,
      orElse: () => BibleReadingCadence.fewTimesMonth,
    );
  }
}

enum ChurchAttendance {
  thisWeek,
  thisMonth,
  fewMonthsAgo,
  overAYear,
  never,
}

extension ChurchAttendanceX on ChurchAttendance {
  String get storageValue => switch (this) {
        ChurchAttendance.thisWeek => 'this_week',
        ChurchAttendance.thisMonth => 'this_month',
        ChurchAttendance.fewMonthsAgo => 'few_months_ago',
        ChurchAttendance.overAYear => 'over_a_year',
        ChurchAttendance.never => 'never',
      };

  String get label => switch (this) {
        ChurchAttendance.thisWeek => 'This week',
        ChurchAttendance.thisMonth => 'This month',
        ChurchAttendance.fewMonthsAgo => 'A few months ago',
        ChurchAttendance.overAYear => 'Over a year ago',
        ChurchAttendance.never => 'Never regularly',
      };

  double get normalizedScore => switch (this) {
        ChurchAttendance.thisWeek => 1.0,
        ChurchAttendance.thisMonth => 0.7,
        ChurchAttendance.fewMonthsAgo => 0.4,
        ChurchAttendance.overAYear => 0.15,
        ChurchAttendance.never => 0.0,
      };

  static ChurchAttendance fromStorage(String? raw) {
    return ChurchAttendance.values.firstWhere(
      (v) => v.storageValue == raw,
      orElse: () => ChurchAttendance.thisMonth,
    );
  }
}

enum PrayerRhythm {
  onAndOff,
  whenIRemember,
  dailyShort,
  dailyExtended,
  multipleTimesDaily,
}

extension PrayerRhythmX on PrayerRhythm {
  String get storageValue => switch (this) {
        PrayerRhythm.onAndOff => 'on_and_off',
        PrayerRhythm.whenIRemember => 'when_i_remember',
        PrayerRhythm.dailyShort => 'daily_short',
        PrayerRhythm.dailyExtended => 'daily_extended',
        PrayerRhythm.multipleTimesDaily => 'multiple_times_daily',
      };

  String get label => switch (this) {
        PrayerRhythm.onAndOff => 'On-and-off',
        PrayerRhythm.whenIRemember => 'When I remember',
        PrayerRhythm.dailyShort => 'Daily, briefly',
        PrayerRhythm.dailyExtended => 'Daily, with depth',
        PrayerRhythm.multipleTimesDaily => 'Multiple times a day',
      };

  double get normalizedScore => switch (this) {
        PrayerRhythm.onAndOff => 0.15,
        PrayerRhythm.whenIRemember => 0.35,
        PrayerRhythm.dailyShort => 0.6,
        PrayerRhythm.dailyExtended => 0.85,
        PrayerRhythm.multipleTimesDaily => 1.0,
      };

  static PrayerRhythm fromStorage(String? raw) {
    return PrayerRhythm.values.firstWhere(
      (v) => v.storageValue == raw,
      orElse: () => PrayerRhythm.whenIRemember,
    );
  }
}
