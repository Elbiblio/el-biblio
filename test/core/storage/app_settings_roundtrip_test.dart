import 'package:flutter_test/flutter_test.dart';

import 'package:elbiblio/core/models/accountability_tone.dart';
import 'package:elbiblio/core/storage/app_settings.dart';
import 'package:elbiblio/features/companion/domain/models/christian_life_baseline.dart';

void main() {
  group('AppSettings.toMap/fromMap round-trip (B5 fields)', () {
    test('valid goodHabits + struggles preserved', () {
      final settings = AppSettings.defaults().copyWith(
        goodHabits: ['daily_prayer', 'fasting'],
        struggles: ['anger'],
        accountabilityCadence: 'weekly',
      );

      final restored = AppSettings.fromMap(settings.toMap());

      expect(restored.goodHabits, ['daily_prayer', 'fasting']);
      expect(restored.struggles, ['anger']);
      expect(restored.accountabilityCadence, 'weekly');
    });

    test('unknown habit keys are filtered on rehydrate', () {
      final raw = AppSettings.defaults().toMap()
        ..['goodHabits'] = <String>['daily_prayer', 'stale_key_from_old_app']
        ..['struggles'] = <String>['anger', 'invented_struggle'];

      final restored = AppSettings.fromMap(raw);

      expect(restored.goodHabits, ['daily_prayer']);
      expect(restored.struggles, ['anger']);
    });

    test('accountabilityCadence normalizes to daily for garbage values', () {
      final raw = AppSettings.defaults().toMap()
        ..['accountabilityCadence'] = 'monthly-ish';
      final restored = AppSettings.fromMap(raw);
      expect(restored.accountabilityCadence, 'daily');
    });

    test('christianLifeBaseline round-trips via toMap/fromMap', () {
      final baseline = ChristianLifeBaseline(
        bibleReadingCadence: BibleReadingCadence.daily,
        lastChurchAttendance: ChurchAttendance.thisWeek,
        prayerRhythm: PrayerRhythm.multipleTimesDaily,
        sovereigntyScore: 5,
        charityScore: 4,
        trustScore: 3,
        capturedAt: DateTime.utc(2026, 4, 23, 12),
      );

      final settings = AppSettings.defaults().copyWith(
        christianLifeBaseline: baseline,
      );
      final restored = AppSettings.fromMap(settings.toMap());
      final restoredBaseline = restored.christianLifeBaseline!;

      expect(
        restoredBaseline.bibleReadingCadence,
        baseline.bibleReadingCadence,
      );
      expect(
        restoredBaseline.lastChurchAttendance,
        baseline.lastChurchAttendance,
      );
      expect(restoredBaseline.prayerRhythm, baseline.prayerRhythm);
      expect(restoredBaseline.sovereigntyScore, baseline.sovereigntyScore);
      expect(restoredBaseline.charityScore, baseline.charityScore);
      expect(restoredBaseline.trustScore, baseline.trustScore);
    });

    test('onboardingDraft string preserved and clearable', () {
      final withDraft = AppSettings.defaults().copyWith(
        onboardingDraft: '{"step":"x"}',
      );
      expect(
        AppSettings.fromMap(withDraft.toMap()).onboardingDraft,
        '{"step":"x"}',
      );

      final cleared = withDraft.copyWith(clearOnboardingDraft: true);
      expect(cleared.onboardingDraft, isNull);
      expect(AppSettings.fromMap(cleared.toMap()).onboardingDraft, isNull);
    });

    test('pending compass submission round-trips and is clearable', () {
      final payload = {
        'primary_archetype': 'Watchman',
        'spiritual_age_score': 48,
        'age_band': '25_34',
      };
      final withPending = AppSettings.defaults().copyWith(
        pendingCompassSubmission: payload,
      );

      expect(
        AppSettings.fromMap(withPending.toMap()).pendingCompassSubmission,
        payload,
      );

      final cleared = withPending.copyWith(clearPendingCompassSubmission: true);
      expect(cleared.pendingCompassSubmission, isNull);
      expect(
        AppSettings.fromMap(cleared.toMap()).pendingCompassSubmission,
        isNull,
      );
    });

    test('first check-in plan round-trips and is clearable', () {
      final settings = AppSettings.defaults().copyWith(
        firstCheckInPlanCommitmentId: 12,
        firstCheckInPlanWhen: 'After lunch',
        firstCheckInPlanObstacle: 'Scrolling when tired',
      );

      final restored = AppSettings.fromMap(settings.toMap());

      expect(restored.firstCheckInPlanCommitmentId, 12);
      expect(restored.firstCheckInPlanWhen, 'After lunch');
      expect(restored.firstCheckInPlanObstacle, 'Scrolling when tired');

      final cleared = restored.copyWith(clearFirstCheckInPlan: true);
      expect(cleared.firstCheckInPlanCommitmentId, isNull);
      expect(cleared.firstCheckInPlanWhen, isNull);
      expect(cleared.firstCheckInPlanObstacle, isNull);
    });

    test('accountability tone and monthly review metadata round-trip', () {
      final startedAt = DateTime.utc(2026, 5, 1, 9);
      final nextReviewAt = DateTime.utc(2026, 6, 1, 9);
      final lastReviewAt = DateTime.utc(2026, 4, 30, 20);
      final settings = AppSettings.defaults().copyWith(
        accountabilityTone: AccountabilityTone.firm,
        currentCommitmentSeasonStartedAt: startedAt,
        nextCommitmentReviewAt: nextReviewAt,
        lastCommitmentReviewAt: lastReviewAt,
        commitmentMonthlyReviewOutcome: CommitmentMonthlyReviewOutcome.deepen,
      );

      final restored = AppSettings.fromMap(settings.toMap());

      expect(restored.accountabilityTone, AccountabilityTone.firm);
      expect(restored.currentCommitmentSeasonStartedAt, startedAt);
      expect(restored.nextCommitmentReviewAt, nextReviewAt);
      expect(restored.lastCommitmentReviewAt, lastReviewAt);
      expect(
        restored.commitmentMonthlyReviewOutcome,
        CommitmentMonthlyReviewOutcome.deepen,
      );

      final cleared = restored.copyWith(clearCommitmentReview: true);
      expect(cleared.currentCommitmentSeasonStartedAt, isNull);
      expect(cleared.nextCommitmentReviewAt, isNull);
      expect(cleared.lastCommitmentReviewAt, isNull);
      expect(cleared.commitmentMonthlyReviewOutcome, isNull);
    });
  });
}
