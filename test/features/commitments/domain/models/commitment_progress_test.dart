import 'package:flutter_test/flutter_test.dart';
import 'package:elbiblio/features/commitments/domain/models/commitment_progress.dart';
import 'package:elbiblio/features/commitments/domain/models/graduated_commitment.dart';

void main() {
  group('CommitmentProgress', () {
    group('construction and defaults', () {
      test('default values are correct', () {
        const progress = CommitmentProgress();
        expect(progress.currentLevel, 1);
        expect(progress.completedCount, 0);
        expect(progress.failedCount, 0);
        expect(progress.currentStreak, 0);
        expect(progress.longestStreak, 0);
        expect(progress.totalXpEarned, 0);
        expect(progress.lastCompletedAt, isNull);
        expect(progress.activeCommitmentStartedAt, isNull);
        expect(progress.activeCommitmentId, isNull);
        expect(progress.activeStatus, CommitmentStatus.idle);
        expect(progress.levelCompletionMap, isEmpty);
      });
    });

    group('computed properties', () {
      test('overallProgress is 0 when no completions', () {
        const progress = CommitmentProgress();
        expect(progress.overallProgress, 0.0);
      });

      test('overallProgress is 0.5 at 20 completions', () {
        const progress = CommitmentProgress(completedCount: 20);
        expect(progress.overallProgress, 0.5);
      });

      test('overallProgress is 1.0 at 40 completions', () {
        const progress = CommitmentProgress(completedCount: 40);
        expect(progress.overallProgress, 1.0);
      });

      test('currentTier returns correct tier for level', () {
        const p1 = CommitmentProgress(currentLevel: 1);
        expect(p1.currentTier, CommitmentTier.quickWins);

        const p15 = CommitmentProgress(currentLevel: 15);
        expect(p15.currentTier, CommitmentTier.buildingBlocks);

        const p25 = CommitmentProgress(currentLevel: 25);
        expect(p25.currentTier, CommitmentTier.halfDayChallenges);

        const p35 = CommitmentProgress(currentLevel: 35);
        expect(p35.currentTier, CommitmentTier.dayLong);
      });

      test('hasActiveCommitment is true when id set and status active', () {
        const p = CommitmentProgress(
          activeCommitmentId: 'gc_01',
          activeStatus: CommitmentStatus.active,
        );
        expect(p.hasActiveCommitment, true);
      });

      test('hasActiveCommitment is false when status is not active', () {
        const p = CommitmentProgress(
          activeCommitmentId: 'gc_01',
          activeStatus: CommitmentStatus.idle,
        );
        expect(p.hasActiveCommitment, false);
      });

      test('hasActiveCommitment is false when id is null', () {
        const p = CommitmentProgress(
          activeStatus: CommitmentStatus.active,
        );
        expect(p.hasActiveCommitment, false);
      });

      test('isJourneyComplete is true at 40 completions', () {
        const p = CommitmentProgress(completedCount: 40);
        expect(p.isJourneyComplete, true);
      });

      test('isJourneyComplete is false at 39 completions', () {
        const p = CommitmentProgress(completedCount: 39);
        expect(p.isJourneyComplete, false);
      });

      test('tierCompletedCount counts completed levels in current tier', () {
        const p = CommitmentProgress(
          currentLevel: 5,
          levelCompletionMap: {1: true, 2: true, 3: true, 4: false, 5: true},
        );
        // Tier 1 (quickWins) levels 1-10
        // Levels with true: 1, 2, 3, 5 = 4 completed (level 4 is false)
        expect(p.tierCompletedCount, 4);
      });

      test('tierCompletedCount for tier 2', () {
        const p = CommitmentProgress(
          currentLevel: 15,
          levelCompletionMap: {11: true, 12: true, 15: true},
        );
        expect(p.tierCompletedCount, 3);
      });
    });

    group('copyWith', () {
      test('returns identical copy when no args', () {
        const original = CommitmentProgress(
          currentLevel: 5,
          completedCount: 4,
          totalXpEarned: 100,
        );
        final copy = original.copyWith();
        expect(copy.currentLevel, 5);
        expect(copy.completedCount, 4);
        expect(copy.totalXpEarned, 100);
      });

      test('clearActiveCommitment nullifies commitment fields', () {
        final now = DateTime.now();
        final p = CommitmentProgress(
          activeCommitmentId: 'gc_01',
          activeCommitmentStartedAt: now,
        );
        final cleared = p.copyWith(clearActiveCommitment: true);
        expect(cleared.activeCommitmentId, isNull);
        expect(cleared.activeCommitmentStartedAt, isNull);
      });

      test('clearLastCompleted nullifies lastCompletedAt', () {
        final p = CommitmentProgress(
          lastCompletedAt: DateTime.now(),
        );
        final cleared = p.copyWith(clearLastCompleted: true);
        expect(cleared.lastCompletedAt, isNull);
      });
    });

    group('JSON serialization', () {
      test('round-trip preserves all fields', () {
        final now = DateTime(2025, 6, 15, 10, 30);
        final progress = CommitmentProgress(
          currentLevel: 5,
          completedCount: 4,
          failedCount: 1,
          currentStreak: 3,
          longestStreak: 4,
          totalXpEarned: 100,
          lastCompletedAt: now,
          activeCommitmentStartedAt: now,
          activeCommitmentId: 'gc_05',
          activeStatus: CommitmentStatus.active,
          levelCompletionMap: const {1: true, 2: true, 3: true, 4: true},
        );

        final json = progress.toJson();
        final restored = CommitmentProgress.fromJson(json);

        expect(restored.currentLevel, 5);
        expect(restored.completedCount, 4);
        expect(restored.failedCount, 1);
        expect(restored.currentStreak, 3);
        expect(restored.longestStreak, 4);
        expect(restored.totalXpEarned, 100);
        expect(restored.lastCompletedAt, now);
        expect(restored.activeCommitmentStartedAt, now);
        expect(restored.activeCommitmentId, 'gc_05');
        expect(restored.activeStatus, CommitmentStatus.active);
        expect(restored.levelCompletionMap.length, 4);
        expect(restored.levelCompletionMap[1], true);
      });

      test('fromJson handles missing fields with defaults', () {
        final restored = CommitmentProgress.fromJson({});
        expect(restored.currentLevel, 1);
        expect(restored.completedCount, 0);
        expect(restored.activeStatus, CommitmentStatus.idle);
        expect(restored.levelCompletionMap, isEmpty);
      });

      test('toJson encodes levelCompletionMap keys as strings', () {
        const p = CommitmentProgress(
          levelCompletionMap: {1: true, 2: false},
        );
        final json = p.toJson();
        final map = json['levelCompletionMap'] as Map;
        expect(map.containsKey('1'), true);
        expect(map.containsKey('2'), true);
      });
    });

    group('equality', () {
      test('two progress objects with same key fields are equal', () {
        const a = CommitmentProgress(
          currentLevel: 5,
          completedCount: 4,
          activeStatus: CommitmentStatus.active,
          activeCommitmentId: 'gc_05',
        );
        const b = CommitmentProgress(
          currentLevel: 5,
          completedCount: 4,
          activeStatus: CommitmentStatus.active,
          activeCommitmentId: 'gc_05',
        );
        expect(a, b);
      });
    });
  });

  group('CommitmentStatus', () {
    test('has exactly 5 values', () {
      expect(CommitmentStatus.values.length, 5);
    });

    test('contains expected statuses', () {
      expect(CommitmentStatus.values, contains(CommitmentStatus.idle));
      expect(CommitmentStatus.values, contains(CommitmentStatus.active));
      expect(CommitmentStatus.values, contains(CommitmentStatus.completed));
      expect(CommitmentStatus.values, contains(CommitmentStatus.failed));
      expect(CommitmentStatus.values, contains(CommitmentStatus.expired));
    });
  });
}
