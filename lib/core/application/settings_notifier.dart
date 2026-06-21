import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/assessment/application/calling_profile_service.dart';
import '../../features/assessment/domain/models/archetype.dart';
import '../../features/assessment/domain/models/weekly_plan.dart';
import '../../features/commitments/domain/models/commitment_category.dart';
import '../../features/companion/domain/models/christian_life_baseline.dart';
import '../../features/mission/domain/models/accountability_partner.dart';
import '../../features/mission/domain/models/kingdom_action_models.dart';
import '../../features/mission/domain/models/mission_action.dart';
import '../../features/mission/domain/models/mission_focus.dart';
import '../../features/mission/domain/models/person_profile.dart';
import '../services/analytics/app_analytics_service.dart';
import '../../features/today/domain/models/daily_anchors.dart';
import '../models/accountability_tone.dart';
import '../services/notifications/notification_service.dart';
import '../services/xp_service.dart';
import '../storage/app_settings.dart';
import '../storage/settings_storage.dart';

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._storage, this._analytics, this._callingProfileService)
    : super(AppSettings.defaults()) {
    NotificationService().setDailyCheckInActionHandler(() async {
      await registerDailyCheckIn(DateTime.now());
    });
    _hydrate();
  }

  final SettingsStorage _storage;
  final AppAnalyticsService _analytics;
  final CallingProfileService _callingProfileService;

  AppSettings _unlockBadge(
    AppSettings current,
    String id,
    DateTime unlockedAt,
  ) {
    if (current.unlockedBadges.containsKey(id)) {
      return current;
    }
    final nextBadges = Map<String, String>.from(current.unlockedBadges)
      ..[id] = unlockedAt.toIso8601String();

    return current.copyWith(unlockedBadges: nextBadges);
  }

  Future<void> _hydrate() async {
    state = await _storage.load();
    unawaited(_syncNotifications(state));
  }

  /// Persist settings with a single retry on failure.
  /// Critical for onboarding flags — a missed save means re-onboarding.
  Future<void> _persistWithRetry(AppSettings settings) async {
    try {
      await _storage.save(settings);
    } catch (_) {
      // Single retry after a brief pause
      await Future.delayed(const Duration(milliseconds: 200));
      await _storage.save(settings);
    }
  }

  Future<void> resetOnboarding() async {
    final next = AppSettings.defaults();
    state = next;
    await _storage.save(next);
    unawaited(_syncNotifications(next));
  }

  Future<void> markRecalibrationPromptShown(DateTime day) async {
    final normalized = DateTime(day.year, day.month, day.day);
    final next = state.copyWith(lastRecalibrationPromptDate: normalized);
    state = next;
    await _storage.save(next);
  }

  Future<void> completePreOnboarding({
    required String name,
    required String phone,
  }) async {
    // Persist that pre-onboarding is done
    final newSettings = state.copyWith(hasCompletedPreOnboarding: true);
    state = newSettings;
    await _persistWithRetry(newSettings);
  }

  /// Atomic write that finalizes both pre-onboarding + onboarding flags
  /// plus all pre-signup selections in a single persist. Replaces the
  /// previous two-call (`completePreOnboarding` + `completeOnboarding`)
  /// sequence so a crash mid-flight can't leave the two flags split.
  Future<void> persistOnboardingBundle({
    required VirtueType primaryVirtue,
    required String lifestyle,
    required String morningTime,
    required String eveningTime,
    required bool morningReminderEnabled,
    required bool eveningReminderEnabled,
    required bool socialPresenceOptIn,
    required bool contactsImported,
    String? primaryArchetypeId,
    List<String> selectedArchetypeIds = const [],
    String? commitmentCategory,
    String? primaryMissionFocus,
    String? ageBand,
    int spiritualAgeScore = 0,
    String spiritualAgeStage = 'Infant',
    List<String> personalDistractions = const [],
    ChristianLifeBaseline? christianLifeBaseline,
    AccountabilityTone accountabilityTone = AccountabilityTone.balanced,
  }) async {
    final normalizedCommitmentCategory = commitmentCategory == null
        ? null
        : CommitmentCategory.normalizeStorageValue(commitmentCategory);
    final normalizedMissionFocus = primaryMissionFocus == null
        ? null
        : MissionFocusTypeX.normalizeStorageValue(primaryMissionFocus);

    var newSettings = state.copyWith(
      hasCompletedPreOnboarding: true,
      onboardingCompleted: true,
      hasCompletedPostOnboarding: true,
      primaryVirtue: primaryVirtue,
      lifestyle: lifestyle,
      morningTime: morningTime,
      eveningTime: eveningTime,
      morningReminderEnabled: morningReminderEnabled,
      eveningReminderEnabled: eveningReminderEnabled,
      socialPresenceOptIn: socialPresenceOptIn,
      contactsImported: contactsImported,
      primaryArchetypeId: primaryArchetypeId,
      selectedArchetypeIds: selectedArchetypeIds,
      commitmentCategory: normalizedCommitmentCategory,
      primaryMissionFocus: normalizedMissionFocus,
      ageBand: ageBand,
      spiritualAgeScore: spiritualAgeScore,
      spiritualAgeStage: spiritualAgeStage,
      christianLifeBaseline: christianLifeBaseline,
      accountabilityTone: accountabilityTone,
    );

    if (primaryArchetypeId != null && normalizedCommitmentCategory != null) {
      final archetype = Archetype.allArchetypes.firstWhere(
        (a) => a.name == primaryArchetypeId,
      );

      final effectiveMissionFocus =
          normalizedMissionFocus ??
          _recommendedMissionFocus(
            CommitmentCategory.values.firstWhere(
              (c) => c.name == normalizedCommitmentCategory,
              orElse: () => CommitmentCategory.growth,
            ),
          ).name;

      if (normalizedMissionFocus == null) {
        newSettings = newSettings.copyWith(
          primaryMissionFocus: effectiveMissionFocus,
        );
      }

      final callingProfile = _callingProfileService.generateProfile(
        archetype: archetype,
        commitmentCategory: normalizedCommitmentCategory,
        missionFocus: effectiveMissionFocus,
        personalDistractions: personalDistractions,
      );

      final now = DateTime.now();
      final weekStart = _startOfWeek(now);
      final weeklyPlan = _callingProfileService.generateWeeklyPlan(
        profile: callingProfile,
        weekStart: weekStart,
        morningTime: morningTime,
        eveningTime: eveningTime,
      );

      newSettings = newSettings.copyWith(
        callingProfile: callingProfile,
        currentWeeklyPlan: weeklyPlan,
      );
    }

    state = newSettings;
    await _persistWithRetry(newSettings);
    unawaited(
      _syncNotifications(
        newSettings,
        requestPermissions:
            newSettings.morningReminderEnabled ||
            newSettings.eveningReminderEnabled,
      ),
    );
    _analytics.track(
      AppAnalyticsEvent.onboardingCompleted,
      properties: {
        'primary_archetype': primaryArchetypeId,
        'top_archetypes': selectedArchetypeIds,
        'commitment_category': normalizedCommitmentCategory,
        'mission_focus': normalizedMissionFocus,
        'age_band': ageBand,
        'spiritual_age_score': spiritualAgeScore,
        'spiritual_age_stage': spiritualAgeStage,
        'accountability_tone': accountabilityTone.storageValue,
      },
    );
  }

  Future<void> completeOnboarding({
    required VirtueType primaryVirtue,
    required String lifestyle,
    required String morningTime,
    required String eveningTime,
    required bool morningReminderEnabled,
    required bool eveningReminderEnabled,
    required bool socialPresenceOptIn,
    required bool contactsImported,
    String? primaryArchetypeId,
    String? commitmentCategory,
    String? primaryMissionFocus,
    List<String> personalDistractions = const [],
    ChristianLifeBaseline? christianLifeBaseline,
  }) async {
    final normalizedCommitmentCategory = commitmentCategory == null
        ? null
        : CommitmentCategory.normalizeStorageValue(commitmentCategory);
    final normalizedMissionFocus = primaryMissionFocus == null
        ? null
        : MissionFocusTypeX.normalizeStorageValue(primaryMissionFocus);
    var newSettings = state.copyWith(
      onboardingCompleted: true,
      hasCompletedPostOnboarding: true,
      primaryVirtue: primaryVirtue,
      lifestyle: lifestyle,
      morningTime: morningTime,
      eveningTime: eveningTime,
      morningReminderEnabled: morningReminderEnabled,
      eveningReminderEnabled: eveningReminderEnabled,
      socialPresenceOptIn: socialPresenceOptIn,
      contactsImported: contactsImported,
      primaryArchetypeId: primaryArchetypeId,
      commitmentCategory: normalizedCommitmentCategory,
      primaryMissionFocus: normalizedMissionFocus,
      christianLifeBaseline: christianLifeBaseline,
    );

    // Generate calling profile and weekly plan if we have archetype data
    if (primaryArchetypeId != null && normalizedCommitmentCategory != null) {
      final archetype = Archetype.allArchetypes.firstWhere(
        (a) => a.name == primaryArchetypeId,
      );

      // Auto-derive mission focus from commitment category if not explicitly set
      final effectiveMissionFocus =
          normalizedMissionFocus ??
          _recommendedMissionFocus(
            CommitmentCategory.values.firstWhere(
              (c) => c.name == normalizedCommitmentCategory,
              orElse: () => CommitmentCategory.growth,
            ),
          ).name;

      // Persist the derived mission focus
      if (normalizedMissionFocus == null) {
        newSettings = newSettings.copyWith(
          primaryMissionFocus: effectiveMissionFocus,
        );
      }

      final callingProfile = _callingProfileService.generateProfile(
        archetype: archetype,
        commitmentCategory: normalizedCommitmentCategory,
        missionFocus: effectiveMissionFocus,
        personalDistractions: personalDistractions,
      );

      // Generate initial weekly plan
      final now = DateTime.now();
      final weekStart = _startOfWeek(now);
      final weeklyPlan = _callingProfileService.generateWeeklyPlan(
        profile: callingProfile,
        weekStart: weekStart,
        morningTime: morningTime,
        eveningTime: eveningTime,
      );

      newSettings = newSettings.copyWith(
        callingProfile: callingProfile,
        currentWeeklyPlan: weeklyPlan,
      );
    }

    state = newSettings;
    await _persistWithRetry(newSettings);
    unawaited(
      _syncNotifications(
        newSettings,
        requestPermissions:
            newSettings.morningReminderEnabled ||
            newSettings.eveningReminderEnabled,
      ),
    );
    _analytics.track(
      AppAnalyticsEvent.onboardingCompleted,
      properties: {
        'primary_archetype': primaryArchetypeId,
        'commitment_category': normalizedCommitmentCategory,
        'mission_focus': normalizedMissionFocus,
      },
    );
  }

  Future<void> setVirtueFocus({required VirtueType primaryVirtue}) async {
    final next = state.copyWith(primaryVirtue: primaryVirtue);
    state = next;
    await _storage.save(next);
  }

  Future<void> generateCallingProfileFromAssessment({
    required Archetype primaryArchetype,
    List<String>? selectedTaskIds,
  }) async {
    // Only generate if no profile exists
    if (state.callingProfile != null) {
      return;
    }

    final recommendedCategory = CommitmentCategory.recommendedForArchetype(
      primaryArchetype.name,
    );
    final commitmentCategory = recommendedCategory.name;
    final missionFocus = _recommendedMissionFocus(recommendedCategory).name;
    final personalDistractions = primaryArchetype.typicalDistractions;

    final callingProfile = _callingProfileService.generateProfile(
      archetype: primaryArchetype,
      commitmentCategory: commitmentCategory,
      missionFocus: missionFocus,
      personalDistractions: personalDistractions,
    );

    // Generate initial weekly plan
    final now = DateTime.now();
    final weekStart = _startOfWeek(now);
    var weeklyPlan = _callingProfileService.generateWeeklyPlan(
      profile: callingProfile,
      weekStart: weekStart,
      morningTime: state.morningTime,
      eveningTime: state.eveningTime,
    );

    // Add selected assessment tasks as weekly commitments
    if (selectedTaskIds != null && selectedTaskIds.isNotEmpty) {
      final additionalCommitments = _createCommitmentsFromTaskIds(
        selectedTaskIds,
      );
      weeklyPlan = weeklyPlan.copyWith(
        weeklyCommitments: [
          ...weeklyPlan.weeklyCommitments,
          ...additionalCommitments,
        ],
      );
    }

    final newSettings = state.copyWith(
      callingProfile: callingProfile,
      currentWeeklyPlan: weeklyPlan,
      primaryArchetypeId: primaryArchetype.name,
      commitmentCategory: commitmentCategory,
      primaryMissionFocus: missionFocus,
    );

    state = newSettings;
    await _storage.save(newSettings);
    _analytics.track(
      AppAnalyticsEvent.callingProfileCreated,
      properties: {
        'source': 'assessment',
        'archetype': primaryArchetype.name,
        'mission_focus': missionFocus,
        'tasks_count': selectedTaskIds?.length ?? 0,
      },
    );
  }

  List<WeeklyCommitment> _createCommitmentsFromTaskIds(List<String> taskIds) {
    // Map task IDs to WeeklyCommitments
    // For now, we'll create generic commitments with the task IDs
    // In a full implementation, you'd look up the actual task details
    return taskIds.map((taskId) {
      return WeeklyCommitment(
        id: WeeklyCommitment.generateId('action', taskId),
        type: 'action',
        title: _getTaskTitle(taskId),
        description: _getTaskDescription(taskId),
        targetCount: 1, // Each task is a one-time action
        currentCount: 0,
        category: _getTaskCategory(taskId),
      );
    }).toList();
  }

  String _getTaskTitle(String taskId) {
    // Simplified mapping - in production, this would look up from a catalog
    if (taskId.startsWith('dev_')) {
      switch (taskId) {
        case 'dev_1':
          return 'Read one book about your specific talent';
        case 'dev_2':
          return 'Find a mentor in your area of calling';
        case 'dev_3':
          return 'Start a journal tracking your growth';
        case 'dev_4':
          return 'Take a course related to your archetype';
        case 'dev_5':
          return 'Find an accountability partner';
        default:
          return 'Development task';
      }
    } else if (taskId.startsWith('eng_')) {
      switch (taskId) {
        case 'eng_1':
          return 'Volunteer in your local church';
        case 'eng_2':
          return 'Start a small group or initiative';
        case 'eng_3':
          return 'Offer your skills to a non-profit';
        case 'eng_4':
          return 'Mentor someone younger in faith';
        case 'eng_5':
          return 'Take on a new responsibility at work';
        default:
          return 'Engagement task';
      }
    } else if (taskId.startsWith('rec_')) {
      switch (taskId) {
        case 'rec_1':
          return 'Set boundaries around your time';
        case 'rec_2':
          return 'Take a sabbatical or retreat';
        case 'rec_3':
          return 'Evaluate your current commitments';
        case 'rec_4':
          return 'Reconnect with your core motivation';
        case 'rec_5':
          return 'Simplify your commitments';
        default:
          return 'Recalibration task';
      }
    }
    return 'Assessment task';
  }

  String _getTaskDescription(String taskId) {
    // Simplified mapping - in production, this would look up from a catalog
    if (taskId.startsWith('dev_')) {
      return 'A development step to grow in your calling';
    } else if (taskId.startsWith('eng_')) {
      return 'An engagement step to apply your calling';
    } else if (taskId.startsWith('rec_')) {
      return 'A recalibration step to realign your focus';
    }
    return 'A task from your assessment action plan';
  }

  String _getTaskCategory(String taskId) {
    // Map task ID to commitment category
    if (taskId.startsWith('dev_')) return 'growth';
    if (taskId.startsWith('eng_')) return 'discipline';
    if (taskId.startsWith('rec_')) return 'charity';
    return 'growth';
  }

  MissionFocusType _recommendedMissionFocus(CommitmentCategory category) {
    return switch (category) {
      CommitmentCategory.charity => MissionFocusType.service,
      CommitmentCategory.discipline => MissionFocusType.faithSharing,
      CommitmentCategory.growth => MissionFocusType.encouragement,
    };
  }

  Future<void> registerDailyCheckIn(DateTime day, {int? integrityScore}) async {
    final normalized = DateTime(day.year, day.month, day.day);
    final previous = state.lastCheckIn;

    if (previous != null) {
      final previousDay = DateTime(previous.year, previous.month, previous.day);
      if (previousDay == normalized) {
        return;
      }
    }

    var streak = 1;
    var daysSincePrevious = 0;
    if (previous != null) {
      final previousDay = DateTime(previous.year, previous.month, previous.day);
      final difference = normalized.difference(previousDay).inDays;
      daysSincePrevious = difference;
      streak = difference == 1 ? state.streakCount + 1 : 1;
    }

    final nextLongestStreak = streak > state.longestStreakCount
        ? streak
        : state.longestStreakCount;

    var next = state.copyWith(
      streakCount: streak,
      longestStreakCount: nextLongestStreak,
      lastCheckIn: normalized,
      lastIntegrityScore: integrityScore ?? state.lastIntegrityScore,
      lastIntegrityDate: integrityScore != null
          ? normalized
          : state.lastIntegrityDate,
    );

    // -----------------------------------------------------------------------
    // Achievements (Phase 4.3A)
    // -----------------------------------------------------------------------

    // Streak milestones
    if (streak >= 3) {
      next = _unlockBadge(next, 'streak_3', normalized);
    }
    if (streak >= 7) {
      next = _unlockBadge(next, 'streak_7', normalized);
    }
    if (streak >= 14) {
      next = _unlockBadge(next, 'streak_14', normalized);
    }

    // Integrity milestones (only if score was passed for this check-in)
    if (integrityScore != null) {
      if (integrityScore >= 8) {
        next = _unlockBadge(next, 'integrity_8', normalized);
      }
      if (integrityScore >= 12) {
        next = _unlockBadge(next, 'integrity_12', normalized);
      }
    }

    // Comeback: user returns after a gap of >= 2 days.
    if (daysSincePrevious >= 2) {
      next = _unlockBadge(next, 'comeback', normalized);
    }

    state = next;
    await _storage.save(next);

    // Award XP for daily check-in
    await XPService.instance.addXP(
      type: XPActivityType.dailyCheckIn,
      description: 'Daily check-in completed',
      metadata: {'date': normalized.toIso8601String(), 'streak': streak},
    );
    _analytics.track(
      AppAnalyticsEvent.dailyCheckInCompleted,
      properties: {'date': normalized, 'streak': streak},
    );

    // Reschedule notifications to cancel the 4pm reminder since they've checked in
    unawaited(_syncNotifications(next));
  }

  Future<void> markCommitmentWelcomeSeen() async {
    final next = state.copyWith(hasSeenCommitmentWelcome: true);
    state = next;
    await _storage.save(next);
  }

  Future<void> markTodayWelcomeSeen() async {
    final next = state.copyWith(hasSeenTodayWelcome: true);
    state = next;
    await _storage.save(next);
  }

  Future<void> markPostOnboardingComplete() async {
    final next = state.copyWith(hasCompletedPostOnboarding: true);
    state = next;
    await _persistWithRetry(next);
  }

  Future<void> setCompanionCharacter(String code) async {
    final next = state.copyWith(companionCharacterCode: code);
    state = next;
    await _persistWithRetry(next);
  }

  Future<void> setChristianLifeBaseline(ChristianLifeBaseline baseline) async {
    final next = state.copyWith(christianLifeBaseline: baseline);
    state = next;
    await _persistWithRetry(next);
  }

  /// Record the Phase 2 habit-catalog selections. These are orthogonal to
  /// archetype-derived distractions — they reflect the user's own report
  /// of what they already practice and what they're working against.
  Future<void> setGoodHabits(List<String> keys) async {
    final next = state.copyWith(goodHabits: keys);
    state = next;
    await _persistWithRetry(next);
  }

  Future<void> setStruggles(List<String> keys) async {
    final next = state.copyWith(struggles: keys);
    state = next;
    await _persistWithRetry(next);
  }

  Future<void> setAccountabilityCadence(String cadence) async {
    final normalized = cadence == 'weekly' ? 'weekly' : 'daily';
    final next = state.copyWith(accountabilityCadence: normalized);
    state = next;
    await _persistWithRetry(next);
  }

  Future<void> setAccountabilityTone(AccountabilityTone tone) async {
    final next = state.copyWith(accountabilityTone: tone);
    state = next;
    await _persistWithRetry(next);
  }

  Future<void> setSoundEnabled(bool enabled) async {
    final next = state.copyWith(soundEnabled: enabled);
    state = next;
    await _persistWithRetry(next);
  }

  Future<void> markWelcomeShownForToday() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final next = state.copyWith(lastWelcomeDate: today);
    state = next;
    await _persistWithRetry(next);
  }

  Future<void> setCompassSeasonSignal({
    required String archetype,
    required int supportScore,
    required AccountabilityTone accountabilityTone,
  }) async {
    final boundedScore = supportScore.clamp(0, 100).toInt();
    final next = state.copyWith(
      primaryArchetypeId: archetype,
      selectedArchetypeIds: [archetype],
      spiritualAgeScore: boundedScore,
      spiritualAgeStage: _formationStageForSupport(boundedScore),
      accountabilityTone: accountabilityTone,
    );
    state = next;
    await _persistWithRetry(next);
  }

  String _formationStageForSupport(int supportScore) {
    if (supportScore >= 72) return 'Structured';
    if (supportScore >= 58) return 'Strengthening';
    if (supportScore >= 45) return 'Forming';
    return 'Restoring';
  }

  /// Persist the serialized onboarding draft. Called on every
  /// `OnboardingNotifier` state mutation so app-kill mid-onboarding doesn't
  /// lose baseline answers or archetype selections.
  Future<void> setOnboardingDraft(String draft) async {
    final next = state.copyWith(onboardingDraft: draft);
    state = next;
    await _storage.save(next);
  }

  /// Wipe the onboarding draft. Called after signup succeeds so a completed
  /// user can never rehydrate stale in-progress state on next launch.
  Future<void> clearOnboardingDraft() async {
    if (state.onboardingDraft == null) return;
    final next = state.copyWith(clearOnboardingDraft: true);
    state = next;
    await _storage.save(next);
  }

  Future<void> setPendingCompassSubmission(Map<String, dynamic> payload) async {
    final next = state.copyWith(pendingCompassSubmission: payload);
    state = next;
    await _storage.save(next);
  }

  Future<void> clearPendingCompassSubmission() async {
    if (state.pendingCompassSubmission == null) return;
    final next = state.copyWith(clearPendingCompassSubmission: true);
    state = next;
    await _storage.save(next);
  }

  Future<void> setFirstCheckInPlan({
    required int commitmentId,
    String? when,
    String? obstacle,
  }) async {
    final normalizedWhen = when?.trim();
    final normalizedObstacle = obstacle?.trim();
    final next = state.copyWith(
      firstCheckInPlanCommitmentId: commitmentId,
      firstCheckInPlanWhen: normalizedWhen == null || normalizedWhen.isEmpty
          ? ''
          : normalizedWhen,
      firstCheckInPlanObstacle:
          normalizedObstacle == null || normalizedObstacle.isEmpty
          ? ''
          : normalizedObstacle,
    );
    state = next;
    await _storage.save(next);
  }

  Future<void> startCommitmentReviewSeason({
    required DateTime startedAt,
    CommitmentMonthlyReviewOutcome? outcome,
  }) async {
    final normalizedStart = DateTime(
      startedAt.year,
      startedAt.month,
      startedAt.day,
    );
    final next = state.copyWith(
      currentCommitmentSeasonStartedAt: normalizedStart,
      nextCommitmentReviewAt: DateTime(
        normalizedStart.year,
        normalizedStart.month + 1,
        normalizedStart.day,
      ),
      commitmentMonthlyReviewOutcome: outcome,
    );
    state = next;
    await _storage.save(next);
  }

  Future<void> completeCommitmentMonthlyReview(
    CommitmentMonthlyReviewOutcome outcome, {
    DateTime? reviewedAt,
  }) async {
    final day = reviewedAt ?? DateTime.now();
    final normalized = DateTime(day.year, day.month, day.day);
    final next = state.copyWith(
      lastCommitmentReviewAt: normalized,
      nextCommitmentReviewAt: DateTime(
        normalized.year,
        normalized.month + 1,
        normalized.day,
      ),
      commitmentMonthlyReviewOutcome: outcome,
    );
    state = next;
    await _storage.save(next);
  }

  Future<void> clearFirstCheckInPlan() async {
    if (state.firstCheckInPlanCommitmentId == null &&
        state.firstCheckInPlanWhen == null &&
        state.firstCheckInPlanObstacle == null) {
      return;
    }
    final next = state.copyWith(clearFirstCheckInPlan: true);
    state = next;
    await _storage.save(next);
  }

  Future<void> markAssessmentPromptSeen() async {
    final next = state.copyWith(hasSeenAssessmentPrompt: true);
    state = next;
    await _storage.save(next);
  }

  Future<void> setCommitmentCategory(String category) async {
    final next = state.copyWith(
      commitmentCategory: CommitmentCategory.normalizeStorageValue(category),
    );
    state = next;
    await _storage.save(next);
  }

  Future<void> setPrimaryMissionFocus(String focus) async {
    final next = state.copyWith(
      primaryMissionFocus: MissionFocusTypeX.normalizeStorageValue(focus),
    );
    state = next;
    await _storage.save(next);
  }

  Future<void> setMissionActions(List<MissionAction> actions) async {
    final next = state.copyWith(missionActions: actions);
    state = next;
    await _storage.save(next);
  }

  /// Merges user-selected distractions into the calling profile.
  /// Adds to (not replaces) any archetype-derived distractions already present.
  Future<void> setPersonalDistractions(List<String> distractions) async {
    final profile = state.callingProfile;
    if (profile == null || distractions.isEmpty) return;
    final merged = {...profile.personalDistractions, ...distractions}.toList();
    final next = state.copyWith(
      callingProfile: profile.copyWith(personalDistractions: merged),
    );
    state = next;
    await _storage.save(next);
  }

  Future<void> setPersonProfiles(List<PersonProfile> profiles) async {
    final next = state.copyWith(personProfiles: profiles);
    state = next;
    await _storage.save(next);
  }

  Future<void> setCurrentWeeklyPlan(WeeklyPlan weeklyPlan) async {
    final next = state.copyWith(currentWeeklyPlan: weeklyPlan);
    state = next;
    await _storage.save(next);
  }

  /// Check if the current weekly plan is stale (from a previous week).
  /// Returns true if a new plan is needed — callers should show a prompt card
  /// rather than silently generating a new plan.
  bool get needsWeeklyPlanRefresh {
    final profile = state.callingProfile;
    if (profile == null) return false;

    final today = DateTime.now();
    final weekStart = _startOfWeek(today);
    final currentWeeklyPlan = state.currentWeeklyPlan;
    return currentWeeklyPlan?.id != WeeklyPlan.generateId(weekStart);
  }

  /// Generate and save a weekly plan. Called explicitly after user interaction
  /// (e.g., from the weekly assessment screen), not automatically.
  Future<void> refreshWeeklyPlanIfNeeded({DateTime? now}) async {
    final profile = state.callingProfile;
    if (profile == null) {
      return;
    }

    final today = now ?? DateTime.now();
    final weekStart = _startOfWeek(today);
    final currentWeeklyPlan = state.currentWeeklyPlan;
    if (currentWeeklyPlan?.id == WeeklyPlan.generateId(weekStart)) {
      return;
    }

    final weeklyPlan = _callingProfileService.generateWeeklyPlan(
      profile: profile,
      weekStart: weekStart,
      morningTime: state.morningTime,
      eveningTime: state.eveningTime,
    );

    final next = state.copyWith(currentWeeklyPlan: weeklyPlan);
    state = next;
    await _storage.save(next);
  }

  Future<void> setSpiritualPulseForDate(
    DateTime date,
    SpiritualPulseResponse response,
  ) async {
    final key = _dayKey(date);
    final nextPulseByDate = Map<String, SpiritualPulseResponse>.from(
      state.spiritualPulseByDate,
    )..[key] = response;
    final next = state.copyWith(spiritualPulseByDate: nextPulseByDate);
    state = next;
    await _storage.save(next);
  }

  Future<void> setAccountabilityPartner(AccountabilityPartner partner) async {
    final next = state.copyWith(accountabilityPartner: partner);
    state = next;
    await _storage.save(next);
  }

  Future<void> clearAccountabilityPartner() async {
    final next = state.copyWith(clearAccountabilityPartner: true);
    state = next;
    await _storage.save(next);
  }

  Future<void> updatePhoneSetupCompleted(bool completed) async {
    final next = state.copyWith(hasCompletedPhoneSetup: completed);
    state = next;
    await _storage.save(next);
  }

  Future<void> updateReminderPreferences({
    String? morningTime,
    String? eveningTime,
    bool? morningReminderEnabled,
    bool? eveningReminderEnabled,
  }) async {
    final next = state.copyWith(
      morningTime: morningTime ?? state.morningTime,
      eveningTime: eveningTime ?? state.eveningTime,
      morningReminderEnabled:
          morningReminderEnabled ?? state.morningReminderEnabled,
      eveningReminderEnabled:
          eveningReminderEnabled ?? state.eveningReminderEnabled,
    );
    state = next;
    await _storage.save(next);
    await _syncNotifications(
      next,
      requestPermissions:
          morningReminderEnabled == true || eveningReminderEnabled == true,
    );
  }

  Future<void> _syncNotifications(
    AppSettings settings, {
    bool requestPermissions = false,
  }) async {
    try {
      final notificationService = NotificationService();
      final wantsDailyReminders =
          settings.morningReminderEnabled || settings.eveningReminderEnabled;
      final wantsAnyNotification =
          wantsDailyReminders || settings.onboardingCompleted;

      final notificationsAllowed = requestPermissions && wantsAnyNotification
          ? await notificationService.requestPermissions()
          : await notificationService.areNotificationsEnabled();

      if (!notificationsAllowed) {
        await notificationService.cancelDailyReminders();
        await notificationService.cancelNotification(3);
        return;
      }

      await notificationService.scheduleDailyReminders(
        morningTime: settings.morningTime,
        eveningTime: settings.eveningTime,
        morningEnabled: settings.morningReminderEnabled,
        eveningEnabled: settings.eveningReminderEnabled,
      );

      // 4pm Check-in Reminder (if user hasn't checked in today)
      await _scheduleCheckInReminder(settings, notificationService);
    } catch (e) {
      // Notification sync is supportive, never launch-critical.
      // Permission prompts are only requested from explicit reminder actions.
    }
  }

  Future<void> _scheduleCheckInReminder(
    AppSettings settings,
    NotificationService notificationService,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if user has already checked in today
    final hasCheckedInToday =
        settings.lastCheckIn != null &&
        DateTime(
              settings.lastCheckIn!.year,
              settings.lastCheckIn!.month,
              settings.lastCheckIn!.day,
            ) ==
            today;

    if (hasCheckedInToday) {
      // Cancel the 4pm reminder if they've already checked in
      await notificationService.cancelNotification(3);
      return;
    }

    // Schedule 4pm reminder for today or next valid day
    DateTime fourPm = DateTime(now.year, now.month, now.day, 16, 0, 0);

    // If 4pm has already passed today, schedule for tomorrow
    if (!now.isBefore(fourPm)) {
      fourPm = fourPm.add(const Duration(days: 1));
    }

    await notificationService.scheduleNotificationWithActions(
      id: 3, // Check-in reminder ID
      title: 'Daily Commitment',
      body: 'How\'s your day going? Check in when you\'re ready.',
      channel: 'daily_rhythm',
      scheduledTime: fourPm,
      payload: 'check_in_reminder',
      actionLabels: ['I did this', 'Journal'],
      // Recur every day at this wall-clock time. Without this the 4pm nudge
      // fires once and is gone — the user only gets reminded on the exact
      // day the schedule was set.
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  DateTime _startOfWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  String _dayKey(DateTime date) {
    return DateTime(date.year, date.month, date.day).toIso8601String();
  }

  // ===========================================================================
  // Kingdom Action Depth Persistence
  // ===========================================================================

  Future<void> setPersonCommitments(List<PersonCommitment> commitments) async {
    final next = state.copyWith(personCommitments: commitments);
    state = next;
    await _storage.save(next);
  }

  Future<void> setGenerosityRecords(List<GenerosityRecord> records) async {
    final next = state.copyWith(generosityRecords: records);
    state = next;
    await _storage.save(next);
  }

  Future<void> setEvangelismConversations(
    List<EvangelismConversation> conversations,
  ) async {
    final next = state.copyWith(evangelismConversations: conversations);
    state = next;
    await _storage.save(next);
  }

  @override
  void dispose() {
    NotificationService().setDailyCheckInActionHandler(null);
    super.dispose();
  }
}
