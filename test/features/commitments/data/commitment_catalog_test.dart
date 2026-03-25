import 'package:flutter_test/flutter_test.dart';
import 'package:elbiblio/features/commitments/data/commitment_catalog.dart';
import 'package:elbiblio/features/commitments/domain/models/graduated_commitment.dart';

void main() {
  group('CommitmentCatalog', () {
    test('has exactly 40 commitments', () {
      expect(CommitmentCatalog.all.length, 40);
    });

    test('levels are sequential from 1 to 40', () {
      final levels = CommitmentCatalog.all.map((c) => c.level).toList();
      for (int i = 0; i < 40; i++) {
        expect(levels[i], i + 1,
            reason: 'Expected level ${i + 1} at index $i, got ${levels[i]}');
      }
    });

    test('all commitments have unique ids', () {
      final ids = CommitmentCatalog.all.map((c) => c.id).toSet();
      expect(ids.length, 40);
    });

    test('all commitments have non-empty title', () {
      for (final c in CommitmentCatalog.all) {
        expect(c.title.isNotEmpty, true,
            reason: 'Level ${c.level} should have a non-empty title');
      }
    });

    test('all commitments have non-empty description', () {
      for (final c in CommitmentCatalog.all) {
        expect(c.description.isNotEmpty, true,
            reason: 'Level ${c.level} should have a non-empty description');
      }
    });

    test('all commitments have positive durationMinutes', () {
      for (final c in CommitmentCatalog.all) {
        expect(c.durationMinutes > 0, true,
            reason: 'Level ${c.level} should have positive duration');
      }
    });

    test('all commitments have non-empty virtue', () {
      for (final c in CommitmentCatalog.all) {
        expect(c.virtue.isNotEmpty, true,
            reason: 'Level ${c.level} should have a non-empty virtue');
      }
    });

    test('all commitments have positive xpReward', () {
      for (final c in CommitmentCatalog.all) {
        expect(c.xpReward > 0, true,
            reason: 'Level ${c.level} should have positive xpReward');
      }
    });

    test('all commitments have non-empty encouragement', () {
      for (final c in CommitmentCatalog.all) {
        expect(c.encouragement.isNotEmpty, true,
            reason: 'Level ${c.level} should have encouragement');
      }
    });

    test('all commitments have non-empty failureGrace', () {
      for (final c in CommitmentCatalog.all) {
        expect(c.failureGrace.isNotEmpty, true,
            reason: 'Level ${c.level} should have failureGrace');
      }
    });

    group('tier assignment', () {
      test('levels 1-10 are quickWins', () {
        for (final c in CommitmentCatalog.all.where((c) => c.level <= 10)) {
          expect(c.tier, CommitmentTier.quickWins,
              reason: 'Level ${c.level} should be quickWins');
        }
      });

      test('levels 11-20 are buildingBlocks', () {
        for (final c in CommitmentCatalog.all
            .where((c) => c.level >= 11 && c.level <= 20)) {
          expect(c.tier, CommitmentTier.buildingBlocks,
              reason: 'Level ${c.level} should be buildingBlocks');
        }
      });

      test('levels 21-30 are halfDayChallenges', () {
        for (final c in CommitmentCatalog.all
            .where((c) => c.level >= 21 && c.level <= 30)) {
          expect(c.tier, CommitmentTier.halfDayChallenges,
              reason: 'Level ${c.level} should be halfDayChallenges');
        }
      });

      test('levels 31-40 are dayLong', () {
        for (final c in CommitmentCatalog.all.where((c) => c.level >= 31)) {
          expect(c.tier, CommitmentTier.dayLong,
              reason: 'Level ${c.level} should be dayLong');
        }
      });
    });

    group('duration progression', () {
      test('tier 1 durations are between 2 and 5 minutes', () {
        for (final c in CommitmentCatalog.getForTier(CommitmentTier.quickWins)) {
          expect(c.durationMinutes, inInclusiveRange(2, 5),
              reason: 'Level ${c.level} quick win duration should be 2-5 min');
        }
      });

      test('tier 2 durations are between 15 and 60 minutes', () {
        for (final c in CommitmentCatalog.getForTier(CommitmentTier.buildingBlocks)) {
          expect(c.durationMinutes, inInclusiveRange(15, 60),
              reason: 'Level ${c.level} building blocks duration should be 15-60 min');
        }
      });

      test('tier 3 durations are between 120 and 360 minutes', () {
        for (final c in CommitmentCatalog.getForTier(CommitmentTier.halfDayChallenges)) {
          expect(c.durationMinutes, inInclusiveRange(120, 360),
              reason: 'Level ${c.level} half-day duration should be 120-360 min');
        }
      });

      test('tier 4 durations are between 720 and 1440 minutes', () {
        for (final c in CommitmentCatalog.getForTier(CommitmentTier.dayLong)) {
          expect(c.durationMinutes, inInclusiveRange(720, 1440),
              reason: 'Level ${c.level} day-long duration should be 720-1440 min');
        }
      });
    });

    group('xpReward progression', () {
      test('xpRewards generally increase across tiers', () {
        final tier1Avg = CommitmentCatalog.getForTier(CommitmentTier.quickWins)
            .map((c) => c.xpReward)
            .reduce((a, b) => a + b) /
            10;
        final tier4Avg = CommitmentCatalog.getForTier(CommitmentTier.dayLong)
            .map((c) => c.xpReward)
            .reduce((a, b) => a + b) /
            10;
        expect(tier4Avg > tier1Avg, true,
            reason: 'Tier 4 avg XP should be higher than tier 1');
      });
    });

    group('getByLevel', () {
      test('returns correct commitment for valid level', () {
        final c = CommitmentCatalog.getByLevel(1);
        expect(c.level, 1);
      });

      test('returns first commitment for invalid level', () {
        final c = CommitmentCatalog.getByLevel(999);
        expect(c.level, 1);
      });
    });

    group('getForTier', () {
      test('returns 10 commitments per tier', () {
        for (final tier in CommitmentTier.values) {
          final tierCommitments = CommitmentCatalog.getForTier(tier);
          expect(tierCommitments.length, 10,
              reason: '${tier.label} should have 10 commitments');
        }
      });
    });
  });
}
