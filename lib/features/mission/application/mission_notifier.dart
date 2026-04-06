import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/application/settings_notifier.dart';
import '../../../core/services/analytics/app_analytics_service.dart';
import '../../../core/services/notifications/notification_service.dart';
import '../../../core/storage/app_settings.dart';
import '../domain/models/check_in_request.dart';
import '../domain/models/accountability_partner.dart';
import '../domain/models/mission_action.dart';
import '../domain/models/mission_focus.dart';
import '../domain/models/person_profile.dart';
import 'mission_state.dart';

class MissionNotifier extends StateNotifier<MissionState> {
  MissionNotifier({
    required SettingsNotifier settingsNotifier,
    required AppAnalyticsService analytics,
    required NotificationService notificationService,
    required AppSettings initialSettings,
  })  : _settingsNotifier = settingsNotifier,
        _analytics = analytics,
        _notificationService = notificationService,
        _uuid = const Uuid(),
        super(_stateFromSettings(initialSettings));

  final SettingsNotifier _settingsNotifier;
  final AppAnalyticsService _analytics;
  final NotificationService _notificationService;
  final Uuid _uuid;

  static MissionState _stateFromSettings(AppSettings settings) {
    return MissionState(
      focus: MissionFocusTypeX.fromStorage(settings.primaryMissionFocus),
      actions: settings.missionActions,
      accountabilityPartner: settings.accountabilityPartner,
    );
  }

  void syncFromSettings(AppSettings settings) {
    state = _stateFromSettings(settings);
  }

  Future<void> setFocus(MissionFocusType focus) async {
    if (state.focus == focus) {
      return;
    }

    state = state.copyWith(focus: focus);
    await _settingsNotifier.setPrimaryMissionFocus(focus.name);
    _analytics.track(
      AppAnalyticsEvent.missionFocusSelected,
      properties: {
        'focus': focus.name,
      },
    );
  }

  Future<void> addAction({
    required String title,
    required String description,
    String? personName,
    String? notes,
    bool requiresFollowUp = false,
    String? evangelismContentId,
  }) async {
    final action = MissionAction(
      id: _uuid.v4(),
      title: title,
      description: description,
      focus: state.focus,
      createdAt: DateTime.now(),
      personName: personName,
      notes: notes,
      requiresFollowUp: requiresFollowUp,
      evangelismContentId: evangelismContentId,
    );

    final actions = [action, ...state.actions];
    final profiles = _syncPersonProfileForName(personName);
    state = state.copyWith(actions: actions);
    await _settingsNotifier.setMissionActions(actions);
    if (profiles != null) {
      await _settingsNotifier.setPersonProfiles(profiles);
    }
    _analytics.track(
      AppAnalyticsEvent.missionActionCreated,
      properties: {
        'focus': action.focus.name,
        'requires_follow_up': action.requiresFollowUp,
        'has_person': (action.personName ?? '').isNotEmpty,
      },
    );
  }

  Future<void> toggleCompleted(MissionAction action) async {
    final wasCompleted = action.isCompleted;
    final updated = wasCompleted
        ? action.copyWith(completedAt: null)
        : action.copyWith(completedAt: DateTime.now());

    final actions = state.actions
        .map((item) => item.id == action.id ? updated : item)
        .toList();

    state = state.copyWith(actions: actions);
    await _settingsNotifier.setMissionActions(actions);
    await _syncWeeklyPlanProgress(updated, increment: !wasCompleted);

    if (!wasCompleted) {
      // Schedule follow-up reminder if needed
      if (updated.requiresFollowUp && updated.completedAt != null) {
        await _scheduleFollowUpReminder(updated);
      }

      _analytics.track(
        AppAnalyticsEvent.missionActionCompleted,
        properties: {
          'focus': action.focus.name,
          'requires_follow_up': action.requiresFollowUp,
          'has_partner': state.accountabilityPartner != null,
        },
      );
    }
  }

  Future<void> savePersonProfile({
    String? profileId,
    required String name,
    required String relationship,
    String? contactInfo,
    String? notes,
  }) async {
    final trimmedName = name.trim();
    final trimmedRelationship = relationship.trim();
    if (trimmedName.isEmpty || trimmedRelationship.isEmpty) {
      return;
    }

    final profiles = [..._settingsNotifier.state.personProfiles];
    final index = profileId == null
        ? -1
        : profiles.indexWhere((profile) => profile.id == profileId);

    if (index == -1) {
      profiles.insert(
        0,
        PersonProfile.create(
          name: trimmedName,
          relationship: trimmedRelationship,
          contactInfo: _cleanOptional(contactInfo),
          notes: _cleanOptional(notes),
        ),
      );
      await _settingsNotifier.setPersonProfiles(profiles);
      return;
    }

    final previous = profiles[index];
    profiles[index] = previous.copyWith(
      name: trimmedName,
      relationship: trimmedRelationship,
      contactInfo: _cleanOptional(contactInfo),
      notes: _cleanOptional(notes),
      lastInteractionAt: DateTime.now(),
    );

    final actions = state.actions
        .map(
          (action) => action.personName == previous.name
              ? action.copyWith(personName: trimmedName)
              : action,
        )
        .toList();

    state = state.copyWith(actions: actions);
    await _settingsNotifier.setMissionActions(actions);
    await _settingsNotifier.setPersonProfiles(profiles);
  }

