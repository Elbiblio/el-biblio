import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../../core/application/settings_notifier.dart';
import '../../../core/services/analytics/app_analytics_service.dart';
import '../../../core/services/notifications/notification_service.dart';
import '../../../core/storage/app_settings.dart';
import '../data/service_opportunity_repository.dart';
import '../domain/models/check_in_request.dart';
import '../domain/models/accountability_partner.dart';
import '../domain/models/kingdom_action_models.dart';
import '../domain/models/mission_action.dart';
import '../domain/models/mission_focus.dart';
import '../domain/models/person_profile.dart';
import '../../assessment/domain/models/calling_profile.dart';
import 'mission_state.dart';

class MissionNotifier extends StateNotifier<MissionState> {
  MissionNotifier({
    required SettingsNotifier settingsNotifier,
    required AppAnalyticsService analytics,
    required NotificationService notificationService,
    required ServiceOpportunityRepository serviceOpportunityRepository,
    required Logger logger,
    required AppSettings initialSettings,
  })  : _settingsNotifier = settingsNotifier,
        _analytics = analytics,
        _notificationService = notificationService,
        _serviceOpportunityRepository = serviceOpportunityRepository,
        _logger = logger,
        _uuid = const Uuid(),
        super(_stateFromSettings(initialSettings));

  final SettingsNotifier _settingsNotifier;
  final AppAnalyticsService _analytics;
  final NotificationService _notificationService;
  final ServiceOpportunityRepository _serviceOpportunityRepository;
  final Logger _logger;
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

    // Schedule weekly Friday check-in reminder now that there's a partner
    unawaited(
      _notificationService.scheduleWeeklyPartnerCheckInReminder(
        partnerName: name,
      ),
    );

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

    // Schedule weekly Friday check-in reminder now that there's a partner
    unawaited(
      _notificationService.scheduleWeeklyPartnerCheckInReminder(
        partnerName: name,
      ),
    );

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

  // ===========================================================================
  // Kingdom Action Depth Methods
  // ===========================================================================

  /// Create a commitment to help a specific person
  Future<void> createPersonCommitment({
    required String name,
    required String relationship,
    String? notes,
    String? needs,
    List<String> tags = const [],
  }) async {
    final commitment = PersonCommitment(
      id: _uuid.v4(),
      name: name,
      relationship: relationship,
      createdAt: DateTime.now(),
      notes: notes,
      needs: needs,
      tags: tags,
    );

    final commitments = [commitment, ...state.personCommitments];
    state = state.copyWith(personCommitments: commitments);
    await _settingsNotifier.setPersonCommitments(commitments);

    _analytics.track(
      'person_commitment_created',
      properties: {
        'relationship': relationship,
        'has_needs': needs?.isNotEmpty ?? false,
      },
    );
  }

  /// Update an existing person commitment
  Future<void> updatePersonCommitment(String id, {
    String? name,
    String? relationship,
    String? notes,
    String? needs,
    List<String>? tags,
    bool? isActive,
    DateTime? lastContactAt,
    DateTime? nextFollowUpAt,
  }) async {
    final index = state.personCommitments.indexWhere((c) => c.id == id);
    if (index == -1) return;

    final updated = state.personCommitments[index].copyWith(
      name: name,
      relationship: relationship,
      notes: notes,
      needs: needs,
      tags: tags,
      isActive: isActive,
      lastContactAt: lastContactAt,
      nextFollowUpAt: nextFollowUpAt,
    );

    final commitments = [...state.personCommitments];
    commitments[index] = updated;
    state = state.copyWith(personCommitments: commitments);
    await _settingsNotifier.setPersonCommitments(commitments);
  }

  /// Link a mission action to a person commitment
  Future<void> linkActionToPersonCommitment({
    required String actionId,
    required String personCommitmentId,
  }) async {
    final index = state.personCommitments.indexWhere((c) => c.id == personCommitmentId);
    if (index == -1) return;

    final commitment = state.personCommitments[index];
    if (commitment.committedActions.contains(actionId)) return;

    final updated = commitment.copyWith(
      committedActions: [...commitment.committedActions, actionId],
      lastContactAt: DateTime.now(),
    );

    final commitments = [...state.personCommitments];
    commitments[index] = updated;
    state = state.copyWith(personCommitments: commitments);
    await _settingsNotifier.setPersonCommitments(commitments);
  }

