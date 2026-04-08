import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/notifications/notification_service.dart';
import '../../../core/services/xp_service.dart';
import '../../today/application/daily_anchors_notifier.dart';
import '../data/commitment_journey_repository.dart';
import '../domain/models/commitment_journey.dart';

/// State for the commitment journey feature.
class CommitmentJourneyState {
  const CommitmentJourneyState({
    this.activeJourney,
    this.availableJourneys = const [],
    this.isLoading = false,
    this.error,
    this.justStarted = false,
    this.justCompleted = false,
    this.justReachedMilestone,
  });

  final ActiveJourney? activeJourney;
  final List<CommitmentJourney> availableJourneys;
  final bool isLoading;
  final String? error;
  final bool justStarted;
  final bool justCompleted;
  final int? justReachedMilestone; // Day number of milestone just reached

  CommitmentJourneyState copyWith({
    ActiveJourney? activeJourney,
    List<CommitmentJourney>? availableJourneys,
    bool? isLoading,
    String? error,
    bool? justStarted,
    bool? justCompleted,
    int? justReachedMilestone,
    bool clearActiveJourney = false,
    bool clearError = false,
  }) {
    return CommitmentJourneyState(
      activeJourney: clearActiveJourney
          ? null
          : (activeJourney ?? this.activeJourney),
      availableJourneys: availableJourneys ?? this.availableJourneys,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      justStarted: justStarted ?? this.justStarted,
      justCompleted: justCompleted ?? this.justCompleted,
      justReachedMilestone: justReachedMilestone ?? this.justReachedMilestone,
    );
  }
}

/// Manages commitment journeys with prayer intentions, milestones, and daily check-ins.
class CommitmentJourneyNotifier extends StateNotifier<CommitmentJourneyState> {
  CommitmentJourneyNotifier({
    required this.repository,
    required this.xpService,
    required this.notificationService,
    this.dailyAnchorsNotifier,
  }) : super(const CommitmentJourneyState()) {
    _initialize();
  }

  final CommitmentJourneyRepository repository;
  final XPService xpService;
  final NotificationService notificationService;
  final DailyAnchorsNotifier? dailyAnchorsNotifier;

  Future<void> _initialize() async {
    await loadActiveJourney();
    await loadAvailableJourneys();
  }