  Future<void> deletePersonProfile(String profileId) async {
    final profiles = _settingsNotifier.state.personProfiles
        .where((profile) => profile.id != profileId)
        .toList();
    await _settingsNotifier.setPersonProfiles(profiles);
  }

  Future<void> _scheduleFollowUpReminder(MissionAction action) async {
    try {
      final followUpDate = action.completedAt!.add(const Duration(days: 3));
      final personName = action.personName ?? 'someone';
      
      await _notificationService.scheduleNotificationWithActions(
        id: _generateNotificationId(action.id, 'follow_up'),
        title: 'Follow up needed',
        body: 'Check in with $personName about: ${action.title}',
        channel: 'mission_follow_up',
        scheduledTime: followUpDate,
        payload: 'mission_follow_up:${action.id}',
      );
    } catch (e) {
      // Silently fail if notification scheduling fails
      debugPrint('Failed to schedule follow-up reminder: $e');
    }
  }

  int _generateNotificationId(String actionId, String type) {
    // Generate a unique notification ID based on action ID and type
    final hash = actionId.hashCode + type.hashCode;
    return hash.abs() % 1000000;
  }

  Future<void> completeFollowUp(MissionAction action, {String? notes}) async {
    final updated = action.copyWith(
      followUpCompletedAt: DateTime.now(),
      notes: notes != null ? '${action.notes ?? ''}\n\nFollow-up: $notes'.trim() : action.notes,
    );

    final actions = state.actions
        .map((item) => item.id == action.id ? updated : item)
        .toList();

    state = state.copyWith(actions: actions);
    await _settingsNotifier.setMissionActions(actions);

    // Cancel the follow-up reminder since it's now complete
    await _notificationService.cancelNotification(_generateNotificationId(action.id, 'follow_up'));

    _analytics.track(
      AppAnalyticsEvent.missionActionCompleted,
      properties: {
        'focus': action.focus.name,
        'follow_up_completed': true,
      },
    );
  }

  Future<void> savePartner({
    required String name,
    required String relationship,
    required String contact,
  }) async {
    final partner = AccountabilityPartner(
      name: name,
      relationship: relationship,
      contact: contact,
      lastCheckInAt: state.accountabilityPartner?.lastCheckInAt,
      lastCheckInNote: state.accountabilityPartner?.lastCheckInNote,
    );

    state = state.copyWith(accountabilityPartner: partner);
    await _settingsNotifier.setAccountabilityPartner(partner);
    _analytics.track(
      AppAnalyticsEvent.accountabilityPartnerSaved,
      properties: {
        'has_contact': contact.isNotEmpty,
      },
    );
  }

  Future<void> logCheckIn(String note) async {
    final partner = state.accountabilityPartner;
    if (partner == null) {
      return;
    }

    final updatedPartner = partner.copyWith(
      lastCheckInAt: DateTime.now(),
      lastCheckInNote: note,
    );

    state = state.copyWith(accountabilityPartner: updatedPartner);
    await _settingsNotifier.setAccountabilityPartner(updatedPartner);
    _analytics.track(
      AppAnalyticsEvent.accountabilityCheckInLogged,
      properties: {
        'note_length': note.trim().length,
        'pending_actions': state.pendingActions.length,
      },
    );
  }

  List<PersonProfile>? _syncPersonProfileForName(String? personName) {
    final trimmedName = _cleanOptional(personName);
    if (trimmedName == null) {
      return null;
    }

    final profiles = [..._settingsNotifier.state.personProfiles];
    final index = profiles.indexWhere(
      (profile) => profile.name.toLowerCase() == trimmedName.toLowerCase(),
    );

    if (index == -1) {
      profiles.insert(
        0,
        PersonProfile.create(
          name: trimmedName,
          relationship: 'Friend',
        ),
      );
      return profiles;
    }

    profiles[index] = profiles[index].copyWith(lastInteractionAt: DateTime.now());
    return profiles;
  }

  Future<void> _syncWeeklyPlanProgress(
    MissionAction action, {
    required bool increment,
  }) async {
    final weeklyPlan = _settingsNotifier.state.currentWeeklyPlan;
    if (weeklyPlan == null) {
      return;
    }

    final updatedCommitments = [...weeklyPlan.weeklyCommitments];
    final targetIndex = updatedCommitments.indexWhere(
      (commitment) => commitment.category == _commitmentCategoryForFocus(action.focus),
    );

    if (targetIndex == -1) {
      return;
    }

    final commitment = updatedCommitments[targetIndex];
    final nextCount = increment
        ? (commitment.currentCount + 1).clamp(0, commitment.targetCount)
        : (commitment.currentCount - 1).clamp(0, commitment.targetCount);
    updatedCommitments[targetIndex] = commitment.copyWith(currentCount: nextCount);

    await _settingsNotifier.setCurrentWeeklyPlan(
      weeklyPlan.copyWith(weeklyCommitments: updatedCommitments),
    );
  }

