import 'package:flutter_test/flutter_test.dart';
import 'package:elbiblio/features/alignment/domain/models/habit_assessment.dart';

void main() {
  group('HabitCategory', () {
    test('has exactly 5 values', () {
      expect(HabitCategory.values.length, 5);
    });

    test('contains expected categories', () {
      expect(HabitCategory.values, contains(HabitCategory.spiritual));
      expect(HabitCategory.values, contains(HabitCategory.mental));
      expect(HabitCategory.values, contains(HabitCategory.physical));
      expect(HabitCategory.values, contains(HabitCategory.relational));
      expect(HabitCategory.values, contains(HabitCategory.digital));
    });

    test('all categories have non-empty labels', () {
      for (final cat in HabitCategory.values) {
        expect(cat.label.isNotEmpty, true,
            reason: '${cat.name} should have a non-empty label');
      }
    });

    test('labels are capitalized', () {
      for (final cat in HabitCategory.values) {
        expect(cat.label[0], cat.label[0].toUpperCase(),
            reason: '${cat.name} label should be capitalized');
      }
    });
  });

  group('HabitItem', () {
    late HabitItem badHabit;
    late HabitItem goodHabit;

    setUp(() {
      badHabit = const HabitItem(
        id: 'bad_sp_1',
        name: 'Neglecting Prayer',
        description: 'Going days without meaningful prayer.',
        category: HabitCategory.spiritual,
        isBadHabit: true,
        counterHabit: 'Set a daily 5-minute prayer alarm.',
        severity: 4,
        relatedVirtue: 'Faith',
        conquestTips: ['Start with gratitude prayers.', 'Use the ACTS model.'],
      );

      goodHabit = const HabitItem(
        id: 'good_sp_1',
        name: 'Morning Prayer',
        description: 'Begin each day with intentional prayer.',
        category: HabitCategory.spiritual,
        isBadHabit: false,
        severity: 1,
        relatedVirtue: 'Faith',
      );
    });

    group('construction', () {
      test('bad habit has all fields', () {
        expect(badHabit.id, 'bad_sp_1');
        expect(badHabit.name, 'Neglecting Prayer');
        expect(badHabit.isBadHabit, true);
        expect(badHabit.counterHabit, isNotNull);
        expect(badHabit.severity, 4);
        expect(badHabit.conquestTips.length, 2);
      });

      test('good habit has default values', () {
        expect(goodHabit.isBadHabit, false);
        expect(goodHabit.counterHabit, isNull);
        expect(goodHabit.isActive, false);
        expect(goodHabit.currentStreak, 0);
        expect(goodHabit.lastCheckIn, isNull);
      });
    });

    group('copyWith', () {
      test('returns identical copy when no args', () {
        final copy = badHabit.copyWith();
        expect(copy.id, badHabit.id);
        expect(copy.name, badHabit.name);
        expect(copy.isBadHabit, badHabit.isBadHabit);
      });

      test('updates isActive and currentStreak', () {
        final copy = badHabit.copyWith(isActive: true, currentStreak: 5);
        expect(copy.isActive, true);
        expect(copy.currentStreak, 5);
        expect(copy.id, badHabit.id);
      });
    });

    group('JSON serialization', () {
      test('toJson produces correct map', () {
        final json = badHabit.toJson();
        expect(json['id'], 'bad_sp_1');
        expect(json['name'], 'Neglecting Prayer');
        expect(json['category'], 'spiritual');
        expect(json['isBadHabit'], true);
        expect(json['counterHabit'], isNotNull);
        expect(json['severity'], 4);
        expect(json['conquestTips'], isA<List>());
        expect(json['isActive'], false);
        expect(json['currentStreak'], 0);
        expect(json['lastCheckIn'], isNull);
      });

      test('round-trip toJson -> fromJson preserves bad habit data', () {
        final json = badHabit.toJson();
        final restored = HabitItem.fromJson(json);
        expect(restored.id, badHabit.id);
        expect(restored.name, badHabit.name);
        expect(restored.description, badHabit.description);
        expect(restored.category, badHabit.category);
        expect(restored.isBadHabit, true);
        expect(restored.counterHabit, badHabit.counterHabit);
        expect(restored.severity, badHabit.severity);
        expect(restored.relatedVirtue, badHabit.relatedVirtue);
        expect(restored.conquestTips, badHabit.conquestTips);
      });

      test('round-trip preserves good habit data', () {
        final json = goodHabit.toJson();
        final restored = HabitItem.fromJson(json);
        expect(restored.id, goodHabit.id);
        expect(restored.isBadHabit, false);
        expect(restored.counterHabit, isNull);
      });

      test('fromJson handles missing optional fields', () {
        final json = {
          'id': 'test',
          'name': 'Test',
          'description': 'Desc',
          'category': 'spiritual',
          'isBadHabit': false,
          'severity': 1,
          'relatedVirtue': 'Faith',
        };
        final restored = HabitItem.fromJson(json);
        expect(restored.conquestTips, isEmpty);
        expect(restored.isActive, false);
        expect(restored.currentStreak, 0);
        expect(restored.lastCheckIn, isNull);
      });

      test('round-trip preserves lastCheckIn', () {
        final withCheckIn = badHabit.copyWith(
          lastCheckIn: DateTime(2025, 6, 15),
          isActive: true,
          currentStreak: 3,
        );
        final json = withCheckIn.toJson();
        final restored = HabitItem.fromJson(json);
        expect(restored.lastCheckIn, DateTime(2025, 6, 15));
        expect(restored.isActive, true);
        expect(restored.currentStreak, 3);
      });
    });
  });

  group('SelfAssessmentQuestion', () {
    test('constructs with required fields', () {
      const q = SelfAssessmentQuestion(
        id: 'q_sp_1',
        question: 'I often go several days without praying.',
        category: HabitCategory.spiritual,
        relatedHabitIds: ['bad_sp_1'],
      );
      expect(q.id, 'q_sp_1');
      expect(q.question.isNotEmpty, true);
      expect(q.category, HabitCategory.spiritual);
      expect(q.relatedHabitIds, ['bad_sp_1']);
    });
  });
}
