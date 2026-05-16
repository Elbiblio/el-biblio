import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../domain/models/jesus_journey_event.dart';
import '../domain/models/journey_progress.dart';
import 'jesus_journey_catalog.dart';

class JourneyRepository {
  static const String _boxName = 'journey_progress';
  static const String _progressKey = 'current_progress';

  Box<dynamic>? _box;

  Future<Box<dynamic>> _getBox() async {
    _box ??= await Hive.openBox<dynamic>(_boxName);
    return _box!;
  }

  Future<JourneyProgress> getProgress() async {
    final box = await _getBox();
    final raw = box.get(_progressKey);
    if (raw == null) return JourneyProgress.initial();
    try {
      final map = Map<String, dynamic>.from(
        raw is String ? json.decode(raw) as Map : raw as Map,
      );
      return JourneyProgress.fromJson(map);
    } catch (_) {
      return JourneyProgress.initial();
    }
  }

  Future<void> saveProgress(JourneyProgress progress) async {
    final box = await _getBox();
    await box.put(_progressKey, json.encode(progress.toJson()));
  }

  JesusJourneyEvent getEvent(int order) {
    return JesusJourneyCatalog.getEvent(order);
  }

  List<JesusJourneyEvent> getAllEvents() {
    return JesusJourneyCatalog.allEvents;
  }

  Future<void> completeEvent(int order, EventResult result) async {
    final progress = await getProgress();
    final newCompleted = Map<int, EventResult>.from(progress.completedEvents);
    newCompleted[order] = result;

    final newScore = newCompleted.values.fold<int>(
      0,
      (sum, result) => sum + result.scoreEarned,
    );
    final newXp = newCompleted.keys.fold<int>(
      0,
      (sum, eventOrder) => sum + getEvent(eventOrder).xpReward,
    );
    final newPerfect = newCompleted.values
        .where((result) => result.isPerfect)
        .length;

    var nextEvent = 29;
    for (var i = 0; i < JesusJourneyCatalog.allEvents.length; i++) {
      if (!newCompleted.containsKey(i)) {
        nextEvent = i;
        break;
      }
    }

    final isComplete =
        newCompleted.length >= JesusJourneyCatalog.allEvents.length;
    final updated = progress.copyWith(
      currentEvent: nextEvent,
      completedEvents: newCompleted,
      totalScore: newScore,
      totalXpEarned: newXp,
      perfectAnswers: newPerfect,
      completedAt: isComplete ? progress.completedAt ?? DateTime.now() : null,
    );

    await saveProgress(updated);
  }

  Future<void> resetJourney() async {
    await saveProgress(JourneyProgress.initial());
  }
}