  /// Get active person commitments needing follow-up
  List<PersonCommitment> get commitmentsNeedingFollowUp {
    return state.personCommitments
        .where((c) => c.isActive && c.needsFollowUp)
        .toList();
  }

  /// Record a generosity/mercy action
  Future<void> recordGenerosity({
    required GenerosityType type,
    required String description,
    double? amount,
    String currency = 'USD',
    String? recipientName,
    String? recipientType,
    String? category,
    bool isRecurring = false,
    String? recurringFrequency,
    String? notes,
    String? impactDescription,
  }) async {
    final record = GenerosityRecord(
      id: _uuid.v4(),
      type: type,
      description: description,
      date: DateTime.now(),
      amount: amount,
      currency: currency,
      recipientName: recipientName,
      recipientType: recipientType,
      category: category,
      isRecurring: isRecurring,
      recurringFrequency: recurringFrequency,
      notes: notes,
      impactDescription: impactDescription,
    );

    final records = [record, ...state.generosityRecords];
    state = state.copyWith(generosityRecords: records);
    await _settingsNotifier.setGenerosityRecords(records);

    _analytics.track(
      'generosity_recorded',
      properties: {
        'type': type.name,
        'category': category,
        'is_recurring': isRecurring,
      },
    );
  }

  /// Get generosity summary for a time period
  Map<String, dynamic> getGenerositySummary({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();

    final periodRecords = state.generosityRecords.where((r) {
      return r.date.isAfter(start) && r.date.isBefore(end);
    }).toList();

    final financial = periodRecords.where((r) => r.isFinancial);
    final time = periodRecords.where((r) => r.isTime);
    final resources = periodRecords.where((r) => r.isResource);

    final totalFinancial = financial.fold<double>(0, (sum, r) => sum + (r.amount ?? 0));

    return {
      'total_records': periodRecords.length,
      'financial_count': financial.length,
      'time_count': time.length,
      'resource_count': resources.length,
      'total_amount': totalFinancial,
      'currency': financial.isNotEmpty ? financial.first.currency : 'USD',
    };
  }

  /// Log an evangelism conversation with follow-up tracking
  Future<void> logEvangelismConversation({
    required String personName,
    required String method,
    String? initialContext,
    String? contentShared,
    String? responseType,
    String? notes,
    List<String>? prayerRequests,
  }) async {
    final conversation = EvangelismConversation(
      id: _uuid.v4(),
      personName: personName,
      date: DateTime.now(),
      method: method,
      initialContext: initialContext,
      contentShared: contentShared,
      responseType: responseType,
      notes: notes,
      prayerRequests: prayerRequests,
    );

    final conversations = [conversation, ...state.evangelismConversations];
    state = state.copyWith(evangelismConversations: conversations);
    await _settingsNotifier.setEvangelismConversations(conversations);

    // Schedule follow-up notification
    final followUpDate = DateTime.now().add(const Duration(days: 7));
    await _notificationService.scheduleNotificationWithActions(
      id: 'evangelism_followup_${conversation.id}'.hashCode,
      title: 'Follow-up Reminder',
      body: 'Pray for and follow up with $personName',
      channel: 'mission_followup',
      scheduledTime: followUpDate,
      payload: 'evangelism_followup:${conversation.id}',
      actionLabels: const ['Log Follow-up', 'Pray Now'],
    );

    _analytics.track(
      'evangelism_conversation_logged',
      properties: {
        'method': method,
        'response_type': responseType,
        'has_prayer_requests': prayerRequests?.isNotEmpty ?? false,
      },
    );
  }

  /// Record a follow-up to an evangelism conversation
  Future<void> recordEvangelismFollowUp({
    required String conversationId,
    String? notes,
    String? newResponseType,
    List<String>? newPrayerRequests,
    String? decisionMade,
  }) async {
    final index = state.evangelismConversations.indexWhere((c) => c.id == conversationId);
    if (index == -1) return;

    final conversation = state.evangelismConversations[index];
    final updated = conversation.copyWith(
      followUpDates: [...conversation.followUpDates, DateTime.now()],
      notes: notes != null ? '${conversation.notes ?? ''}\n\nFollow-up: $notes' : conversation.notes,
      responseType: newResponseType ?? conversation.responseType,
      prayerRequests: newPrayerRequests ?? conversation.prayerRequests,
      decisionMade: decisionMade,
      decisionDate: decisionMade != null ? DateTime.now() : conversation.decisionDate,
      isOngoing: decisionMade != 'accepted' && decisionMade != 'declined',
    );

    final conversations = [...state.evangelismConversations];
    conversations[index] = updated;
    state = state.copyWith(evangelismConversations: conversations);
    await _settingsNotifier.setEvangelismConversations(conversations);

    _analytics.track(
      'evangelism_follow_up_recorded',
      properties: {
        'days_since_conversation': conversation.daysSinceLastContact,
        'decision_made': decisionMade,
      },
    );
  }

  /// Get evangelism conversations needing follow-up
  List<EvangelismConversation> get evangelismNeedsFollowUp {
    return state.evangelismConversations
        .where((c) => c.isOngoing && c.needsFollowUp)
        .toList();
  }

  /// Generate dynamic service matches based on calling profile
  /// Attempts backend API first, falls back to local generation if offline
  Future<List<ServiceMatch>> generateServiceMatches() async {
    final profile = _settingsNotifier.state.callingProfile;
    if (profile == null) return [];

    try {
      // Try backend API first
      final matches = await _serviceOpportunityRepository.getMatchedOpportunities();
      _logger.i('Loaded ${matches.length} service matches from backend');
      return matches;
    } catch (e) {
      // Fallback to local generation if offline or API fails
      _logger.w('Backend service match failed, using local fallback: $e');
      return _generateLocalServiceMatches(profile);
    }
  }

  /// Local fallback for service matching when offline
  List<ServiceMatch> _generateLocalServiceMatches(CallingProfile profile) {
    final matches = <ServiceMatch>[];
    final tendencies = profile.burdensAndServiceTendencies;

    // Static opportunities data (fallback only)
    final opportunities = [
      {
        'id': 'children_ministry',
        'title': 'Children\'s Ministry Helper',
        'category': 'children',
        'burdens': ['children', 'education', 'families'],
        'tendencies': ['teaching', 'mentoring'],
      },
      {
        'id': 'elderly_visits',
        'title': 'Elderly Care Visits',
        'category': 'elderly',
        'burdens': ['elderly', 'loneliness', 'healthcare'],
        'tendencies': ['visiting', 'listening', 'compassion'],
      },
      {
        'id': 'food_bank',
        'title': 'Food Bank Distribution',
        'category': 'poverty',
        'burdens': ['poverty', 'hunger', 'community'],
        'tendencies': ['serving', 'organizing', 'generosity'],
      },
      {
        'id': 'prayer_team',
        'title': 'Intercessory Prayer Team',
        'category': 'prayer',
        'burdens': ['prayer', 'spiritual_warfare', 'community'],
        'tendencies': ['praying', 'listening', 'faithfulness'],
      },
    ];

    for (final opp in opportunities) {
      final oppBurdens = opp['burdens'] as List<String>;
      final oppTendencies = opp['tendencies'] as List<String>;

      // Calculate match score
      int matchPoints = 0;
      final matchReasons = <String>[];

      // Check burden alignment
      for (final burden in tendencies) {
        if (oppBurdens.any((b) => burden.toLowerCase().contains(b) || b.contains(burden.toLowerCase()))) {
          matchPoints += 2;
          matchReasons.add('Aligns with your burden for $burden');
        }
      }

      // Check tendency alignment
      for (final tendency in tendencies) {
        if (oppTendencies.any((t) => tendency.toLowerCase().contains(t) || t.contains(tendency.toLowerCase()))) {
          matchPoints += 1;
          if (matchReasons.length < 3) {
            matchReasons.add('Matches your $tendency tendency');
          }
        }
      }

      // Normalize score to 0.0-1.0 range
      final score = (matchPoints / 6).clamp(0.0, 1.0);

      if (score > 0.3) {
        matches.add(ServiceMatch(
          opportunityId: opp['id'] as String,
          title: opp['title'] as String,
          matchScore: score,
          matchReasons: matchReasons.isEmpty
              ? ['General service opportunity']
              : matchReasons.take(2).toList(),
          category: opp['category'] as String,
          burdenAlignment: oppBurdens.firstWhere(
            (b) => tendencies.any((t) => t.toLowerCase().contains(b)),
            orElse: () => '',
          ),
          tendencyAlignment: oppTendencies.firstWhere(
            (t) => tendencies.any((ten) => ten.toLowerCase().contains(t)),
            orElse: () => '',
          ),
        ));
      }
    }

    // Sort by match score descending
    matches.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    return matches;
  }

  /// Get all impact timeline events (actions, generosity, evangelism, commitments)
  List<ImpactTimelineEvent> get impactTimeline {
    final events = <ImpactTimelineEvent>[];

    // Add completed mission actions
    for (final action in state.completedActions) {
      events.add(ImpactTimelineEvent(
        id: 'action_${action.id}',
        date: action.completedAt!,
        type: ImpactType.action,
        title: action.title,
        description: action.description,
        personName: action.personName,
        focusType: action.focus,
      ));
    }

    // Add generosity records
    for (final record in state.generosityRecords) {
      events.add(ImpactTimelineEvent(
        id: 'generosity_${record.id}',
        date: record.date,
        type: ImpactType.generosity,
        title: '${record.type.label}: ${record.description}',
        description: record.impactDescription ?? 'Given to ${record.recipientName ?? 'someone in need'}',
        recipientName: record.recipientName,
        category: record.category,
      ));
    }

    // Add evangelism conversations
    for (final conversation in state.evangelismConversations) {
      events.add(ImpactTimelineEvent(
        id: 'evangelism_${conversation.id}',
        date: conversation.date,
        type: ImpactType.evangelism,
        title: 'Shared faith with ${conversation.personName}',
        description: conversation.contentShared ?? 'Gospel conversation',
        personName: conversation.personName,
        isOngoing: conversation.isOngoing,
        decisionMade: conversation.decisionMade,
      ));
    }

    // Add person commitment milestones
    for (final commitment in state.personCommitments.where((c) => c.committedActions.isNotEmpty)) {
      events.add(ImpactTimelineEvent(
        id: 'commitment_${commitment.id}',
        date: commitment.lastContactAt ?? commitment.createdAt,
        type: ImpactType.relationship,
        title: 'Helped ${commitment.name}',
        description: '${commitment.committedActions.length} actions completed',
        personName: commitment.name,
        relationship: commitment.relationship,
      ));
    }

    // Sort by date descending (most recent first)
    events.sort((a, b) => b.date.compareTo(a.date));
    return events;
  }
}

/// Unified impact timeline event for visualization
class ImpactTimelineEvent {
  const ImpactTimelineEvent({
    required this.id,
    required this.date,
    required this.type,
    required this.title,
    required this.description,
    this.personName,
    this.recipientName,
    this.category,
    this.focusType,
    this.isOngoing,
    this.decisionMade,
    this.relationship,
  });

  final String id;
  final DateTime date;
  final ImpactType type;
  final String title;
  final String description;
  final String? personName;
  final String? recipientName;
  final String? category;
  final dynamic focusType;
  final bool? isOngoing;
  final String? decisionMade;
  final String? relationship;
}

enum ImpactType {
  action,
  generosity,
  evangelism,
  relationship,
}

extension ImpactTypeX on ImpactType {
  String get label {
    switch (this) {
      case ImpactType.action:
        return 'Mission Action';
      case ImpactType.generosity:
        return 'Generosity';
      case ImpactType.evangelism:
        return 'Faith Sharing';
      case ImpactType.relationship:
        return 'Relationship';
    }
  }

  IconData get icon {
    switch (this) {
      case ImpactType.action:
        return Icons.rocket_launch;
      case ImpactType.generosity:
        return Icons.favorite;
      case ImpactType.evangelism:
        return Icons.wb_sunny;
      case ImpactType.relationship:
        return Icons.people;
    }
  }

  Color get color {
    switch (this) {
      case ImpactType.action:
        return Colors.blue;
      case ImpactType.generosity:
        return Colors.green;
      case ImpactType.evangelism:
        return Colors.orange;
      case ImpactType.relationship:
        return Colors.purple;
    }
  }
}
