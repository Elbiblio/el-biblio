import 'dart:io';

import 'package:elbiblio/features/games/data/jesus_journey_catalog.dart';
import 'package:elbiblio/features/games/data/journey_repository.dart';
import 'package:elbiblio/features/games/domain/models/journey_progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory hiveDir;

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('journey_repository_test_');
    Hive.init(hiveDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDir.existsSync()) {
      await hiveDir.delete(recursive: true);
    }
  });

  group('JourneyRepository', () {
    test('completing an event advances to the next incomplete event', () async {
      final repository = JourneyRepository();

      await repository.completeEvent(
        0,
        EventResult(
          eventOrder: 0,
          correctAnswers: 3,
          scoreEarned: 300,
          completedAt: DateTime(2026, 1, 1),
        ),
      );

      final progress = await repository.getProgress();

      expect(progress.currentEvent, 1);
      expect(progress.completedEvents.keys, contains(0));
      expect(progress.totalScore, 300);
      expect(progress.totalXpEarned, JesusJourneyCatalog.getEvent(0).xpReward);
      expect(progress.perfectAnswers, 1);
    });

    test(
      'replaying an event replaces totals instead of inflating them',
      () async {
        final repository = JourneyRepository();

        await repository.completeEvent(
          0,
          EventResult(
            eventOrder: 0,
            correctAnswers: 3,
            scoreEarned: 300,
            completedAt: DateTime(2026, 1, 1),
          ),
        );
        await repository.completeEvent(
          0,
          EventResult(
            eventOrder: 0,
            correctAnswers: 2,
            scoreEarned: 100,
            completedAt: DateTime(2026, 1, 2),
          ),
        );

        final progress = await repository.getProgress();

        expect(progress.currentEvent, 1);
        expect(progress.completedEvents.length, 1);
        expect(progress.completedEvents[0]!.correctAnswers, 2);
        expect(progress.totalScore, 100);
        expect(
          progress.totalXpEarned,
          JesusJourneyCatalog.getEvent(0).xpReward,
        );
        expect(progress.perfectAnswers, 0);
      },
    );
  });
}
