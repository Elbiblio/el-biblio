import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/app_providers.dart';
import '../../../core/services/notifications/notification_service.dart';
import '../application/mood_notifier.dart';
import '../data/daily_anchors_repository.dart';
import '../data/daily_anchors_sync_repository.dart';
import '../domain/models/daily_anchors.dart';

class DailyAnchorsNotifier extends StateNotifier<DailyAnchors> {
  DailyAnchorsNotifier({
    required this.ref,
    required this.repository,
    required this.syncRepository,
  }) : super(DailyAnchors.empty(DateTime.now())) {
    loadToday();
    
    // Listen to virtue changes and reload anchors
    ref.listen(settingsProvider, (previous, next) {
      if (previous?.primaryVirtue != next.primaryVirtue) {
        loadToday();
      }
    });
  }

  final Ref ref;
  final DailyAnchorsRepository repository;
  final DailyAnchorsSyncRepository syncRepository;

  Future<void> loadToday() async {
    final settings = ref.read(settingsProvider);
    final anchors = await repository.getForDate(
      DateTime.now(),
      virtueType: settings.primaryVirtue,
    );
    state = anchors;
    unawaited(_syncToServer(anchors));
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
      await ref
          .read(settingsProvider.notifier)
          .registerDailyCheckIn(DateTime.now(), integrityScore: updated.integrityPoints);
    }

    if (completed) {
      // Trigger loop closure: gently reset mood to neutral after completion
      // We use a slight delay to allow the user to see the checkmark animation first
      Future.delayed(const Duration(seconds: 2), () {
        ref.read(moodProvider.notifier).resetToNeutral();
      });
    }

    unawaited(_syncToServer(updated));
  }

  Future<void> startCommitment() async {
    final now = DateTime.now();
    final updatedHabit = state.habit.copyWith(
      commitmentStartTime: now,
    );
    
    final updatedAnchors = state.copyWith(habit: updatedHabit);
    await repository.save(updatedAnchors);
    state = updatedAnchors;
    unawaited(_syncToServer(updatedAnchors));
  }

  Future<void> lockInCommitment() async {
    debugPrint('DailyAnchorsNotifier: lockInCommitment called');
    final now = DateTime.now();
    final updatedHabit = state.habit.copyWith(
      commitmentLockedTime: now,
      isLockedIn: true,
    );
    
    debugPrint('DailyAnchorsNotifier: Updated habit with lock-in time');
    final updatedAnchors = state.copyWith(habit: updatedHabit);
    await repository.save(updatedAnchors);
    state = updatedAnchors;
    unawaited(_syncToServer(updatedAnchors));

    debugPrint('DailyAnchorsNotifier: Showing commitment lock-in notification');
    // Show music player style commitment notification
    final notificationService = NotificationService();
    await notificationService.showCommitmentLockInNotification(
      commitmentTitle: updatedHabit.displayTitle,
      virtueType: state.coreVirtue.type,
    );
    debugPrint('DailyAnchorsNotifier: Commitment lock-in notification sent');
  }

  Future<void> completeCommitment({bool succeeded = true}) async {
    final now = DateTime.now();
    final updatedHabit = state.habit.copyWith(
      commitmentCompletedTime: now,
      isCompleted: succeeded,
    );
    
    final updatedAnchors = state.copyWith(habit: updatedHabit);
    await repository.save(updatedAnchors);
    state = updatedAnchors;
    unawaited(_syncToServer(updatedAnchors));

    // Cancel the commitment lock-in notification
    final notificationService = NotificationService();
    await notificationService.cancelCommitmentLockInNotification();

    if (succeeded) {
      // Trigger mood reset after successful completion
      Future.delayed(const Duration(seconds: 2), () {
        ref.read(moodProvider.notifier).resetToNeutral();
      });
    }
  }

  Future<void> refreshForNewDay() async {
    await loadToday();
  }

  Future<int> getConsecutiveMissedDays() async {
    return await repository.getConsecutiveMissedDays();
  }

  Future<void> addSpiritualPulse({
    required SpiritualPulseType type,
    required String note,
    double intensity = 1.0,
    String? goingWell,
    String? struggling,
    String? needHelp,
    String? followUpQuestion,
    String? followUpAnswer,
    String? virtueFocus,
  }) async {
    // This would typically be handled by a separate spiritual pulse service
    // For now, we'll just log it and potentially integrate with daily anchors
    debugPrint('Spiritual pulse added: ${type.name} - $note');
    
    // Could potentially trigger some UI update or notification here
    // For example, updating a mood indicator or triggering a reflection prompt
  }

  Future<void> _syncToServer(DailyAnchors anchors) async {
    final synced = await syncRepository.syncAnchors(anchors);
    if (!synced) {
      debugPrint('DailyAnchorsNotifier: deferred server sync for ${anchors.date.toIso8601String()}');
    }
  }
}
