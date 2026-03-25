import 'package:flutter_test/flutter_test.dart';
import 'package:elbiblio/features/commitments/domain/models/graduated_commitment.dart';

void main() {
  group('GraduatedCommitment', () {
    late GraduatedCommitment commitment;

    setUp(() {
      commitment = const GraduatedCommitment(
        id: 'gc_01',
        level: 1,
        title: 'Pause and Breathe',
        description: 'Take 3 slow, deep breaths.',
        durationMinutes: 2,
        tier: CommitmentTier.quickWins,
        virtue: 'peace',
        tips: ['Breathe in for 4 counts.', 'Close your eyes.'],
        xpReward: 10,
        encouragement: 'Great job!',
        failureGrace: 'Try again.',
      );
    });

    group('construction', () {
      test('creates with all required fields', () {
        expect(commitment.id, 'gc_01');
        expect(commitment.level, 1);
        expect(commitment.title, 'Pause and Breathe');
        expect(commitment.durationMinutes, 2);
        expect(commitment.tier, CommitmentTier.quickWins);
        expect(commitment.virtue, 'peace');
        expect(commitment.tips.length, 2);
        expect(commitment.xpReward, 10);
        expect(commitment.encouragement, 'Great job!');
        expect(commitment.failureGrace, 'Try again.');
      });

      test('tips defaults to empty list', () {
        const c = GraduatedCommitment(
          id: 'test',
          level: 1,
          title: 'Test',
          description: 'Desc',
          durationMinutes: 2,
          tier: CommitmentTier.quickWins,
          virtue: 'peace',
          xpReward: 10,
          encouragement: 'Enc',
          failureGrace: 'Grace',
        );
        expect(c.tips, isEmpty);
      });
    });

    group('copyWith', () {
      test('returns identical copy when no args', () {
        final copy = commitment.copyWith();
        expect(copy.id, commitment.id);
        expect(copy.level, commitment.level);
        expect(copy.title, commitment.title);
        expect(copy.xpReward, commitment.xpReward);
      });

      test('updates specified fields only', () {
        final copy = commitment.copyWith(level: 5, xpReward: 50);
        expect(copy.level, 5);
        expect(copy.xpReward, 50);
        expect(copy.id, commitment.id);
        expect(copy.title, commitment.title);
      });
    });

    group('JSON serialization', () {
      test('toJson produces correct map', () {
        final json = commitment.toJson();
        expect(json['id'], 'gc_01');
        expect(json['level'], 1);
        expect(json['tier'], 1); // quickWins.value == 1
        expect(json['tips'], isA<List>());
        expect(json['xpReward'], 10);
      });

      test('round-trip toJson -> fromJson preserves data', () {
        final json = commitment.toJson();
        final restored = GraduatedCommitment.fromJson(json);
        expect(restored.id, commitment.id);
        expect(restored.level, commitment.level);
        expect(restored.title, commitment.title);
        expect(restored.description, commitment.description);
        expect(restored.durationMinutes, commitment.durationMinutes);
        expect(restored.tier, commitment.tier);
        expect(restored.virtue, commitment.virtue);
        expect(restored.tips, commitment.tips);
        expect(restored.xpReward, commitment.xpReward);
        expect(restored.encouragement, commitment.encouragement);
        expect(restored.failureGrace, commitment.failureGrace);
      });

      test('fromJson handles missing tips', () {
        final json = commitment.toJson();
        json.remove('tips');
        final restored = GraduatedCommitment.fromJson(json);
        expect(restored.tips, isEmpty);
      });
    });

    group('equality', () {
      test('two commitments with same id and level are equal', () {
        final other = commitment.copyWith(title: 'Different Title');
        expect(commitment, other);
      });

      test('two commitments with different id are not equal', () {
        final other = commitment.copyWith(id: 'gc_02');
        expect(commitment == other, false);
      });

      test('two commitments with different level are not equal', () {
        final other = commitment.copyWith(level: 2);
        expect(commitment == other, false);
      });
    });

    test('toString contains level and title', () {
      expect(commitment.toString(), contains('level: 1'));
      expect(commitment.toString(), contains('Pause and Breathe'));
    });
  });

  group('CommitmentTier', () {
    test('has exactly 4 values', () {
      expect(CommitmentTier.values.length, 4);
    });

    test('values have correct numeric values', () {
      expect(CommitmentTier.quickWins.value, 1);
      expect(CommitmentTier.buildingBlocks.value, 2);
      expect(CommitmentTier.halfDayChallenges.value, 3);
      expect(CommitmentTier.dayLong.value, 4);
    });

    test('all tiers have non-empty labels', () {
      for (final tier in CommitmentTier.values) {
        expect(tier.label.isNotEmpty, true);
      }
    });

    test('all tiers have non-empty timeRange', () {
      for (final tier in CommitmentTier.values) {
        expect(tier.timeRange.isNotEmpty, true);
      }
    });

    test('all tiers have non-empty icon', () {
      for (final tier in CommitmentTier.values) {
        expect(tier.icon.isNotEmpty, true);
      }
    });

    group('fromLevel', () {
      test('levels 1-10 return quickWins', () {
        for (int i = 1; i <= 10; i++) {
          expect(CommitmentTier.fromLevel(i), CommitmentTier.quickWins,
              reason: 'Level $i should be quickWins');
        }
      });

      test('levels 11-20 return buildingBlocks', () {
        for (int i = 11; i <= 20; i++) {
          expect(CommitmentTier.fromLevel(i), CommitmentTier.buildingBlocks,
              reason: 'Level $i should be buildingBlocks');
        }
      });

      test('levels 21-30 return halfDayChallenges', () {
        for (int i = 21; i <= 30; i++) {
          expect(CommitmentTier.fromLevel(i), CommitmentTier.halfDayChallenges,
              reason: 'Level $i should be halfDayChallenges');
        }
      });

      test('levels 31-40 return dayLong', () {
        for (int i = 31; i <= 40; i++) {
          expect(CommitmentTier.fromLevel(i), CommitmentTier.dayLong,
              reason: 'Level $i should be dayLong');
        }
      });
    });

    group('fromValue', () {
      test('returns correct tier for valid values', () {
        expect(CommitmentTier.fromValue(1), CommitmentTier.quickWins);
        expect(CommitmentTier.fromValue(2), CommitmentTier.buildingBlocks);
        expect(CommitmentTier.fromValue(3), CommitmentTier.halfDayChallenges);
        expect(CommitmentTier.fromValue(4), CommitmentTier.dayLong);
      });

      test('returns quickWins for invalid value', () {
        expect(CommitmentTier.fromValue(0), CommitmentTier.quickWins);
        expect(CommitmentTier.fromValue(99), CommitmentTier.quickWins);
      });
    });
  });
}
