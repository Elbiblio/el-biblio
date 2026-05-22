import 'dart:async';
import 'dart:convert';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:logger/logger.dart';

class AppAnalyticsEvent {
  const AppAnalyticsEvent._();

  // ==================== ONBOARDING & DISCOVERY ====================
  static const onboardingStarted = 'onboarding_started';
  static const onboardingStepCompleted = 'onboarding_step_completed';
  static const onboardingCompleted = 'onboarding_completed';

  // Assessment / Calling Discovery
  static const assessmentStarted = 'assessment_started';
  static const assessmentCompleted = 'assessment_completed';
  static const callingProfileCreated = 'calling_profile_created';
  static const callingProfileViewed = 'calling_profile_viewed';
  static const assessmentPromptShown = 'assessment_prompt_shown';
  static const assessmentPromptDismissed = 'assessment_prompt_dismissed';

  // ==================== DAILY ALIGNMENT (TODAY SCREEN) ====================
  static const todayScreenViewed = 'today_screen_viewed';
  static const dailyAnchorStarted = 'daily_anchor_started';
  static const dailyAnchorCompleted = 'daily_anchor_completed';
  static const virtueMarkedDone = 'virtue_marked_done';
  static const habitCommitmentStarted = 'habit_commitment_started';
  static const habitCommitmentCompleted = 'habit_commitment_completed';
  static const energyActionCompleted = 'energy_action_completed';
  static const prayerGuideUsed = 'prayer_guide_used';
  static const soulCareDialogOpened = 'soul_care_dialog_opened';
  static const soulCareToolUsed = 'soul_care_tool_used';
  static const quickActionTapped = 'quick_action_tapped';

  // Weekly Planning
  static const weeklyPlanViewed = 'weekly_plan_viewed';
  static const weeklyPrioritySet = 'weekly_priority_set';
  static const weeklyCheckInCompleted = 'weekly_check_in_completed';

  // ==================== SCRIPTURE & LEARNING (ALIGN) ====================
  static const bibleReadingOpened = 'bible_reading_opened';
  static const bibleChapterCompleted = 'bible_chapter_completed';
  static const readingPlanStarted = 'reading_plan_started';
  static const readingPlanCompleted = 'reading_plan_completed';
  static const verseHighlighted = 'verse_highlighted';
  static const verseBookmarked = 'verse_bookmarked';
  static const verseCompared = 'verse_compared';
  static const bibleSearchUsed = 'bible_search_used';

  // ==================== REFLECTION (REFLECT) ====================
  static const journalEntryCreated = 'journal_entry_created';
  static const journalEntryEdited = 'journal_entry_edited';
  static const journalEntryDeleted = 'journal_entry_deleted';
  static const journalOpenedFromBible = 'journal_opened_from_bible';

  // Meditation
  static const meditationStarted = 'meditation_started';
  static const meditationCompleted = 'meditation_completed';
  static const meditationStyleSelected = 'meditation_style_selected';
  static const meditationPaused = 'meditation_paused';
  static const meditationResumed = 'meditation_resumed';

  // ==================== KINGDOM ACTION (ACT) ====================
  static const actScreenViewed = 'act_screen_viewed';
  static const serviceOpportunityViewed = 'service_opportunity_viewed';
  static const serviceCommitmentCreated = 'service_commitment_created';
  static const serviceActionLogged = 'service_action_logged';
  static const evangelismHelperUsed = 'evangelism_helper_used';
  static const faithConversationPrepared = 'faith_conversation_prepared';
  static const personPrayedFor = 'person_prayed_for';
  static const impactMemoryCreated = 'impact_memory_created';
  static const impactHistoryViewed = 'impact_history_viewed';

  // Mission
  static const missionFocusSelected = 'mission_focus_selected';
  static const missionActionCreated = 'mission_action_created';
  static const missionActionCompleted = 'mission_action_completed';
  static const personProfileViewed = 'person_profile_viewed';

  // ==================== COMMUNITY & GROWTH (GROW TOGETHER) ====================
  static const growTogetherScreenViewed = 'grow_together_screen_viewed';
  static const accountabilityPartnerAdded = 'accountability_partner_added';
  static const accountabilityCheckInLogged = 'accountability_check_in_logged';
  static const accountabilityCheckInRequested =
      'accountability_check_in_requested';
  static const accountabilityCheckInConfirmed =
      'accountability_check_in_confirmed';
  static const communityPrayerShared = 'community_prayer_shared';

  // Social
  static const inviteInitiated = 'invite_initiated';
  static const inviteCompleted = 'invite_completed';
  static const contactSyncStarted = 'contact_sync_started';
  static const contactSyncCompleted = 'contact_sync_completed';

  // ==================== TOOLS & FEATURES ====================
  static const spiritualAidUsed = 'spiritual_aid_used';
  static const alignmentHubOpened = 'alignment_hub_opened';
  static const faithQuestionsOpened = 'faith_questions_opened';
  static const gamePlayed = 'game_played';
  static const appLockEnabled = 'app_lock_enabled';
  static const reminderSettingsChanged = 'reminder_settings_changed';

  // ==================== APP LIFECYCLE ====================
  static const appOpened = 'app_opened';
  static const appBackgrounded = 'app_backgrounded';
  static const notificationReceived = 'notification_received';
  static const notificationTapped = 'notification_tapped';

  // Legacy/deprecated constants for backward compatibility
  static const dailyCheckInCompleted = 'daily_check_in_completed';
  static const accountabilityPartnerSaved = 'accountability_partner_saved';
  static const day7Retention = 'day_7_retention';
  static const day30Retention = 'day_30_retention';
  static const streak3Days = 'streak_3_days';
  static const streak7Days = 'streak_7_days';
  static const streak30Days = 'streak_30_days';
}

class AppAnalyticsService {
  AppAnalyticsService(this._logger, this._analytics);

  final Logger _logger;
  final FirebaseAnalytics _analytics;

  void track(String eventName, {Map<String, Object?> properties = const {}}) {
    final normalized = <String, Object>{};
    for (final entry in properties.entries) {
      final value = _normalizeParameter(entry.value);
      if (value != null) {
        normalized[entry.key] = value;
      }
    }

    // Keep console logging as fallback for debugging
    _logger.i('analytics:$eventName ${normalized.isEmpty ? '{}' : normalized}');

    // Send to Firebase Analytics
    try {
      unawaited(
        _analytics.logEvent(name: eventName, parameters: normalized).catchError(
          (Object error, StackTrace stackTrace) {
            _logger.w(
              'Firebase analytics event failed: $eventName',
              error: error,
              stackTrace: stackTrace,
            );
          },
        ),
      );
    } catch (error, stackTrace) {
      _logger.w(
        'Firebase analytics event rejected: $eventName',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Object? _normalizeParameter(Object? value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) return value;
    if (value is int) return value;
    if (value is double && value.isFinite) return value;
    if (value is num && value.isFinite) return value;
    if (value is bool) return value ? 1 : 0;
    if (value is DateTime) return value.toIso8601String();

    if (value is Iterable) {
      final encoded = value
          .where((item) => item != null)
          .map((item) => item is DateTime ? item.toIso8601String() : '$item')
          .where((item) => item.isNotEmpty)
          .join(',');
      return encoded.isEmpty ? null : encoded;
    }

    if (value is Map) {
      final encoded = jsonEncode(value);
      return encoded.isEmpty || encoded == '{}' ? null : encoded;
    }

    final fallback = '$value';
    return fallback.isEmpty ? null : fallback;
  }
}