  /// Load the currently active journey, if any.
  Future<void> loadActiveJourney() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final journey = await repository.getActiveJourney();
      state = state.copyWith(
        activeJourney: journey,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load available journeys for selection.
  Future<void> loadAvailableJourneys() async {
    try {
      final journeys = await repository.getAvailableJourneys();
      state = state.copyWith(availableJourneys: journeys);
    } catch (e) {
      log('Failed to load available journeys: $e');
    }
  }

  /// Start a new journey with a prayer intention.
  Future<void> startJourney({
    required String journeyId,
    required String prayerIntention,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final journey = await repository.startJourney(
        journeyId: journeyId,
        prayerIntention: prayerIntention,
      );

      state = state.copyWith(
        activeJourney: journey,
        isLoading: false,
        justStarted: true,
      );

      // Sync with daily anchors
      await _syncWithDailyAnchors();

      // Schedule evening check-in notifications
      // 6pm partner check-in, 8pm user fallback
      final journeyDefinition = await repository.getJourneyById(journeyId);
      await _scheduleCheckInNotifications(journeyDefinition, prayerIntention);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Check in for today - marks the current day as completed.
  /// Awards virtue growth silently.
  Future<void> checkInToday() async {
    final active = state.activeJourney;
    if (active == null) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await repository.checkInToday();
      
      // Check if we just reached a milestone
      final journey = await repository.getJourneyById(active.journeyId);
      int? milestoneReached;
      for (final milestone in journey.milestones) {
        if (updated.currentDay == milestone.day &&
            !active.milestonesReached.contains(milestone.day)) {
          milestoneReached = milestone.day;
          break;
        }
      }

      // Award virtue growth silently
      await _recordVirtueGrowth(journey, updated);

      // Show milestone notification if reached
      if (milestoneReached != null) {
        final milestone = journey.milestones.firstWhere((m) => m.day == milestoneReached);
        await notificationService.showMilestoneReachedNotification(
          journeyTitle: journey.title,
          milestoneDay: milestoneReached,
          newRequirement: milestone.newRequirement,
        );
      }

      state = state.copyWith(
        activeJourney: updated,
        isLoading: false,
        justReachedMilestone: milestoneReached,
      );

      // Check for journey completion
      if (updated.isComplete) {
        await _completeJourney(journey);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Mark a milestone as acknowledged (viewed by user).
  void acknowledgeMilestone() {
    state = state.copyWith(justReachedMilestone: null);
  }

  /// Acknowledge that we just started a journey.
  void acknowledgeStart() {
    state = state.copyWith(justStarted: false);
  }

  /// Acknowledge journey completion.
  void acknowledgeCompletion() {
    state = state.copyWith(justCompleted: false);
  }

  /// Get the full journey details for the active journey.
  Future<CommitmentJourney> getCurrentJourneyDetails() async {
    if (state.activeJourney == null) {
      throw StateError('No active journey');
    }
    return await repository.getJourneyById(state.activeJourney!.journeyId);
  }

  /// Abandon the current journey.
  Future<void> abandonJourney() async {
    final active = state.activeJourney;
    if (active == null) return;

    state = state.copyWith(isLoading: true);
    try {
      await repository.abandonJourney(active.journeyId);

      // Cancel all scheduled notifications
      await notificationService.cancelJourneyNotifications();

      state = state.copyWith(
        clearActiveJourney: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Get recommended journeys based on user's struggles and virtue focus.
  Future<List<CommitmentJourney>> getRecommendations({
    List<String>? struggles,
    String? virtueFocus,
  }) async {
    return await repository.getRecommendations(
      struggles: struggles,
      virtueFocus: virtueFocus,
    );
  }

  /// Sync the active journey with daily anchors for TodayScreen display.
  Future<void> _syncWithDailyAnchors() async {
    if (dailyAnchorsNotifier == null || state.activeJourney == null) return;

    try {
      final journey = await getCurrentJourneyDetails();
      final currentAnchors = dailyAnchorsNotifier!.state;
      
      final requirement = journey.requirementForDay(state.activeJourney!.currentDay);
      
      final updatedHabit = currentAnchors.habit.copyWith(
        commitmentTitle: journey.title,
        commitmentDescription: '$requirement\n\nIntention: ${state.activeJourney!.prayerIntention}',
        // No duration minutes for journey-based commitments - they're all-day practices
      );
      
      final updatedAnchors = currentAnchors.copyWith(habit: updatedHabit);
      await dailyAnchorsNotifier!.repository.save(updatedAnchors);
      dailyAnchorsNotifier!.state = updatedAnchors;
    } catch (e) {
      log('Failed to sync journey with daily anchors: $e');
    }
  }

  /// Record virtue growth silently (no UI mention).
  Future<void> _recordVirtueGrowth(
    CommitmentJourney journey,
    ActiveJourney active,
  ) async {
    try {
      // Award XP silently
      await xpService.addXP(
        type: XPActivityType.commitment,
        description: 'Day ${active.currentDay} of ${journey.title}',
        metadata: {
          'journeyId': journey.id,
          'day': active.currentDay,
          'virtue': journey.virtueAlignment,
          'milestoneCount': journey.milestoneCount,
        },
      );
    } catch (e) {
      log('Failed to record virtue growth: $e');
    }
  }

  /// Complete the journey and award final virtue growth.
  Future<void> _completeJourney(CommitmentJourney journey) async {
    try {
      await repository.completeJourney(journey.id);

      // Award completion XP silently
      await xpService.addXP(
        type: XPActivityType.commitment,
        description: 'Completed ${journey.title}',
        metadata: {
          'journeyId': journey.id,
          'duration': journey.duration.days,
          'virtue': journey.virtueAlignment,
        },
      );

      // Show completion notification
      await notificationService.showJourneyCompletedNotification(
        journeyTitle: journey.title,
        durationDays: journey.duration.days,
        virtueAlignment: journey.virtueAlignment,
      );

      // Cancel all scheduled check-in notifications
      await notificationService.cancelJourneyNotifications();

      state = state.copyWith(justCompleted: true);
    } catch (e) {
      log('Failed to complete journey: $e');
    }
  }

  /// Schedule evening check-in notifications.
  /// Partner is asked at 6pm, user gets fallback at 8pm if no partner response.
  Future<void> _scheduleCheckInNotifications(
    CommitmentJourney journey,
    String prayerIntention,
  ) async {
    try {
      final active = state.activeJourney;
      if (active == null) return;

      // TODO: Get partner name from user profile/settings
      // For now, schedule user reminder only
      await notificationService.scheduleUserCheckInReminder(
        journeyTitle: journey.title,
        currentDay: active.currentDay,
        totalDays: journey.duration.days,
        prayerIntention: prayerIntention,
      );

      // When partner system is implemented:
      // await notificationService.schedulePartnerCheckInRequest(...);
    } catch (e) {
      log('Failed to schedule check-in notifications: $e');
    }
  }

  /// Check if a check-in is due (after 6pm, or partner hasn't responded).
  Future<CheckInStatus> getCheckInStatus() async {
    final active = state.activeJourney;
    if (active == null) return CheckInStatus.noActiveJourney;

    final now = DateTime.now();
    final hour = now.hour;

    // Check if already checked in today
    if (active.completedDays.contains(active.currentDay)) {
      return CheckInStatus.alreadyCheckedIn;
    }

    // Before 6pm: too early
    if (hour < 18) {
      return CheckInStatus.tooEarly;
    }

    // 6pm-8pm: partner check-in window
    if (hour >= 18 && hour < 20) {
      final partnerResponded = await repository.hasPartnerRespondedToday();
      if (partnerResponded) {
        return CheckInStatus.completedByPartner;
      }
      return CheckInStatus.waitingForPartner;
    }

    // 8pm+: user can check in
    return CheckInStatus.userCanCheckIn;
  }
}

/// Status of the daily check-in flow.
enum CheckInStatus {
  noActiveJourney,
  tooEarly, // Before 6pm
  waitingForPartner, // 6pm-8pm, waiting for partner
  userCanCheckIn, // 8pm+ or no partner
  alreadyCheckedIn,
  completedByPartner,
}
