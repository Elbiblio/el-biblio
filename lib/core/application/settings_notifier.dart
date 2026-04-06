import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/assessment/application/calling_profile_service.dart';
import '../../features/assessment/domain/models/archetype.dart';
import '../../features/assessment/domain/models/weekly_plan.dart';
import '../../features/mission/domain/models/accountability_partner.dart';
import '../../features/mission/domain/models/mission_action.dart';
import '../../features/mission/domain/models/person_profile.dart';
import '../services/analytics/app_analytics_service.dart';
import '../../features/today/domain/models/daily_anchors.dart';
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

  AppSettings _unlockBadge(AppSettings current, String id, DateTime unlockedAt) {
    if (current.unlockedBadges.containsKey(id)) {
      return current;
    }
    final nextBadges = Map<String, String>.from(current.unlockedBadges)
      ..[id] = unlockedAt.toIso8601String();

    return current.copyWith(unlockedBadges: nextBadges);
  }

  Future<void> _hydrate() async {
    state = await _storage.load();
    _syncNotifications(state);
  }

  Future<void> resetOnboarding() async {
    final next = AppSettings.defaults();
    state = next;
    await _storage.save(next);
    _syncNotifications(next);
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
    await _storage.save(newSettings);
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
  }) async {
    var newSettings = state.copyWith(
      onboardingCompleted: true,
      primaryVirtue: primaryVirtue,
      lifestyle: lifestyle,
      morningTime: morningTime,
      eveningTime: eveningTime,
      morningReminderEnabled: morningReminderEnabled,
      eveningReminderEnabled: eveningReminderEnabled,
      socialPresenceOptIn: socialPresenceOptIn,
      contactsImported: contactsImported,
      primaryArchetypeId: primaryArchetypeId,
      commitmentCategory: commitmentCategory,
      primaryMissionFocus: primaryMissionFocus,
    );

    // Generate calling profile and weekly plan if we have archetype data
    if (primaryArchetypeId != null &&
        commitmentCategory != null &&
        primaryMissionFocus != null) {
      final archetype = Archetype.allArchetypes
          .firstWhere((a) => a.name == primaryArchetypeId);

      final callingProfile = _callingProfileService.generateProfile(
        archetype: archetype,
        commitmentCategory: commitmentCategory,
        missionFocus: primaryMissionFocus,
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
    await _storage.save(newSettings);
    _syncNotifications(newSettings);
    _analytics.track(
      AppAnalyticsEvent.onboardingCompleted,
      properties: {
        'primary_archetype': primaryArchetypeId,
        'commitment_category': commitmentCategory,
        'mission_focus': primaryMissionFocus,
      },
    );
  }

  Future<void> setVirtueFocus({
    required VirtueType primaryVirtue,
  }) async {
    final next = state.copyWith(
      primaryVirtue: primaryVirtue,
    );
    state = next;
    await _storage.save(next);
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
      lastIntegrityDate: integrityScore != null ? normalized : state.lastIntegrityDate,
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
      metadata: {
        'date': normalized.toIso8601String(),
        'streak': streak,
      },
    );
    _analytics.track(
      AppAnalyticsEvent.dailyCheckInCompleted,
      properties: {
        'date': normalized,
        'streak': streak,
      },
    );
    
    // Reschedule notifications to cancel the 4pm reminder since they've checked in
    _syncNotifications(next);
  }

  Future<void> markCommitmentWelcomeSeen() async {
    final next = state.copyWith(hasSeenCommitmentWelcome: true);
    state = next;
    await _storage.save(next);
  }

  Future<void> markAssessmentPromptSeen() async {
    final next = state.copyWith(hasSeenAssessmentPrompt: true);
    state = next;
    await _storage.save(next);
  }

  Future<void> setCommitmentCategory(String category) async {
    final next = state.copyWith(commitmentCategory: category);
    state = next;
    await _storage.save(next);
  }

  Future<void> setPrimaryMissionFocus(String focus) async {
    final next = state.copyWith(primaryMissionFocus: focus);
    state = next;
    await _storage.save(next);
  }

  Future<void> setMissionActions(List<MissionAction> actions) async {
    final next = state.copyWith(missionActions: actions);
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
      morningReminderEnabled: morningReminderEnabled ?? state.morningReminderEnabled,
      eveningReminderEnabled: eveningReminderEnabled ?? state.eveningReminderEnabled,
    );
    state = next;
    await _storage.save(next);
    await _syncNotifications(next);
  }

  Future<void> _syncNotifications(AppSettings settings) async {
    final notificationService = NotificationService();
    
    // Check permissions before scheduling
    await notificationService.requestPermissions();
    // For now, we just continue with scheduling since permissions are handled differently

    await notificationService.scheduleDailyReminders(
      morningTime: settings.morningTime,
      eveningTime: settings.eveningTime,
      morningEnabled: settings.morningReminderEnabled,
      eveningEnabled: settings.eveningReminderEnabled,
    );

    // 4pm Check-in Reminder (if user hasn't checked in today)
    await _scheduleCheckInReminder(settings, notificationService);
  }

  Future<void> _scheduleCheckInReminder(AppSettings settings, NotificationService notificationService) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Check if user has already checked in today
    final hasCheckedInToday = settings.lastCheckIn != null && 
        DateTime(settings.lastCheckIn!.year, settings.lastCheckIn!.month, settings.lastCheckIn!.day) == today;
    
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
      body: 'Have you completed your spiritual anchor today?',
      channel: 'daily_rhythm',
      scheduledTime: fourPm,
      payload: 'check_in_reminder',
      actionLabels: ['I did this', 'Journal'],
    );
  }

  DateTime _startOfWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  String _dayKey(DateTime date) {
    return DateTime(date.year, date.month, date.day).toIso8601String();
  }

  @override
  void dispose() {
    NotificationService().setDailyCheckInActionHandler(null);
    super.dispose();
  }
}
