import 'package:flutter_test/flutter_test.dart';
import 'package:elbiblio/features/alignment/data/forty_day_templates.dart';

void main() {
  group('FortyDayTemplates', () {
    test('has templates available', () {
      final templates = FortyDayTemplates.allTemplates;
      expect(templates.isNotEmpty, true);
    });

    test('has exactly 6 templates', () {
      expect(FortyDayTemplates.allTemplates.length, 6);
    });

    test('all templates have unique ids', () {
      final ids = FortyDayTemplates.allTemplates.map((t) => t.id).toSet();
      expect(ids.length, FortyDayTemplates.allTemplates.length);
    });

    test('all templates have non-empty title', () {
      for (final t in FortyDayTemplates.allTemplates) {
        expect(t.title.isNotEmpty, true,
            reason: 'Template ${t.id} should have a non-empty title');
      }
    });

    test('all templates have non-empty category', () {
      for (final t in FortyDayTemplates.allTemplates) {
        expect(t.category.isNotEmpty, true,
            reason: 'Template ${t.id} should have a non-empty category');
      }
    });

    test('all templates have non-empty description', () {
      for (final t in FortyDayTemplates.allTemplates) {
        expect(t.description.isNotEmpty, true,
            reason: 'Template ${t.id} should have a non-empty description');
      }
    });

    test('all templates have exactly 40 daily tasks', () {
      for (final t in FortyDayTemplates.allTemplates) {
        expect(t.dailyTasks.length, 40,
            reason:
                'Template ${t.id} (${t.title}) should have 40 tasks, got ${t.dailyTasks.length}');
      }
    });

    test('all daily tasks have sequential day numbers 1-40', () {
      for (final t in FortyDayTemplates.allTemplates) {
        for (int i = 0; i < 40; i++) {
          expect(t.dailyTasks[i].dayNumber, i + 1,
              reason:
                  'Template ${t.id}, task $i should have dayNumber ${i + 1}');
        }
      }
    });

    test('all daily tasks have non-empty title', () {
      for (final t in FortyDayTemplates.allTemplates) {
        for (final task in t.dailyTasks) {
          expect(task.title.isNotEmpty, true,
              reason:
                  'Template ${t.id}, day ${task.dayNumber} should have a title');
        }
      }
    });

    test('all daily tasks have non-empty description', () {
      for (final t in FortyDayTemplates.allTemplates) {
        for (final task in t.dailyTasks) {
          expect(task.description.isNotEmpty, true,
              reason:
                  'Template ${t.id}, day ${task.dayNumber} should have a description');
        }
      }
    });

    test('all daily tasks have positive durationMinutes', () {
      for (final t in FortyDayTemplates.allTemplates) {
        for (final task in t.dailyTasks) {
          expect(task.durationMinutes > 0, true,
              reason:
                  'Template ${t.id}, day ${task.dayNumber} should have positive duration');
        }
      }
    });

    test('all daily tasks have non-empty reflectionPrompt', () {
      for (final t in FortyDayTemplates.allTemplates) {
        for (final task in t.dailyTasks) {
          expect(task.reflectionPrompt.isNotEmpty, true,
              reason:
                  'Template ${t.id}, day ${task.dayNumber} should have a reflection prompt');
        }
      }
    });

    test('all daily tasks have non-empty relatedVerse', () {
      for (final t in FortyDayTemplates.allTemplates) {
        for (final task in t.dailyTasks) {
          expect(task.relatedVerse.isNotEmpty, true,
              reason:
                  'Template ${t.id}, day ${task.dayNumber} should have a related verse');
        }
      }
    });

    test('templates have valid date ranges', () {
      for (final t in FortyDayTemplates.allTemplates) {
        expect(t.endDate.isAfter(t.startDate), true,
            reason: 'Template ${t.id} endDate should be after startDate');
      }
    });

    test('templates default to notStarted status', () {
      for (final t in FortyDayTemplates.allTemplates) {
        expect(t.completions, isEmpty,
            reason: 'Template ${t.id} should have no completions');
      }
    });
  });
}
