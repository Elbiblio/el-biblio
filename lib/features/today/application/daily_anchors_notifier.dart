import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/app_providers.dart';
import '../application/mood_notifier.dart';
import '../data/daily_anchors_repository.dart';
import '../domain/models/daily_anchors.dart';

class DailyAnchorsNotifier extends StateNotifier<DailyAnchors> {
  DailyAnchorsNotifier({
    required this.ref,
    required this.repository,
  }) : super(DailyAnchors.empty(DateTime.now())) {
    loadToday();
  }

  final Ref ref;
  final DailyAnchorsRepository repository;

  Future<void> loadToday() async {
    final settings = ref.read(settingsProvider);
    final anchors = await repository.getForDate(
      DateTime.now(),
      virtueType: settings.primaryVirtue,
    );
    state = anchors;
  }

  Future<void> markAnchorDone(AnchorType type, {bool completed = true}) async {
    final settings = ref.read(settingsProvider);
    final updated = await repository.updateCompletion(
      DateTime.now(),
      fallbackVirtue: settings.primaryVirtue,
      type: type,
      isCompleted: completed,
    );

    state = updated;

    if (updated.isCompleted) {
      await ref.read(settingsProvider.notifier).registerDailyCheckIn(DateTime.now());
    }

    if (completed) {
      // Trigger loop closure: gently reset mood to neutral after completion
      // We use a slight delay to allow the user to see the checkmark animation first
      Future.delayed(const Duration(seconds: 2), () {
        ref.read(moodProvider.notifier).resetToNeutral();
      });
    }
  }

  Future<void> refreshForNewDay() async {
    await loadToday();
  }
}
