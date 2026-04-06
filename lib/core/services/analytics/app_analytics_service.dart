import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:logger/logger.dart';

class AppAnalyticsEvent {
  const AppAnalyticsEvent._();

  // Onboarding
  static const onboardingStarted = 'onboarding_started';
  static const onboardingStepCompleted = 'onboarding_step_completed';
  static const onboardingCompleted = 'onboarding_completed';

  // Assessment
  static const assessmentStarted = 'assessment_started';
  static const assessmentCompleted = 'assessment_completed';

  // Daily engagement
  static const dailyCheckInCompleted = 'daily_check_in_completed';
  static const firstWeekAction = 'first_week_action';

  // Mission
  static const missionFocusSelected = 'mission_focus_selected';
  static const missionActionCreated = 'mission_action_created';
  static const missionActionCompleted = 'mission_action_completed';

  // Accountability
  static const accountabilityPartnerSaved = 'accountability_partner_saved';
  static const accountabilityCheckInLogged = 'accountability_check_in_logged';
  static const accountabilityCheckInRequested = 'accountability_check_in_requested';
  static const accountabilityCheckInConfirmed = 'accountability_check_in_confirmed';

  // Social
  static const inviteInitiated = 'invite_initiated';
  static const inviteCompleted = 'invite_completed';

  // Feature usage
  static const bibleReadingOpened = 'bible_reading_opened';
  static const journalEntryCreated = 'journal_entry_created';
  static const meditationStarted = 'meditation_started';
  static const meditationCompleted = 'meditation_completed';
}

class AppAnalyticsService {
  AppAnalyticsService(this._logger, this._analytics);

  final Logger _logger;
  final FirebaseAnalytics _analytics;

  void track(
    String eventName, {
    Map<String, Object?> properties = const {},
  }) {
    final normalized = <String, Object>{};
    for (final entry in properties.entries) {
      final value = entry.value;
      if (value == null) {
        // Skip null values
        continue;
      } else if (value is DateTime) {
        normalized[entry.key] = value.toIso8601String();
      } else {
        normalized[entry.key] = value;
      }
    }

    // Keep console logging as fallback for debugging
    _logger.i('analytics:$eventName ${normalized.isEmpty ? '{}' : normalized}');

    // Send to Firebase Analytics
    _analytics.logEvent(
      name: eventName,
      parameters: normalized,
    );
  }
}
