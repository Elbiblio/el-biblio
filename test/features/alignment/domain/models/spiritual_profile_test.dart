import 'package:flutter_test/flutter_test.dart';
import 'package:elbiblio/features/alignment/domain/models/spiritual_profile.dart';

void main() {
  group('SpiritualProfile', () {
    late SpiritualProfile profile;
    late DateTime fixedDate;

    setUp(() {
      fixedDate = DateTime(2025, 6, 15, 10, 30);
      profile = SpiritualProfile(
        archetypeId: 'Artisan',
        archetypeName: 'The Artisan',
        description: 'Creative and expressive.',
        dimensions: const {
          'prayer': 0.7,
          'worship': 0.9,
          'service': 0.5,
          'study': 0.6,
        },
        strengths: const ['Creativity', 'Worship'],
        weaknesses: const ['Discipline', 'Consistency'],
        growthAreas: const ['Study', 'Fasting'],
        assessedAt: fixedDate,
      );
    });

    group('construction', () {
      test('creates with all required fields', () {
        expect(profile.archetypeId, 'Artisan');
        expect(profile.archetypeName, 'The Artisan');
        expect(profile.description.isNotEmpty, true);
        expect(profile.dimensions.length, 4);
        expect(profile.strengths.length, 2);
        expect(profile.weaknesses.length, 2);
        expect(profile.growthAreas.length, 2);
        expect(profile.assessedAt, fixedDate);
        expect(profile.previousProfiles, isNull);
      });

      test('previousProfiles defaults to null', () {
        expect(profile.previousProfiles, isNull);
      });
    });

    group('copyWith', () {
      test('returns identical copy when no args', () {
        final copy = profile.copyWith();
        expect(copy.archetypeId, profile.archetypeId);
        expect(copy.dimensions, profile.dimensions);
        expect(copy.strengths, profile.strengths);
      });

      test('updates specified fields', () {
        final copy = profile.copyWith(
          archetypeId: 'Watchman',
          archetypeName: 'The Watchman',
        );
        expect(copy.archetypeId, 'Watchman');
        expect(copy.archetypeName, 'The Watchman');
        expect(copy.description, profile.description);
      });
    });

    group('JSON serialization', () {
      test('toJson produces correct map', () {
        final json = profile.toJson();
        expect(json['archetypeId'], 'Artisan');
        expect(json['archetypeName'], 'The Artisan');
        expect(json['dimensions'], isA<Map>());
        expect(json['strengths'], isA<List>());
        expect(json['weaknesses'], isA<List>());
        expect(json['growthAreas'], isA<List>());
        expect(json['assessedAt'], fixedDate.toIso8601String());
        expect(json.containsKey('previousProfiles'), false);
      });

      test('toJson includes previousProfiles when present', () {
        final withHistory = profile.copyWith(
          previousProfiles: [profile],
        );
        final json = withHistory.toJson();
        expect(json.containsKey('previousProfiles'), true);
        expect((json['previousProfiles'] as List).length, 1);
      });

      test('round-trip toJson -> fromJson preserves data', () {
        final json = profile.toJson();
        final restored = SpiritualProfile.fromJson(json);
        expect(restored.archetypeId, profile.archetypeId);
        expect(restored.archetypeName, profile.archetypeName);
        expect(restored.description, profile.description);
        expect(restored.dimensions['prayer'], 0.7);
        expect(restored.dimensions['worship'], 0.9);
        expect(restored.strengths, profile.strengths);
        expect(restored.weaknesses, profile.weaknesses);
        expect(restored.growthAreas, profile.growthAreas);
        expect(restored.assessedAt, fixedDate);
        expect(restored.previousProfiles, isNull);
      });

      test('round-trip preserves previousProfiles', () {
        final withHistory = profile.copyWith(
          previousProfiles: [profile],
        );
        final json = withHistory.toJson();
        final restored = SpiritualProfile.fromJson(json);
        expect(restored.previousProfiles, isNotNull);
        expect(restored.previousProfiles!.length, 1);
        expect(restored.previousProfiles![0].archetypeId, 'Artisan');
      });
    });

    group('growthSince', () {
      test('returns positive delta when dimensions improved', () {
        final previous = SpiritualProfile(
          archetypeId: 'Artisan',
          archetypeName: 'The Artisan',
          description: 'Desc',
          dimensions: const {'prayer': 0.5, 'worship': 0.7},
          strengths: const [],
          weaknesses: const [],
          growthAreas: const [],
          assessedAt: DateTime(2025, 1, 1),
        );
        final current = SpiritualProfile(
          archetypeId: 'Artisan',
          archetypeName: 'The Artisan',
          description: 'Desc',
          dimensions: const {'prayer': 0.8, 'worship': 0.9},
          strengths: const [],
          weaknesses: const [],
          growthAreas: const [],
          assessedAt: DateTime(2025, 6, 1),
        );
        expect(current.growthSince(previous), closeTo(0.25, 0.01));
      });

      test('returns 0.0 when both dimensions are empty', () {
        final empty = SpiritualProfile(
          archetypeId: 'a',
          archetypeName: 'A',
          description: '',
          dimensions: const {},
          strengths: const [],
          weaknesses: const [],
          growthAreas: const [],
          assessedAt: DateTime(2025, 1, 1),
        );
        expect(empty.growthSince(empty), 0.0);
      });

      test('returns 0.0 when previous dimensions empty', () {
        final empty = SpiritualProfile(
          archetypeId: 'a',
          archetypeName: 'A',
          description: '',
          dimensions: const {},
          strengths: const [],
          weaknesses: const [],
          growthAreas: const [],
          assessedAt: DateTime(2025, 1, 1),
        );
        expect(profile.growthSince(empty), 0.0);
      });

      test('returns negative delta when dimensions declined', () {
        final previous = SpiritualProfile(
          archetypeId: 'a',
          archetypeName: 'A',
          description: '',
          dimensions: const {'prayer': 0.9, 'worship': 0.9},
          strengths: const [],
          weaknesses: const [],
          growthAreas: const [],
          assessedAt: DateTime(2025, 1, 1),
        );
        final current = SpiritualProfile(
          archetypeId: 'a',
          archetypeName: 'A',
          description: '',
          dimensions: const {'prayer': 0.5, 'worship': 0.5},
          strengths: const [],
          weaknesses: const [],
          growthAreas: const [],
          assessedAt: DateTime(2025, 6, 1),
        );
        expect(current.growthSince(previous), lessThan(0));
      });
    });
  });
}