  String _commitmentCategoryForFocus(MissionFocusType focus) {
    switch (focus) {
      case MissionFocusType.service:
        return 'charity';
      case MissionFocusType.faithSharing:
        return 'growth';
      case MissionFocusType.encouragement:
        return 'growth';
    }
  }

  String? _cleanOptional(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  // ===========================================================================
  // Enhanced Accountability Check-in Flow
  // ===========================================================================

  /// Request a check-in from the accountability partner
  /// Creates a pending check-in request that the partner can confirm
  Future<void> requestCheckIn({
    required String note,
    required List<String> completedCommitmentIds,
  }) async {
    final partner = state.accountabilityPartner;
    if (partner == null) {
      return;
    }

    // Get the start of the current week
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    final request = CheckInRequest(
      id: _uuid.v4(),
      requestedAt: now,
      requestedByUserId: 'current_user', // In real app, use actual user ID
      weekStartDate: DateTime(weekStart.year, weekStart.month, weekStart.day),
      note: note,
      verifiedCommitments: completedCommitmentIds,
    );

    final updatedPartner = partner.copyWith(
      pendingCheckInRequest: request,
    );

    state = state.copyWith(accountabilityPartner: updatedPartner);
    await _settingsNotifier.setAccountabilityPartner(updatedPartner);

    _analytics.track(
      AppAnalyticsEvent.accountabilityCheckInRequested,
      properties: {
        'note_length': note.trim().length,
        'completed_commitments': completedCommitmentIds.length,
      },
    );
  }

  /// Confirm a pending check-in request (called by the partner)
  /// This verifies that the user completed their commitments
  Future<void> confirmCheckIn({
    required String confirmationNote,
    required List<String> verifiedCommitmentIds,
  }) async {
    final partner = state.accountabilityPartner;
    if (partner == null || partner.pendingCheckInRequest == null) {
      return;
    }

    final pendingRequest = partner.pendingCheckInRequest!;
    final confirmedRequest = pendingRequest.copyWith(
      confirmedAt: DateTime.now(),
      confirmedByUserId: 'partner_user', // In real app, use actual partner user ID
      confirmationNote: confirmationNote,
      verifiedCommitments: verifiedCommitmentIds,
    );

    // Calculate new weekly streak
    final newStreak = partner.weeklyStreak + 1;

    final updatedPartner = partner.copyWith(
      lastCheckInAt: DateTime.now(),
      lastCheckInNote: confirmedRequest.note,
      pendingCheckInRequest: null, // Clear the pending request
      weeklyStreak: newStreak,
    );

    state = state.copyWith(accountabilityPartner: updatedPartner);
    await _settingsNotifier.setAccountabilityPartner(updatedPartner);

    _analytics.track(
      AppAnalyticsEvent.accountabilityCheckInConfirmed,
      properties: {
        'streak': newStreak,
        'confirmation_note_length': confirmationNote.trim().length,
        'verified_commitments': verifiedCommitmentIds.length,
      },
    );
  }

  /// Cancel a pending check-in request
  Future<void> cancelCheckInRequest() async {
    final partner = state.accountabilityPartner;
    if (partner == null) {
      return;
    }

    final updatedPartner = partner.copyWith(
      pendingCheckInRequest: null,
    );

    state = state.copyWith(accountabilityPartner: updatedPartner);
    await _settingsNotifier.setAccountabilityPartner(updatedPartner);
  }

  /// Save partner with enhanced options including partner type
  Future<void> savePartnerEnhanced({
    required String name,
    required String relationship,
    required String contact,
    PartnerType partnerType = PartnerType.peer,
  }) async {
    final existingPartner = state.accountabilityPartner;
    final partner = AccountabilityPartner(
      name: name,
      relationship: relationship,
      contact: contact,
      lastCheckInAt: existingPartner?.lastCheckInAt,
      lastCheckInNote: existingPartner?.lastCheckInNote,
      partnerType: partnerType,
      pendingCheckInRequest: existingPartner?.pendingCheckInRequest,
      weeklyStreak: existingPartner?.weeklyStreak ?? 0,
    );

    state = state.copyWith(accountabilityPartner: partner);
    await _settingsNotifier.setAccountabilityPartner(partner);
    _analytics.track(
      AppAnalyticsEvent.accountabilityPartnerSaved,
      properties: {
        'has_contact': contact.isNotEmpty,
        'partner_type': partnerType.name,
      },
    );
  }

  /// Get the current weekly commitments for shared visibility
  List<dynamic> get sharedWeeklyCommitments {
    final weeklyPlan = _settingsNotifier.state.currentWeeklyPlan;
    if (weeklyPlan == null) {
      return [];
    }
    return weeklyPlan.weeklyCommitments;
  }

  /// Check if there's a pending check-in request
  bool get hasPendingCheckInRequest {
    return state.accountabilityPartner?.pendingCheckInRequest != null;
  }

  /// Get the pending check-in request if any
  CheckInRequest? get pendingCheckInRequest {
    return state.accountabilityPartner?.pendingCheckInRequest;
  }
}
