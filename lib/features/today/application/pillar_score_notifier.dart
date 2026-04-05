import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/app_providers.dart';
import '../domain/models/pillar_score.dart';

/// Aggregates data from multiple feature providers to compute pillar scores.
///
/// Uses simple heuristics for MVP:
/// - Career: 0.33 if assessment seen, 0.33 if archetype set, 0.34 if 40-day goal active
/// - Growth: based on graduated commitment progress
/// - Focus: 0.5 if app lock configured, 0.5 if limits respected today
/// - Word & Faith: 0.25 each for bible, prayer, habit commitment, energy action today
class PillarScoreNotifier extends StateNotifier<PillarScore> {
  PillarScoreNotifier(this._ref) : super(const PillarScore()) {
    _computeScores();
  }

  final Ref _ref;

  void refresh() => _computeScores();

  void _computeScores() {
    state = PillarScore(
      careerAlignment: _computeCareerAlignment(),
      spiritualGrowth: _computeSpiritualGrowth(),
      focusShield: _computeFocusShield(),
      wordAndFaith: _computeWordAndFaith(),
    );
  }

  // ---------------------------------------------------------------------------
  // Career Alignment (0.0 - 1.0)
  // ---------------------------------------------------------------------------
  double _computeCareerAlignment() {
    double score = 0.0;

    final settings = _ref.read(settingsProvider);

    // 0.33 if assessment has been seen
    if (settings.hasSeenAssessmentPrompt) {
      score += 0.33;
    }

    // 0.33 if archetype is set
    if (settings.primaryArchetypeId != null &&
        settings.primaryArchetypeId!.isNotEmpty) {
      score += 0.33;
    }

    // 0.34 if 40-day goal is active
    final fortyDayState = _ref.read(fortyDayProvider);
    if (fortyDayState.hasActiveGoal) {
      score += 0.34;
    }

    return score.clamp(0.0, 1.0);
  }

  // ---------------------------------------------------------------------------
  // Spiritual Growth (0.0 - 1.0)
  // ---------------------------------------------------------------------------
  double _computeSpiritualGrowth() {
    final gcState = _ref.read(graduatedCommitmentProvider);
    final progress = gcState.progress;

    // Use the graduated commitment progress stats
    final totalCompleted = progress.completedCount;
    final currentLevel = progress.currentLevel;

    // Simple heuristic: base score on completions and level
    // Level 1 = 0.1 base, Level 2 = 0.2, etc., plus completions contribution
    double score = 0.0;

    // Level contribution (up to 0.5)
    score += (currentLevel * 0.1).clamp(0.0, 0.5);

    // Completions contribution (up to 0.5)
    // 10+ completions = full 0.5
    score += (totalCompleted / 10.0 * 0.5).clamp(0.0, 0.5);

    return score.clamp(0.0, 1.0);
  }

  // ---------------------------------------------------------------------------
  // Focus Shield (0.0 - 1.0)
  // ---------------------------------------------------------------------------
  double _computeFocusShield() {
    double score = 0.0;

    final appLockState = _ref.read(appLockProvider);

    // 0.5 if app lock is configured (has any monitored apps)
    if (appLockState.totalMonitoredApps > 0) {
      score += 0.5;
    }

    // 0.5 if limits are respected today (doing well)
    if (appLockState.todayUsage.isNotEmpty && appLockState.isDoingWell) {
      score += 0.5;
    } else if (appLockState.totalMonitoredApps > 0 &&
        appLockState.todayUsage.isEmpty) {
      // No usage recorded yet today but has configs — partial credit
      score += 0.25;
    }

    return score.clamp(0.0, 1.0);
  }

  // ---------------------------------------------------------------------------
  // Word & Faith (0.0 - 1.0)
  // ---------------------------------------------------------------------------
  double _computeWordAndFaith() {
    double score = 0.0;
    final today = DateTime.now();

    // 0.25 for Bible reading today
    final bibleState = _ref.read(bibleReadingProvider);
    if (bibleState.lastReadingDate != null) {
      final lastRead = bibleState.lastReadingDate!;
      if (lastRead.year == today.year &&
          lastRead.month == today.month &&
          lastRead.day == today.day) {
        score += 0.25;
      }
    }

    // 0.25 for prayer/virtue completed today
    final anchors = _ref.read(dailyAnchorsProvider);
    if (anchors.coreVirtue.isCompleted) {
      score += 0.25;
    }

    // 0.25 for habit commitment activity today
    if (anchors.habit.isCompleted || anchors.habit.isCommitmentActive) {
      score += 0.25;
    }

    // 0.25 for energy action (physical activity) today
    if (anchors.energyAction.isCompleted) {
      score += 0.25;
    }

    return score.clamp(0.0, 1.0);
  }
}
