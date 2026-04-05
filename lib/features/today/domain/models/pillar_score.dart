/// Represents the user's progress across the 4 Pillars of Clarity.
///
/// Each pillar score ranges from 0.0 (no progress) to 1.0 (fully achieved).
class PillarScore {
  const PillarScore({
    this.careerAlignment = 0.0,
    this.spiritualGrowth = 0.0,
    this.focusShield = 0.0,
    this.wordAndFaith = 0.0,
  });

  /// Career Alignment: assessment done, archetype set, 40-day goal active.
  final double careerAlignment;

  /// Spiritual Growth: commitment progress across Growth/Discipline/Charity tracks.
  final double spiritualGrowth;

  /// Focus Shield: app lock configured, daily limits respected.
  final double focusShield;

  /// Word & Faith: bible read, games played, meditation done, prayer logged.
  final double wordAndFaith;

  /// Overall clarity score across all 4 pillars (0.0 - 1.0).
  double get overall =>
      (careerAlignment + spiritualGrowth + focusShield + wordAndFaith) / 4.0;

  /// Number of pillars with any progress.
  int get activePillars => [
        careerAlignment,
        spiritualGrowth,
        focusShield,
        wordAndFaith,
      ].where((s) => s > 0).length;

  /// Percentage of overall clarity (0 - 100).
  int get overallPercent => (overall * 100).round();

  PillarScore copyWith({
    double? careerAlignment,
    double? spiritualGrowth,
    double? focusShield,
    double? wordAndFaith,
  }) {
    return PillarScore(
      careerAlignment: careerAlignment ?? this.careerAlignment,
      spiritualGrowth: spiritualGrowth ?? this.spiritualGrowth,
      focusShield: focusShield ?? this.focusShield,
      wordAndFaith: wordAndFaith ?? this.wordAndFaith,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PillarScore &&
        other.careerAlignment == careerAlignment &&
        other.spiritualGrowth == spiritualGrowth &&
        other.focusShield == focusShield &&
        other.wordAndFaith == wordAndFaith;
  }

  @override
  int get hashCode => Object.hash(
        careerAlignment,
        spiritualGrowth,
        focusShield,
        wordAndFaith,
      );

  @override
  String toString() =>
      'PillarScore(career: $careerAlignment, growth: $spiritualGrowth, '
      'focus: $focusShield, word: $wordAndFaith, overall: ${overall.toStringAsFixed(2)})';
}
