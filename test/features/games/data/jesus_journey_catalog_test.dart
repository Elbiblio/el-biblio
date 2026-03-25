import 'package:flutter_test/flutter_test.dart';
import 'package:elbiblio/features/games/data/jesus_journey_catalog.dart';

void main() {
  group('JesusJourneyCatalog', () {
    test('has exactly 30 events', () {
      expect(JesusJourneyCatalog.allEvents.length, 30);
    });

    test('events are in chronological order 0-29', () {
      final events = JesusJourneyCatalog.allEvents;
      for (int i = 0; i < events.length; i++) {
        expect(events[i].order, i,
            reason: 'Expected order $i at index $i, got ${events[i].order}');
      }
    });

    test('all events have unique ids', () {
      final ids = JesusJourneyCatalog.allEvents.map((e) => e.id).toSet();
      expect(ids.length, 30);
    });

    test('all events have non-empty title', () {
      for (final e in JesusJourneyCatalog.allEvents) {
        expect(e.title.isNotEmpty, true,
            reason: 'Event ${e.order} should have a non-empty title');
      }
    });

    test('all events have non-empty subtitle', () {
      for (final e in JesusJourneyCatalog.allEvents) {
        expect(e.subtitle.isNotEmpty, true,
            reason: 'Event ${e.order} should have a non-empty subtitle');
      }
    });

    test('all events have non-empty narrative', () {
      for (final e in JesusJourneyCatalog.allEvents) {
        expect(e.narrative.isNotEmpty, true,
            reason: 'Event ${e.order} should have a non-empty narrative');
      }
    });

    test('all events have biblical references', () {
      for (final e in JesusJourneyCatalog.allEvents) {
        expect(e.bibleReference.isNotEmpty, true,
            reason: 'Event ${e.order} should have a bible reference');
        expect(e.keyVerse.isNotEmpty, true,
            reason: 'Event ${e.order} should have a key verse');
        expect(e.keyVerseReference.isNotEmpty, true,
            reason: 'Event ${e.order} should have a key verse reference');
      }
    });

    test('all events have non-empty spiritualTakeaway', () {
      for (final e in JesusJourneyCatalog.allEvents) {
        expect(e.spiritualTakeaway.isNotEmpty, true,
            reason: 'Event ${e.order} should have a spiritual takeaway');
      }
    });

    test('all events have non-empty iconName', () {
      for (final e in JesusJourneyCatalog.allEvents) {
        expect(e.iconName.isNotEmpty, true,
            reason: 'Event ${e.order} should have an icon name');
      }
    });

    test('all events have positive xpReward', () {
      for (final e in JesusJourneyCatalog.allEvents) {
        expect(e.xpReward > 0, true,
            reason: 'Event ${e.order} should have positive xpReward');
      }
    });

    group('questions', () {
      test('all events have exactly 3 questions', () {
        for (final e in JesusJourneyCatalog.allEvents) {
          expect(e.questions.length, 3,
              reason:
                  'Event ${e.order} (${e.title}) should have 3 questions, got ${e.questions.length}');
        }
      });

      test('all questions have non-empty question text', () {
        for (final e in JesusJourneyCatalog.allEvents) {
          for (int i = 0; i < e.questions.length; i++) {
            expect(e.questions[i].question.isNotEmpty, true,
                reason: 'Event ${e.order}, question $i should have text');
          }
        }
      });

      test('all questions have at least 2 options', () {
        for (final e in JesusJourneyCatalog.allEvents) {
          for (int i = 0; i < e.questions.length; i++) {
            expect(e.questions[i].options.length, greaterThanOrEqualTo(2),
                reason:
                    'Event ${e.order}, question $i should have at least 2 options');
          }
        }
      });

      test('all questions have valid correctIndex within options range', () {
        for (final e in JesusJourneyCatalog.allEvents) {
          for (int i = 0; i < e.questions.length; i++) {
            final q = e.questions[i];
            expect(q.correctIndex, greaterThanOrEqualTo(0),
                reason:
                    'Event ${e.order}, question $i correctIndex should be >= 0');
            expect(q.correctIndex, lessThan(q.options.length),
                reason:
                    'Event ${e.order}, question $i correctIndex ${q.correctIndex} should be < options.length ${q.options.length}');
          }
        }
      });

      test('all questions have non-empty explanation', () {
        for (final e in JesusJourneyCatalog.allEvents) {
          for (int i = 0; i < e.questions.length; i++) {
            expect(e.questions[i].explanation.isNotEmpty, true,
                reason: 'Event ${e.order}, question $i should have an explanation');
          }
        }
      });

      test('no question has empty options', () {
        for (final e in JesusJourneyCatalog.allEvents) {
          for (int i = 0; i < e.questions.length; i++) {
            for (int j = 0; j < e.questions[i].options.length; j++) {
              expect(e.questions[i].options[j].isNotEmpty, true,
                  reason:
                      'Event ${e.order}, question $i, option $j should not be empty');
            }
          }
        }
      });
    });

    group('getEvent', () {
      test('returns correct event for valid order', () {
        final event = JesusJourneyCatalog.getEvent(0);
        expect(event.order, 0);
      });

      test('returns first event for invalid order', () {
        final event = JesusJourneyCatalog.getEvent(999);
        expect(event.order, 0);
      });
    });
  });
}
