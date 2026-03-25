import 'package:flutter_test/flutter_test.dart';
import 'package:elbiblio/features/alignment/data/habit_catalog.dart';
import 'package:elbiblio/features/alignment/domain/models/habit_assessment.dart';

void main() {
  group('HabitCatalog', () {
    test('has habits in the catalog', () {
      expect(HabitCatalog.allHabits.isNotEmpty, true);
    });

    test('all habits have unique ids', () {
      final ids = HabitCatalog.allHabits.map((h) => h.id).toSet();
      expect(ids.length, HabitCatalog.allHabits.length);
    });

    test('all habits have non-empty name', () {
      for (final h in HabitCatalog.allHabits) {
        expect(h.name.isNotEmpty, true,
            reason: 'Habit ${h.id} should have a non-empty name');
      }
    });

    test('all habits have non-empty description', () {
      for (final h in HabitCatalog.allHabits) {
        expect(h.description.isNotEmpty, true,
            reason: 'Habit ${h.id} should have a non-empty description');
      }
    });

    test('all habits have non-empty relatedVirtue', () {
      for (final h in HabitCatalog.allHabits) {
        expect(h.relatedVirtue.isNotEmpty, true,
            reason: 'Habit ${h.id} should have a related virtue');
      }
    });

    test('all habits have positive severity', () {
      for (final h in HabitCatalog.allHabits) {
        expect(h.severity > 0, true,
            reason: 'Habit ${h.id} should have positive severity');
      }
    });

    group('bad and good habits', () {
      test('has both bad and good habits', () {
        expect(HabitCatalog.badHabits.isNotEmpty, true);
        expect(HabitCatalog.goodHabits.isNotEmpty, true);
      });

      test('badHabits returns only bad habits', () {
        for (final h in HabitCatalog.badHabits) {
          expect(h.isBadHabit, true,
              reason: 'Habit ${h.id} should be a bad habit');
        }
      });

      test('goodHabits returns only good habits', () {
        for (final h in HabitCatalog.goodHabits) {
          expect(h.isBadHabit, false,
              reason: 'Habit ${h.id} should be a good habit');
        }
      });

      test('bad + good habits equals total habits', () {
        expect(
          HabitCatalog.badHabits.length + HabitCatalog.goodHabits.length,
          HabitCatalog.allHabits.length,
        );
      });

      test('each bad habit has a counterHabit', () {
        for (final h in HabitCatalog.badHabits) {
          expect(h.counterHabit, isNotNull,
              reason: 'Bad habit ${h.id} should have a counter-habit');
          expect(h.counterHabit!.isNotEmpty, true,
              reason: 'Bad habit ${h.id} should have a non-empty counter-habit');
        }
      });

      test('bad habits have conquest tips', () {
        for (final h in HabitCatalog.badHabits) {
          expect(h.conquestTips.isNotEmpty, true,
              reason: 'Bad habit ${h.id} should have conquest tips');
        }
      });
    });

    group('categories', () {
      test('habits cover all HabitCategory values', () {
        final categories = HabitCatalog.allHabits.map((h) => h.category).toSet();
        for (final cat in HabitCategory.values) {
          expect(categories.contains(cat), true,
              reason: 'Category ${cat.name} should have habits');
        }
      });

      test('habitsByCategory returns only matching habits', () {
        for (final cat in HabitCategory.values) {
          final habits = HabitCatalog.habitsByCategory(cat);
          for (final h in habits) {
            expect(h.category, cat);
          }
        }
      });

      test('each category has both bad and good habits', () {
        for (final cat in HabitCategory.values) {
          final habits = HabitCatalog.habitsByCategory(cat);
          final hasBad = habits.any((h) => h.isBadHabit);
          final hasGood = habits.any((h) => !h.isBadHabit);
          expect(hasBad, true,
              reason: 'Category ${cat.name} should have bad habits');
          expect(hasGood, true,
              reason: 'Category ${cat.name} should have good habits');
        }
      });
    });

    group('findById', () {
      test('returns habit for valid id', () {
        final habit = HabitCatalog.findById('bad_sp_1');
        expect(habit, isNotNull);
        expect(habit!.id, 'bad_sp_1');
      });

      test('returns null for invalid id', () {
        expect(HabitCatalog.findById('nonexistent'), isNull);
      });
    });
  });
}
