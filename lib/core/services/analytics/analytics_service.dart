import 'package:flutter/material.dart';

/// Core analytics events for El-Biblio product tracking
/// 
/// Tracks user behavior across the product spine:
/// - Discover: Assessment completion, profile views
/// - Align: Daily anchor completion, streaks
/// - Act: Service actions, evangelism, impact logging
/// - Reflect: Journal entries, meditation sessions
/// - Grow: Community engagement, accountability

enum AnalyticsEvent {
  // Onboarding & Discovery
  onboardingStarted,
  onboardingCompleted,
  onboardingStepViewed,
  assessmentStarted,
  assessmentCompleted,
  callingProfileViewed,
  
  // Daily Alignment (Today Screen)
  dailyAnchorStarted,
  dailyAnchorCompleted,
  virtueMarkedDone,
  habitCommitmentStarted,
  habitCommitmentCompleted,
  energyActionCompleted,
  prayerGuideUsed,
  
  // Scripture & Learning
  bibleReadingStarted,
  bibleChapterCompleted,
  readingPlanStarted,
  readingPlanCompleted,
  verseHighlighted,
  verseBookmarked,
  
  // Reflection
  journalEntryCreated,
  journalEntryEdited,
  journalEntryDeleted,
  meditationSessionStarted,
  meditationSessionCompleted,
  meditationStyleSelected,
  
  // Action (Kingdom Impact)
  actScreenViewed,
  serviceOpportunityViewed,
  serviceCommitmentCreated,
  serviceActionLogged,
  evangelismHelperUsed,
  faithConversationPrepared,
  personPrayedFor,
  impactMemoryCreated,
  
  // Community & Growth
  growTogetherScreenViewed,
  accountabilityPartnerAdded,
  weeklyCheckInCompleted,
  communityPrayerShared,
  inviteSent,
  
  // Tools & Features
  soulCareDialogOpened,
  soulCareToolUsed,
  quickActionTapped,
  spiritualAidUsed,
  gamePlayed,
  
  // App Lifecycle
  appOpened,
  appClosed,
  reminderReceived,
  reminderTapped,
}

/// Severity/Importance level for product events
enum EventPriority { debug, info, important, critical }

/// Properties map for event context
typedef EventProperties = Map<String, dynamic>;

/// Analytics service interface for El-Biblio
/// 
/// Implementations can wrap Firebase Analytics, Amplitude, Mixpanel,
/// or a custom backend. This interface keeps the app decoupled.
abstract class AnalyticsService {
  /// Initialize the analytics service
  Future<void> initialize();
  
  /// Track a named event with optional properties
  void trackEvent(String name, {EventProperties? properties});
  
  /// Track a typed analytics event
  void track(AnalyticsEvent event, {EventProperties? properties, EventPriority priority = EventPriority.info});
  
  /// Set user properties for segmentation
  void setUserProperties(EventProperties properties);
  
  /// Identify the current user
  void identifyUser(String userId);
  
  /// Reset identity on logout
  void resetIdentity();
  
  /// Flush any pending events (for batching implementations)
  Future<void> flush();
}

/// Debug analytics implementation that logs to console
/// Used in development or when analytics are disabled
class DebugAnalyticsService implements AnalyticsService {
  bool _enabled = true;
  String? _currentUserId;
  EventProperties _userProperties = {};
  
  @override
  Future<void> initialize() async {
    debugPrint('[Analytics] Debug service initialized');
  }
  
  @override
  void trackEvent(String name, {EventProperties? properties}) {
    if (!_enabled) return;
    
    final props = properties ?? {};
    final timestamp = DateTime.now().toIso8601String();
    
    debugPrint('[Analytics] $timestamp | $name | ${props.toString()}');
  }
  
  @override
  void track(AnalyticsEvent event, {EventProperties? properties, EventPriority priority = EventPriority.info}) {
    if (!_enabled && priority == EventPriority.debug) return;
    
    final props = {
      'event_name': event.name,
      'priority': priority.name,
      if (_currentUserId != null) 'user_id': _currentUserId,
      ..._userProperties,
      ...?properties,
    };
    
    trackEvent(event.name, properties: props);
  }
  
  @override
  void setUserProperties(EventProperties properties) {
    _userProperties.addAll(properties);
    debugPrint('[Analytics] User properties updated: $properties');
  }
  
  @override
  void identifyUser(String userId) {
    _currentUserId = userId;
    debugPrint('[Analytics] User identified: $userId');
  }
  
  @override
  void resetIdentity() {
    _currentUserId = null;
    _userProperties = {};
    debugPrint('[Analytics] Identity reset');
  }
  
  @override
  Future<void> flush() async {
    debugPrint('[Analytics] Flush called (no-op in debug mode)');
  }
  
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }
}

/// Provider for accessing analytics throughout the app
class Analytics {
  static AnalyticsService _instance = DebugAnalyticsService();
  
  static AnalyticsService get instance => _instance;
  
  /// Configure the analytics implementation
  static void configure(AnalyticsService service) {
    _instance = service;
  }
  
  /// Initialize analytics
  static Future<void> initialize() => _instance.initialize();
  
  /// Track a typed event
  static void track(AnalyticsEvent event, {EventProperties? properties, EventPriority priority = EventPriority.info}) {
    _instance.track(event, properties: properties, priority: priority);
  }
  
  /// Track with raw name
  static void trackEvent(String name, {EventProperties? properties}) {
    _instance.trackEvent(name, properties: properties);
  }
  
  /// Set user properties
  static void setUserProperties(EventProperties properties) => _instance.setUserProperties(properties);
  
  /// Identify user
  static void identifyUser(String userId) => _instance.identifyUser(userId);
  
  /// Reset identity
  static void resetIdentity() => _instance.resetIdentity();
  
  /// Flush events
  static Future<void> flush() => _instance.flush();
}

/// Mixin for widgets that need analytics tracking
/// 
/// Usage:
/// ```dart
/// class MyScreen extends StatelessWidget with AnalyticsMixin {
///   @override
///   String get screenName => 'my_screen';
/// }
/// ```
mixin AnalyticsMixin<T extends StatefulWidget> on State<T> {
  String get screenName;
  AnalyticsEvent? get screenViewEvent => null;
  EventProperties get screenProperties => {};
  
  @override
  void initState() {
    super.initState();
    _trackScreenView();
  }
  
  void _trackScreenView() {
    if (screenViewEvent != null) {
      Analytics.track(screenViewEvent!, properties: {
        'screen_name': screenName,
        ...screenProperties,
      });
    } else {
      Analytics.trackEvent('screen_view', properties: {
        'screen_name': screenName,
        ...screenProperties,
      });
    }
  }
  
  /// Helper to track button taps
  void trackButtonTap(String buttonName, {EventProperties? additionalProps}) {
    Analytics.track(AnalyticsEvent.quickActionTapped, properties: {
      'button_name': buttonName,
      'screen': screenName,
      ...?additionalProps,
    });
  }
}
