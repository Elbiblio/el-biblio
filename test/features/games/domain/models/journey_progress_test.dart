import 'package:flutter_test/flutter_test.dart';
import 'package:elbiblio/features/games/domain/models/journey_progress.dart';

void main() {
  group('EventResult', () {
    late EventResult result;

    setUp(() {
      result = EventResult(
        eventOrder: 0,
        correctAnswers: 3,
        scoreEarned: 15,
        completedAt: DateTime(2025, 6, 15),
      );
    });

    test('isPerfect is true when correctAnswers is 3', () {
      expect(result.isPerfect, true);
    });

    test('isPerfect is false when correctAnswers is not 3', () {
      final imperfect = EventResult(
        eventOrder: 0,
        correctAnswers: 2,
        scoreEarned: 10,
        completedAt: DateTime(2025, 6, 15),
      );
      expect(imperfect.isPerfect, false);
    });

    test('JSON round-trip preserves data', () {
      final json = result.toJson();
      final restored = EventResult.fromJson(json);
      expect(restored.eventOrder, result.eventOrder);
      expect(restored.correctAnswers, result.correctAnswers);
      expect(restored.scoreEarned, result.scoreEarned);
      expect(restored.completedAt, result.completedAt);
    });

    test('fromJson handles missing fields with defaults', () {
      final restored = EventResult.fromJson({});
      expect(restored.eventOrder, 0);
      expect(restored.correctAnswers, 0);
      expect(restored.scoreEarned, 0);
    });
  });

  group('JourneyProgress', () {
    group('construction and defaults', () {
      test('default values are correct', () {
        final progress = JourneyProgress(startedAt: DateTime(2025, 6, 15));
        expect(progress.currentEvent, 0);
        expect(progress.completedEvents, isEmpty);
        expect(progress.totalScore, 0);
        expect(progress.totalXpEarned, 0);
        expect(progress.perfectAnswers, 0);
        expect(progress.completedAt, isNull);
      });

      test('initial factory creates with defaults', () {
        final progress = JourneyProgress.initial();
        expect(progress.currentEvent, 0);
        expect(progress.completedEvents, isEmpty);
      });
    });

    group('computed properties', () {
      test('overallProgress is 0 when no events completed', () {
        final progress = JourneyProgress(startedAt: DateTime(2025, 6, 15));
        expect(progress.overallProgress, 0.0);
      });

      test('overallProgress is 0.5 at 15 completed events', () {
        final completed = <int, EventResult>{};
        for (int i = 0; i < 15; i++) {
          completed[i] = EventResult(
            eventOrder: i,
            correctAnswers: 3,
            scoreEarned: 15,
            completedAt: DateTime(2025, 6, 15),
          );
        }
        final progress = JourneyProgress(
          startedAt: DateTime(2025, 6, 15),
          completedEvents: completed,
        );
        expect(progress.overallProgress, 0.5);
      });

      test('overallProgress is 1.0 at 30 completed events', () {
        final completed = <int, EventResult>{};
        for (int i = 0; i < 30; i++) {
          completed[i] = EventResult(
            eventOrder: i,
            correctAnswers: 3,
            scoreEarned: 15,
            completedAt: DateTime(2025, 6, 15),
          );
        }
        final progress = JourneyProgress(
          startedAt: DateTime(2025, 6, 15),
          completedEvents: completed,
        );
        expect(progress.overallProgress, 1.0);
      });

      test('isComplete is false when under 30 events', () {
        final progress = JourneyProgress(startedAt: DateTime(2025, 6, 15));
        expect(progress.isComplete, false);
      });

      test('isComplete is true at 30 events', () {
        final completed = <int, EventResult>{};
        for (int i = 0; i < 30; i++) {
          completed[i] = EventResult(
            eventOrder: i,
            correctAnswers: 3,
            scoreEarned: 15,
            completedAt: DateTime(2025, 6, 15),
          );
        }
        final progress = JourneyProgress(
          startedAt: DateTime(2025, 6, 15),
          completedEvents: completed,
        );
        expect(progress.isComplete, true);
      });
    });

    group('copyWith', () {
      test('returns identical copy when no args', () {
        final progress = JourneyProgress(
          startedAt: DateTime(2025, 6, 15),
          currentEvent: 5,
          totalScore: 100,
        );
        final copy = progress.copyWith();
        expect(copy.currentEvent, 5);
        expect(copy.totalScore, 100);
      });

      test('updates specified fields', () {
        final progress = JourneyProgress(startedAt: DateTime(2025, 6, 15));
        final copy = progress.copyWith(currentEvent: 10, totalScore: 200);
        expect(copy.currentEvent, 10);
        expect(copy.totalScore, 200);
      });
    });

    group('JSON serialization', () {
      test('round-trip preserves all fields', () {
        final startDate = DateTime(2025, 6, 15);
        final completeDate = DateTime(2025, 7, 15);
        final completed = <int, EventResult>{
          0: EventResult(
            eventOrder: 0,
            correctAnswers: 3,
            scoreEarned: 15,
            completedAt: startDate,
          ),
          1: EventResult(
            eventOrder: 1,
            correctAnswers: 2,
            scoreEarned: 10,
            completedAt: startDate,
          ),
        };
        final progress = JourneyProgress(
          currentEvent: 2,
          completedEvents: completed,
          totalScore: 25,
          totalXpEarned: 30,
          perfectAnswers: 1,
          startedAt: startDate,
          completedAt: completeDate,
        );

        final json = progress.toJson();
        final restored = JourneyProgress.fromJson(json);

        expect(restored.currentEvent, 2);
        expect(restored.completedEvents.length, 2);
        expect(restored.completedEvents[0]!.correctAnswers, 3);
        expect(restored.completedEvents[1]!.correctAnswers, 2);
        expect(restored.totalScore, 25);
        expect(restored.totalXpEarned, 30);
        expect(restored.perfectAnswers, 1);
        expect(restored.startedAt, startDate);
        expect(restored.completedAt, completeDate);
      });

      test('fromJson handles missing fields with defaults', () {
        final restored = JourneyProgress.fromJson({});
        expect(restored.currentEvent, 0);
        expect(restored.completedEvents, isEmpty);
        expect(restored.totalScore, 0);
        expect(restored.completedAt, isNull);
      });

      test('completedEvents map keys are serialized as strings', () {
        final progress = JourneyProgress(
          startedAt: DateTime(2025, 6, 15),
          completedEvents: {
            0: EventResult(
              eventOrder: 0,
              correctAnswers: 3,
              scoreEarned: 15,
              completedAt: DateTime(2025, 6, 15),
            ),
          },
        );
        final json = progress.toJson();
        final completedMap = json['completedEvents'] as Map;
        expect(completedMap.containsKey('0'), true);
      });
    });
  });
}
