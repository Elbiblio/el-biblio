import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/app_routes.dart';
import '../../models/accountability_tone.dart';
import '../../../features/today/domain/models/daily_anchors.dart';

enum NotificationActionOutcome { success, fallbackNavigation, failed }

/// Top-level handler for notification taps when the app is in background/terminated.
/// Must be a top-level function (not a class method) for flutter_local_notifications.
@pragma('vm:entry-point')
void _onBackgroundNotificationTapped(NotificationResponse response) {
  // The app is brought to foreground by the OS; we only need to handle
  // action button taps here. Simple notification taps are handled by
  // onDidReceiveNotificationResponse once the app resumes.
  if (response.notificationResponseType ==
      NotificationResponseType.selectedNotificationAction) {
    // Store the action in shared prefs so the app can process it on resume.
    // The service singleton handles this via actionEvents stream when ready.
    debugPrint(
      'NotificationService [BG]: action=${response.actionId} payload=${response.payload}',
    );
  }
}

class NotificationActionEvent {
  const NotificationActionEvent({
    required this.actionId,
    required this.payload,
    required this.outcome,
    required this.timestamp,
    this.error,
  });

  final String actionId;
  final String? payload;
  final NotificationActionOutcome outcome;
  final DateTime timestamp;
  final String? error;
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final Dio _dio = Dio();

  static const String _actionDidThis = 'action_0';
  static const String _actionJournal = 'action_1';
  static const String _actionCommitmentView = 'commitment_view';
  static const String _actionCommitmentDone = 'commitment_done';
  static const String _dailyCheckInCategory = 'daily_check_in';
  static const String _commitmentCategory = 'commitment_lock_in';

  static const int commitmentLockInNotificationId = 40;
  static const int morningReminderId = 1001;
  static const int eveningReminderId = 1002;
  static const int _ledOnMs = 1000;
  static const int _ledOffMs = 500;

  bool _initialized = false;
  bool _platformAvailable = true;
  Future<void> Function()? _dailyCheckInActionHandler;
  final StreamController<NotificationActionEvent> _actionEventsController =
      StreamController<NotificationActionEvent>.broadcast();

  Stream<NotificationActionEvent> get actionEvents =>
      _actionEventsController.stream;

  void setDailyCheckInActionHandler(Future<void> Function()? handler) {
    _dailyCheckInActionHandler = handler;
  }

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();

      const androidInitSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      final iosInitSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        notificationCategories: [
          DarwinNotificationCategory(
            _dailyCheckInCategory,
            actions: <DarwinNotificationAction>[
              DarwinNotificationAction.plain(
                _actionDidThis,
                'I did this ✓',
                options: {DarwinNotificationActionOption.foreground},
              ),
              DarwinNotificationAction.plain(
                _actionJournal,
                'Journal',
                options: {DarwinNotificationActionOption.foreground},
              ),
            ],
          ),
          DarwinNotificationCategory(
            _commitmentCategory,
            actions: <DarwinNotificationAction>[
              DarwinNotificationAction.plain(
                _actionCommitmentView,
                'View',
                options: {DarwinNotificationActionOption.foreground},
              ),
              DarwinNotificationAction.plain(
                _actionCommitmentDone,
                'I did this ✓',
                options: {DarwinNotificationActionOption.foreground},
              ),
            ],
          ),
          // Journey check-in category — was missing, causing action buttons
          // to be invisible on iOS for all journey notifications.
          DarwinNotificationCategory(
            _journeyCategory,
            actions: <DarwinNotificationAction>[
              DarwinNotificationAction.plain(
                'check_in',
                'I kept my commitment ✓',
                options: {DarwinNotificationActionOption.foreground},
              ),
              DarwinNotificationAction.plain(
                'view',
                'View journey',
                options: {DarwinNotificationActionOption.foreground},
              ),
            ],
          ),
        ],
      );

      final initSettings = InitializationSettings(
        android: androidInitSettings,
        iOS: iosInitSettings,
      );

      await _localNotificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
        onDidReceiveBackgroundNotificationResponse:
            _onBackgroundNotificationTapped,
      );

      _initialized = true;
    } catch (e, stackTrace) {
      _platformAvailable = false;
      _initialized = true;
      if (e.toString().contains('LateInitializationError') ||
          e.runtimeType.toString().contains('LateInitializationError')) {
        debugPrint(
          'NotificationService: platform notifications unavailable in this environment.',
        );
      } else {
        debugPrint(
          'NotificationService: Initialization failed: $e\n$stackTrace',
        );
      }
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification actions
    if (response.notificationResponseType ==
            NotificationResponseType.selectedNotificationAction &&
        response.actionId != null) {
      _handleNotificationAction(response.actionId!, response.payload);
    } else {
      // Handle navigation based on payload
      _handleNotificationNavigation(response.payload);
    }
  }

  void _handleNotificationAction(String actionId, String? payload) {
    final context = _getAppContext();
    if (context == null) return;

    try {
      switch (actionId) {
        case _actionDidThis:
          _handleIDidThis(context, payload);
          break;
        case _actionJournal:
          _handleJournalAction(context, payload);
          break;
        case _actionCommitmentView:
          _goToRoute(AppRoutes.commit);
          break;
        case _actionCommitmentDone:
          _handleIDidThis(context, payload);
          break;
        default:
          break;
      }
    } catch (e) {
      debugPrint('NotificationService: Action handling error: $e');
    }
  }

  Future<void> _handleIDidThis(BuildContext context, String? payload) async {
    final outcome = await executeDailyCheckInAction(payload: payload);
    if (!context.mounted) {
      return;
    }

    if (outcome == NotificationActionOutcome.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Great work! Your check-in has been recorded.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (outcome == NotificationActionOutcome.fallbackNavigation) {
      _goToRoute(AppRoutes.today);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Great! Complete your check-in on the Today screen.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    _goToRoute(AppRoutes.today);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Could not record check-in automatically. Please confirm it on Today.',
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<NotificationActionOutcome> executeDailyCheckInAction({
    String? payload,
  }) async {
    try {
      if (_dailyCheckInActionHandler == null) {
        _emitActionEvent(
          actionId: _actionDidThis,
          payload: payload,
          outcome: NotificationActionOutcome.fallbackNavigation,
        );
        return NotificationActionOutcome.fallbackNavigation;
      }

      await _dailyCheckInActionHandler!.call();
      _emitActionEvent(
        actionId: _actionDidThis,
        payload: payload,
        outcome: NotificationActionOutcome.success,
      );
      return NotificationActionOutcome.success;
    } catch (e) {
      debugPrint('NotificationService: check-in action failed: $e');
      _emitActionEvent(
        actionId: _actionDidThis,
        payload: payload,
        outcome: NotificationActionOutcome.failed,
        error: e.toString(),
      );
      return NotificationActionOutcome.failed;
    }
  }

  void _emitActionEvent({
    required String actionId,
    required String? payload,
    required NotificationActionOutcome outcome,
    String? error,
  }) {
    _actionEventsController.add(
      NotificationActionEvent(
        actionId: actionId,
        payload: payload,
        outcome: outcome,
        timestamp: DateTime.now(),
        error: error,
      ),
    );
  }

  void _handleJournalAction(BuildContext context, String? payload) {
    // Navigate to journal screen
    _goToRoute('${AppRoutes.journal}/new');

    // Show a hint about the daily commitment
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Write about your daily spiritual experience.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _handleNotificationNavigation(String? payload) {
    if (payload == null) return;

    // Get the current context (this needs to be called from a widget context)
    // For now, we'll use a global navigator key approach
    final context = _getAppContext();
    if (context == null) return;

    try {
      if (payload == 'bible_reading' ||
          payload == 'morning_reminder' ||
          payload == 'evening_reminder') {
        // Navigate to Bible screen
        _goToRoute(AppRoutes.bible);
      } else if (payload.startsWith('bible_reader:')) {
        // Extract book, chapter, verse from payload
        // Format: bible_reader:book=John&chapter=3&verse=16
        final params = payload.substring('bible_reader:'.length);
        _goToRoute('${AppRoutes.bibleReader}?$params');
      } else if (payload == 'daily_verse') {
        // Navigate to today's verse (will be handled by verse provider)
        _goToRoute(AppRoutes.bible);
      } else if (payload == 'check_in_reminder' ||
          payload == 'commitment_locked_in' ||
          payload == 'journey_check_in_reminder' ||
          payload == 'journey_milestone' ||
          payload == 'journey_completed' ||
          payload == 'partner_check_in_request') {
        _goToRoute(AppRoutes.today);
      } else if (payload == 'commitment_check_in' ||
          payload.startsWith('commitment_check_in:') ||
          payload == 'mvp_commitment_check_in' ||
          payload.startsWith('mvp_commitment_check_in:')) {
        _goToRoute(AppRoutes.commit);
      } else if (payload == 'grow_together') {
        _goToRoute(AppRoutes.growTogether);
      } else if (payload == 'companion_partner_checkin') {
        final week = _isoWeekKey(DateTime.now());
        _goToRoute(
          '${AppRoutes.companionChat}?thread=partner-checkin-$week&mode=accountability&title=${Uri.encodeQueryComponent('Weekly check-in')}',
        );
      }
    } catch (e) {
      debugPrint('NotificationService: Navigation error: $e');
    }
  }

  BuildContext? _getAppContext() {
    // This is a simplified approach - in a real app, you'd want to use
    // a proper navigator key or context management system
    return navigatorKey.currentContext;
  }

  void _goToRoute(String route) {
    final context = _getAppContext();
    if (context == null) return;
    GoRouter.of(context).go(route);
  }

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// ISO week key (`YYYY-Www`). Used to scope the companion accountability
  /// thread per week — each Friday opens a fresh thread, avoiding runaway
  /// context from prior weeks.
  static String _isoWeekKey(DateTime date) {
    final thursday = date.add(Duration(days: 4 - date.weekday));
    final firstDayOfYear = DateTime(thursday.year, 1, 1);
    final dayOfYear = thursday.difference(firstDayOfYear).inDays + 1;
    final week = ((dayOfYear - 1) ~/ 7) + 1;
    return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
  }

  tz.TZDateTime _resolveScheduleTime(DateTime scheduledTime) {
    try {
      // Get current device timezone dynamically
      final now = tz.TZDateTime.now(tz.local);
      var resolved = tz.TZDateTime.from(scheduledTime, tz.local);

      // Handle DST transitions and ensure future scheduling
      // Add extra safety margin for timezone changes
      while (!resolved.isAfter(now.add(const Duration(minutes: 5)))) {
        resolved = resolved.add(const Duration(days: 1));
      }

      return resolved;
    } catch (e) {
      debugPrint(
        'NotificationService: Error resolving timezone, falling back to local: $e',
      );
      // Enhanced fallback with better error handling
      try {
        final now = DateTime.now();
        var resolved = DateTime(
          now.year,
          now.month,
          now.day,
          scheduledTime.hour,
          scheduledTime.minute,
        );

        // Ensure future scheduling with buffer
        while (!resolved.isAfter(now.add(const Duration(minutes: 5)))) {
          resolved = resolved.add(const Duration(days: 1));
        }

        return tz.TZDateTime.from(resolved, tz.local);
      } catch (fallbackError) {
        debugPrint(
          'NotificationService: Critical error in timezone fallback: $fallbackError',
        );
        // Last resort - schedule for 24 hours from now
        return tz.TZDateTime.now(tz.local).add(const Duration(hours: 24));
      }
    }
  }

  Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    await _dio.download(url, filePath);
    return filePath;
  }

  Future<void> scheduleNotificationWithActions({
    required int id,
    required String title,
    required String body,
    required String channel,
    DateTime? scheduledTime,
    String? payload,
    List<String>? actionLabels,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    try {
      await initialize();

      final actions = actionLabels
          ?.asMap()
          .entries
          .map(
            (entry) => AndroidNotificationAction(
              'action_${entry.key}',
              entry.value,
              showsUserInterface: true,
            ),
          )
          .toList();

      // Create Android notification details with actions
      final androidDetails = AndroidNotificationDetails(
        channel,
        'Daily Rhythm',
        channelDescription: 'Daily spiritual reminders',
        importance: Importance.high,
        priority: Priority.high,
        color: const Color(0xFF638B6C),
        ledColor: const Color(0xFF638B6C),
        enableLights: true,
        ledOnMs: _ledOnMs,
        ledOffMs: _ledOffMs,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        actions: actions,
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: actionLabels != null && actionLabels.isNotEmpty
            ? _dailyCheckInCategory
            : null,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      if (scheduledTime != null) {
        await _localNotificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: _resolveScheduleTime(scheduledTime),
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: matchDateTimeComponents,
          payload: payload,
        );
      } else {
        await _localNotificationsPlugin.show(
          id: id,
          title: title,
          body: body,
          notificationDetails: notificationDetails,
          payload: payload,
        );
      }
    } catch (e) {
      debugPrint(
        'NotificationService: Error scheduling notification with actions: $e',
      );
    }
  }

  Future<void> scheduleRichNotification({
    required int id,
    required String title,
    required String body,
    required String channel,
    DateTime? scheduledTime,
    String? payload,
    String? largeIcon,
    String? bigPicture,
    bool repeatDaily = false,
  }) async {
    try {
      await initialize();

      String? largeIconPath;
      String? bigPicturePath;

      if (largeIcon != null && largeIcon.startsWith('http')) {
        largeIconPath = await _downloadAndSaveFile(largeIcon, 'largeIcon_$id');
      }

      if (bigPicture != null && bigPicture.startsWith('http')) {
        bigPicturePath = await _downloadAndSaveFile(
          bigPicture,
          'bigPicture_$id',
        );
      }

      AndroidNotificationDetails androidDetails;
      DarwinNotificationDetails iosDetails;

      if (bigPicturePath != null) {
        final bigPictureStyleInformation = BigPictureStyleInformation(
          FilePathAndroidBitmap(bigPicturePath),
          largeIcon: largeIconPath != null
              ? FilePathAndroidBitmap(largeIconPath)
              : null,
          contentTitle: title,
          summaryText: body,
          htmlFormatContentTitle: true,
          htmlFormatSummaryText: true,
        );

        androidDetails = AndroidNotificationDetails(
          channel,
          channel,
          channelDescription: 'Rich Notifications',
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: bigPictureStyleInformation,
        );

        iosDetails = DarwinNotificationDetails(
          attachments: [DarwinNotificationAttachment(bigPicturePath)],
        );
      } else {
        androidDetails = AndroidNotificationDetails(
          channel,
          channel,
          channelDescription: 'Standard Notifications',
          importance: Importance.max,
          priority: Priority.high,
          largeIcon: largeIconPath != null
              ? FilePathAndroidBitmap(largeIconPath)
              : null,
        );

        iosDetails = DarwinNotificationDetails(
          attachments: largeIconPath != null
              ? [DarwinNotificationAttachment(largeIconPath)]
              : null,
        );
      }

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      if (scheduledTime != null) {
        await _localNotificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: _resolveScheduleTime(scheduledTime),
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: repeatDaily ? DateTimeComponents.time : null,
          payload: payload,
        );
      } else {
        await _localNotificationsPlugin.show(
          id: id,
          title: title,
          body: body,
          notificationDetails: notificationDetails,
          payload: payload,
        );
      }
    } catch (e) {
      debugPrint('NotificationService: Error scheduling rich notification: $e');
    }
  }

  Future<void> showCommitmentLockInNotification({
    required String commitmentTitle,
    VirtueType? virtueType,
  }) async {
    try {
      await initialize();

      // Create virtue icon bitmap if virtue type is provided
      AndroidBitmap? virtueIconBitmap;
      if (virtueType != null) {
        virtueIconBitmap = await _createVirtueIconBitmap(virtueType);
      }

      final androidDetails = AndroidNotificationDetails(
        'commitment_player',
        'Commitment Lock-In',
        channelDescription: 'Music player style commitment reminder',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.progress,
        ongoing: true,
        autoCancel: false,
        onlyAlertOnce: true,
        color: _getVirtueColor(virtueType),
        ledColor: _getVirtueColor(virtueType),
        largeIcon: virtueIconBitmap as AndroidBitmap<Object>?,
        styleInformation: const MediaStyleInformation(
          htmlFormatContent: true,
          htmlFormatTitle: true,
        ),
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            _actionCommitmentView,
            'View',
            showsUserInterface: true,
            cancelNotification: false,
            icon: virtueIconBitmap != null
                ? virtueIconBitmap as AndroidBitmap<Object>?
                : null,
          ),
          AndroidNotificationAction(
            _actionCommitmentDone,
            'I did this',
            showsUserInterface: true,
            icon: virtueIconBitmap != null
                ? virtueIconBitmap as AndroidBitmap<Object>?
                : null,
          ),
        ],
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
        threadIdentifier: 'daily_commitment',
        categoryIdentifier: _commitmentCategory,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final title = virtueType != null
          ? 'Afternoon commitment locked in'
          : 'Afternoon commitment locked in';

      final body = virtueType != null
          ? '$commitmentTitle • ${virtueType.title} Focus'
          : commitmentTitle;

      await _localNotificationsPlugin.show(
        id: commitmentLockInNotificationId,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: 'commitment_locked_in',
      );
    } catch (e) {
      debugPrint(
        'NotificationService: Error showing commitment lock-in notification: $e',
      );
    }
  }

  Future<void> cancelCommitmentLockInNotification() async {
    await _localNotificationsPlugin.cancel(id: commitmentLockInNotificationId);
  }

  Future<void> cancelNotification(int id) async {
    await _localNotificationsPlugin.cancel(id: id);
  }

  /// Wipe every scheduled notification owned by this install.
  ///
  /// Call at a login / signup boundary so IDs left over from a previous
  /// tenant of the device (shared phone, re-install, test accounts) cannot
  /// fire at the new user. The caller is responsible for re-scheduling any
  /// notifications the new session still wants.
  Future<void> cancelAll() async {
    try {
      await initialize();
      await _localNotificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('NotificationService: cancelAll failed: $e');
    }
  }

  Future<void> scheduleDailyReminders({
    required String morningTime,
    required String eveningTime,
    required bool morningEnabled,
    required bool eveningEnabled,
  }) async {
    try {
      await initialize();

      // Cancel existing reminders first
      await cancelDailyReminders();

      if (morningEnabled) {
        final morningDateTime = _parseTime(morningTime);
        await _scheduleDailyReminder(
          id: morningReminderId,
          title: 'Morning Anchor',
          body: 'Start your day with Scripture and reflection',
          scheduledTime: morningDateTime,
          payload: 'morning_reminder',
        );
      }

      if (eveningEnabled) {
        final eveningDateTime = _parseTime(eveningTime);
        await _scheduleDailyReminder(
          id: eveningReminderId,
          title: 'Evening Review',
          body: 'Reflect on your day and prepare for tomorrow',
          scheduledTime: eveningDateTime,
          payload: 'evening_reminder',
        );
      }

      // Save scheduled notification info for persistence
      await _saveScheduledReminderInfo(morningEnabled, eveningEnabled);
    } catch (e) {
      debugPrint('NotificationService: Error scheduling daily reminders: $e');
    }
  }

  Future<void> cancelDailyReminders() async {
    try {
      await _localNotificationsPlugin.cancel(id: morningReminderId);
      await _localNotificationsPlugin.cancel(id: eveningReminderId);
    } catch (e) {
      debugPrint('NotificationService: Error cancelling daily reminders: $e');
    }
  }

  // ─── Weekly accountability partner check-in reminder ─────────────────────
  // Fires every Friday at 7pm as a gentle nudge to share weekly progress.

  Future<void> scheduleWeeklyPartnerCheckInReminder({
    required String partnerName,
    bool isAiCompanion = false,
  }) async {
    try {
      await initialize();
      await _localNotificationsPlugin.cancel(id: weeklyPartnerCheckInId);

      final now = tz.TZDateTime.now(tz.local);

      // Find the next Friday at 19:00
      int daysUntilFriday = (DateTime.friday - now.weekday + 7) % 7;
      // If today is Friday but it's already past 19:00, schedule for next Friday
      if (daysUntilFriday == 0 && now.hour >= 19) daysUntilFriday = 7;

      final scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + daysUntilFriday,
        19,
        0,
        0,
      );

      const androidDetails = AndroidNotificationDetails(
        'accountability_weekly',
        'Weekly Partner Check-in',
        channelDescription:
            'Weekly reminder to share progress with your accountability partner',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        color: Color(0xFF638B6C),
        channelShowBadge: true,
        enableVibration: true,
        playSound: true,
        styleInformation: BigTextStyleInformation(
          'Sharing your progress — wins and struggles alike — deepens accountability and grows your faith.',
          htmlFormatBigText: false,
          summaryText: 'El-Biblio',
        ),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        threadIdentifier: 'accountability_weekly',
      );

      await _localNotificationsPlugin.zonedSchedule(
        id: weeklyPartnerCheckInId,
        title: 'Weekly check-in with $partnerName',
        body: 'How did your week go? Take a moment to share your progress.',
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: isAiCompanion ? 'companion_partner_checkin' : 'grow_together',
      );

      debugPrint(
        'NotificationService: Scheduled weekly partner check-in every Friday at 7pm',
      );
    } catch (e) {
      debugPrint(
        'NotificationService: Error scheduling weekly partner check-in: $e',
      );
    }
  }

  Future<void> cancelWeeklyPartnerCheckInReminder() async {
    try {
      await _localNotificationsPlugin.cancel(id: weeklyPartnerCheckInId);
    } catch (e) {
      debugPrint(
        'NotificationService: Error cancelling weekly partner check-in: $e',
      );
    }
  }

  // ─── Companion daily verse ───────────────────────────────────────────────
  // One gentle verse a day, drawn from the companion's preferred book order.
  // The client schedules the shell; content (verse text + reference) is
  // resolved server-side or from the on-device verse pool so the companion
  // voice stays consistent with the active character.

  static const int companionDailyVerseId = 7000;

  Future<void> scheduleCompanionDailyVerse({
    required String companionCode,
    required String companionDisplayName,
    required String deliveryTime,
    required String verseReference,
    required String verseText,
  }) async {
    try {
      await initialize();
      await _localNotificationsPlugin.cancel(id: companionDailyVerseId);

      final scheduledDateTime = _parseTime(deliveryTime);

      final androidDetails = AndroidNotificationDetails(
        'companion_daily_verse',
        'Daily Verse from your Companion',
        channelDescription:
            'A daily Scripture nudge in your companion\'s voice',
        importance: Importance.high,
        priority: Priority.high,
        color: const Color(0xFF638B6C),
        channelShowBadge: true,
        enableVibration: true,
        playSound: true,
        styleInformation: BigTextStyleInformation(
          verseText,
          htmlFormatBigText: false,
          contentTitle: '$companionDisplayName · $verseReference',
          htmlFormatContentTitle: false,
          summaryText: 'El-Biblio',
        ),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        threadIdentifier: 'companion_daily_verse',
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotificationsPlugin.zonedSchedule(
        id: companionDailyVerseId,
        title: '$companionDisplayName · $verseReference',
        body: verseText,
        scheduledDate: _resolveScheduleTime(scheduledDateTime),
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'companion_daily_verse:$companionCode',
      );

      debugPrint(
        'NotificationService: Scheduled companion daily verse ($companionCode) at $deliveryTime',
      );
    } catch (e) {
      debugPrint(
        'NotificationService: Error scheduling companion daily verse: $e',
      );
    }
  }

  Future<void> cancelCompanionDailyVerse() async {
    try {
      await _localNotificationsPlugin.cancel(id: companionDailyVerseId);
    } catch (e) {
      debugPrint(
        'NotificationService: Error cancelling companion daily verse: $e',
      );
    }
  }

  // ─── Adaptive accountability partner check-in ────────────────────────────
  // Default cadence is DAILY. If the user's baseline spiritual level is
  // already strong, we step down to weekly so the nudge doesn't feel noisy.

  /// Schedule the partner check-in at the cadence the user earns.
  /// [cadence] is 'daily' or 'weekly'. Daily fires every evening at 7pm;
  /// weekly fires every Friday at 7pm (legacy behaviour).
  Future<void> scheduleAccountabilityPartnerCheckIn({
    required String partnerName,
    required String cadence,
    bool isAiCompanion = false,
  }) async {
    if (cadence == 'weekly') {
      await scheduleWeeklyPartnerCheckInReminder(
        partnerName: partnerName,
        isAiCompanion: isAiCompanion,
      );
      return;
    }

    // Cancel first; if zonedSchedule throws we end up with zero schedules on
    // the shared id rather than two cadences firing in parallel.
    bool cancelled = false;
    try {
      await initialize();
      await _localNotificationsPlugin.cancel(id: weeklyPartnerCheckInId);
      cancelled = true;

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        19,
        0,
        0,
      );
      if (!scheduledDate.isAfter(now.add(const Duration(minutes: 5)))) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const androidDetails = AndroidNotificationDetails(
        'accountability_daily',
        'Daily Partner Check-in',
        channelDescription:
            'Daily nudge to share today\'s walk with your accountability partner',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        color: Color(0xFF638B6C),
        channelShowBadge: true,
        enableVibration: true,
        playSound: true,
        styleInformation: BigTextStyleInformation(
          'One small share a day — a win, a struggle, a prayer — keeps you both walking together.',
          htmlFormatBigText: false,
          summaryText: 'El-Biblio',
        ),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        threadIdentifier: 'accountability_daily',
      );

      await _localNotificationsPlugin.zonedSchedule(
        id: weeklyPartnerCheckInId,
        title: 'Check in with $partnerName',
        body: 'How did today go? A quick share keeps you both moving.',
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
        // Use exactAllowWhileIdle for reliability parity with morning/evening
        // anchors; an evening partner nudge that silently slips past the user
        // defeats the whole cadence.
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: isAiCompanion ? 'companion_partner_checkin' : 'grow_together',
      );

      debugPrint(
        'NotificationService: Scheduled daily partner check-in at 7pm',
      );
    } catch (e) {
      debugPrint(
        'NotificationService: Error scheduling daily partner check-in: $e (cancelled=$cancelled)',
      );
      // If we cancelled but never successfully scheduled, the id is now empty
      // — which is the safe state. No second cadence can double-fire.
    }
  }

  Future<void> _scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String payload,
  }) async {
    final isMorning = id == morningReminderId;
    final expandedText = isMorning
        ? 'Open Scripture, reflect on today\'s verse, and set your intention for the day.'
        : 'Review what God did today. Journal a moment of faithfulness before you sleep.';

    final androidDetails = AndroidNotificationDetails(
      'daily_reminders',
      'Daily Reminders',
      channelDescription: 'Morning and evening spiritual reminders',
      importance: Importance.high,
      priority: Priority.high,
      color: const Color(0xFF638B6C),
      ledColor: const Color(0xFF638B6C),
      enableLights: true,
      ledOnMs: _ledOnMs,
      ledOffMs: _ledOffMs,
      enableVibration: true,
      playSound: true,
      channelShowBadge: true,
      visibility: NotificationVisibility.public,
      // BigText shows the expanded body when notification is long-pressed/expanded
      styleInformation: BigTextStyleInformation(
        expandedText,
        htmlFormatBigText: false,
        contentTitle: title,
        htmlFormatContentTitle: false,
        summaryText: 'ElBiblio',
        htmlFormatSummaryText: false,
      ),
      // Action buttons for quick interaction without opening the app
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'action_0',
          'I did this ✓',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'action_1',
          'Journal',
          showsUserInterface: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      threadIdentifier: 'daily_reminders',
      categoryIdentifier: _dailyCheckInCategory,
      // iOS 15+: breaks through Focus/Do Not Disturb for spiritual reminders
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _resolveScheduleTime(scheduledTime),
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  // _scheduleBackupNotification was removed: it fired 30 minutes after the
  // scheduling call (not after the actual reminder time), creating a confusing
  // duplicate that appeared mid-morning when the user set a 7 AM reminder.
  // The daily repeat via matchDateTimeComponents: DateTimeComponents.time is
  // sufficient — no backup needed.

  DateTime _parseTime(String timeString) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts.length > 1 ? int.parse(parts[1]) : 0;
    return DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      hour,
      minute,
    );
  }

  Future<void> _saveScheduledReminderInfo(
    bool morningEnabled,
    bool eveningEnabled,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('morning_reminder_scheduled', morningEnabled);
      await prefs.setBool('evening_reminder_scheduled', eveningEnabled);
      await prefs.setString(
        'last_reminder_update',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      debugPrint('NotificationService: Error saving reminder info: $e');
    }
  }

  Future<void> restoreDailyReminders({
    required String morningTime,
    required String eveningTime,
    required bool morningEnabled,
    required bool eveningEnabled,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final morningScheduled =
          prefs.getBool('morning_reminder_scheduled') ?? false;
      final eveningScheduled =
          prefs.getBool('evening_reminder_scheduled') ?? false;
      final lastUpdate = prefs.getString('last_reminder_update');

      if (lastUpdate != null) {
        final updateDate = DateTime.parse(lastUpdate);
        // Only restore if updated within last 24 hours
        if (DateTime.now().difference(updateDate).inHours < 24) {
          if (morningScheduled && morningEnabled) {
            await scheduleDailyReminders(
              morningTime: morningTime,
              eveningTime: eveningTime,
              morningEnabled: true,
              eveningEnabled: false,
            );
          }
          if (eveningScheduled && eveningEnabled) {
            await scheduleDailyReminders(
              morningTime: morningTime,
              eveningTime: eveningTime,
              morningEnabled: false,
              eveningEnabled: true,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('NotificationService: Error restoring daily reminders: $e');
    }
  }

  Future<bool> requestPermissions() async {
    try {
      await initialize();
      if (!_platformAvailable) return false;

      if (Platform.isIOS) {
        await _localNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        return areNotificationsEnabled();
      } else if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _localNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        await androidImplementation?.requestNotificationsPermission();
        return areNotificationsEnabled();
      }
    } catch (e) {
      debugPrint('NotificationService: Error requesting permissions: $e');
    }
    return false;
  }

  Future<bool> areNotificationsEnabled() async {
    try {
      await initialize();
      if (!_platformAvailable) return true;
      if (Platform.isAndroid) {
        final implementation = _localNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        return await implementation?.areNotificationsEnabled() ?? true;
      }
      if (Platform.isIOS) {
        final implementation = _localNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        final permissions = await implementation?.checkPermissions();
        return permissions?.isEnabled ?? false;
      }
    } catch (e) {
      debugPrint('NotificationService: Error checking permissions: $e');
    }
    return false;
  }

  Stream<String> get pushTokenStream => const Stream.empty();
  Stream get pushMessageStream => const Stream.empty();
  String? get currentPushToken => null;

  Future<Map<String, dynamic>> getDeviceInfo() async {
    return {};
  }

  Future<void> subscribeToTopic(String topic) async {}

  Future<void> unsubscribeFromTopic(String topic) async {}

  Future<AndroidBitmap?> _createVirtueIconBitmap(VirtueType virtueType) async {
    try {
      // Create a simple colored circle with virtue icon
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = 96.0; // Notification icon size

      // Draw colored circle background
      final paint = Paint()
        ..color = _getVirtueColor(virtueType)
        ..isAntiAlias = true;

      canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, paint);

      // Draw virtue icon (simplified - using text for now)
      final textPainter = TextPainter(
        text: TextSpan(
          text: _getVirtueIconText(virtueType),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
      );

      final picture = recorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final bytes = byteData.buffer.asUint8List();
        return ByteArrayAndroidBitmap(bytes);
      }
    } catch (e) {
      debugPrint('NotificationService: Error creating virtue icon bitmap: $e');
    }
    return null;
  }

  Color _getVirtueColor(VirtueType? virtueType) {
    if (virtueType == null) return const Color(0xFF638B6C); // Default green

    switch (virtueType) {
      case VirtueType.humility:
        return const Color(0xFF8B5E3C); // Brown
      case VirtueType.love:
        return const Color(0xFFC85F4B); // Red
      case VirtueType.faith:
        return const Color(0xFF638B6C); // Green
      case VirtueType.knowledge:
        return const Color(0xFF4A6FA5); // Blue
    }
  }

  String _getVirtueIconText(VirtueType virtueType) {
    switch (virtueType) {
      case VirtueType.humility:
        return 'H';
      case VirtueType.love:
        return 'L';
      case VirtueType.faith:
        return 'F';
      case VirtueType.knowledge:
        return 'K';
    }
  }

  // ============================================================================
  // COMMITMENT JOURNEY NOTIFICATIONS (3/10/40-day journeys with spiritual copy)
  // ============================================================================

  static const int journeyCheckInBaseId = 3000;
  static const int journeyMilestoneBaseId = 4000;
  static const int journeyCompletionId = 5000;
  static const int weeklyPartnerCheckInId = 6000;
  static const String _journeyCategory = 'commitment_journey';

  /// Schedule 6pm partner check-in request notification.
  /// Asks partner to confirm user's commitment completion.
  Future<void> schedulePartnerCheckInRequest({
    required String partnerName,
    required String userName,
    required String journeyTitle,
    required int currentDay,
    required int totalDays,
  }) async {
    try {
      await initialize();

      const androidDetails = AndroidNotificationDetails(
        'partner_check_ins',
        'Walking Together Check-ins',
        channelDescription:
            'Evening check-in requests for accountability partners',
        importance: Importance.high,
        priority: Priority.high,
        color: Color(0xFF7B68EE),
        ledColor: Color(0xFF7B68EE),
        enableLights: true,
        ledOnMs: _ledOnMs,
        ledOffMs: _ledOffMs,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'confirm',
            'Yes, they did',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            'decline',
            'Not today',
            showsUserInterface: true,
          ),
        ],
      );

      const iosDetails = DarwinNotificationDetails(
        categoryIdentifier: _journeyCategory,
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Spiritual copy for partner notification
      final title = 'Walking together with $userName';
      final body =
          'Day $currentDay of $totalDays: Did they keep their commitment to "$journeyTitle"?';

      // Schedule for 6:00 PM today
      final now = DateTime.now();
      var scheduledTime = DateTime(now.year, now.month, now.day, 18, 0);
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      await _localNotificationsPlugin.zonedSchedule(
        id: journeyCheckInBaseId,
        title: title,
        body: body,
        scheduledDate: _resolveScheduleTime(scheduledTime),
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'partner_check_in_request',
      );
    } catch (e) {
      debugPrint('NotificationService: Error scheduling partner check-in: $e');
    }
  }

  /// Schedule 8pm user fallback check-in notification.
  /// Sent when partner hasn't responded by 8pm.
  Future<void> scheduleUserCheckInReminder({
    required String journeyTitle,
    required int currentDay,
    required int totalDays,
    String? prayerIntention,
  }) async {
    try {
      await initialize();

      final subText = 'Day $currentDay of $totalDays';
      final expandedBody = prayerIntention != null && prayerIntention.isNotEmpty
          ? 'Your intention: "$prayerIntention"\n\nTap to record today\'s faithfulness.'
          : 'Take a moment to reflect and mark today\'s commitment complete.';

      final androidDetails = AndroidNotificationDetails(
        'journey_check_ins',
        'Your Journey Check-ins',
        channelDescription:
            'Evening reminders to check in on your commitment journey',
        importance: Importance.high,
        priority: Priority.high,
        color: const Color(0xFF638B6C),
        ledColor: const Color(0xFF638B6C),
        enableLights: true,
        ledOnMs: _ledOnMs,
        ledOffMs: _ledOffMs,
        enableVibration: true,
        playSound: true,
        channelShowBadge: true,
        visibility: NotificationVisibility.public,
        subText: subText,
        styleInformation: BigTextStyleInformation(
          expandedBody,
          htmlFormatBigText: false,
          summaryText: subText,
        ),
        actions: const <AndroidNotificationAction>[
          AndroidNotificationAction(
            'check_in',
            'I kept my commitment ✓',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            'view',
            'View journey',
            showsUserInterface: true,
          ),
        ],
      );

      const iosDetails = DarwinNotificationDetails(
        categoryIdentifier: _journeyCategory,
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        threadIdentifier: 'journey_check_ins',
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Spiritual copy options - randomly select for variety
      final spiritualTitles = [
        'How did God move today?',
        'Reflect on your journey',
        'Stay faithful to your calling',
        'Day $currentDay awaits your check-in',
      ];

      final spiritualBodies = [
        'Day $currentDay of $totalDays: $journeyTitle',
        if (prayerIntention != null && prayerIntention.isNotEmpty)
          'Remember your intention: "$prayerIntention"',
        'Take a moment to reflect and check in',
      ].where((s) => s.isNotEmpty).join(' • ');

      final title = spiritualTitles[currentDay % spiritualTitles.length];

      // Schedule for 8:00 PM today (2 hours after partner notification)
      final now = DateTime.now();
      var scheduledTime = DateTime(now.year, now.month, now.day, 20, 0);
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      await _localNotificationsPlugin.zonedSchedule(
        id: journeyCheckInBaseId + 1,
        title: title,
        body: spiritualBodies,
        scheduledDate: _resolveScheduleTime(scheduledTime),
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'journey_check_in_reminder',
      );
    } catch (e) {
      debugPrint('NotificationService: Error scheduling user check-in: $e');
    }
  }

  Future<bool> scheduleCommitmentNudges({
    required int commitmentId,
    required String commitmentTitle,
    required String dailyAction,
    required int nudgeCount,
    bool startTomorrow = false,
    String? planWhen,
    String? planObstacle,
    AccountabilityTone accountabilityTone = AccountabilityTone.balanced,
  }) async {
    try {
      await initialize();
      if (!_platformAvailable) {
        return false;
      }
      await cancelCommitmentNudges(commitmentId);

      final boundedCount = _boundedCommitmentNudgeCount(
        nudgeCount,
        accountabilityTone,
      );
      final now = DateTime.now();
      final window = _commitmentNudgeWindow(now, planWhen, accountabilityTone);
      final spanMinutes = window.$2.difference(window.$1).inMinutes;
      final stepMinutes = boundedCount <= 1 || spanMinutes <= 0
          ? 0
          : (spanMinutes / (boundedCount - 1)).round();
      final isFirm = accountabilityTone == AccountabilityTone.firm;

      final androidDetails = AndroidNotificationDetails(
        'commitment_nudges',
        'Commitment nudges',
        channelDescription:
            'Gentle prompts to check in with your active commitment',
        importance: isFirm ? Importance.high : Importance.defaultImportance,
        priority: isFirm ? Priority.high : Priority.defaultPriority,
        color: const Color(0xFF638B6C),
        ledColor: const Color(0xFF638B6C),
        enableLights: isFirm,
        ledOnMs: _ledOnMs,
        ledOffMs: _ledOffMs,
        enableVibration: isFirm,
        playSound: isFirm,
        channelShowBadge: true,
        visibility: NotificationVisibility.public,
        actions: const <AndroidNotificationAction>[
          AndroidNotificationAction(
            _actionCommitmentDone,
            'I did this',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            _actionCommitmentView,
            'View',
            showsUserInterface: true,
          ),
        ],
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        categoryIdentifier: _commitmentCategory,
        presentSound: isFirm,
        threadIdentifier: 'commitment_nudges',
        interruptionLevel: isFirm
            ? InterruptionLevel.timeSensitive
            : InterruptionLevel.active,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      for (var i = 0; i < boundedCount; i++) {
        var scheduledTime = window.$1.add(Duration(minutes: stepMinutes * i));
        if (startTomorrow) {
          scheduledTime = scheduledTime.add(const Duration(days: 1));
        }
        if (scheduledTime.isBefore(now.add(const Duration(minutes: 2)))) {
          scheduledTime = scheduledTime.add(const Duration(days: 1));
        }

        await _localNotificationsPlugin.zonedSchedule(
          id: 7000 + commitmentId * 10 + i,
          title: commitmentTitle,
          body: _commitmentNudgeBody(
            dailyAction: dailyAction,
            planWhen: planWhen,
            planObstacle: planObstacle,
          ),
          scheduledDate: _resolveScheduleTime(scheduledTime),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'commitment_check_in:$commitmentId',
        );
      }
      return true;
    } catch (e) {
      debugPrint('NotificationService: Error scheduling commitment nudges: $e');
      return false;
    }
  }

  String _commitmentNudgeBody({
    required String dailyAction,
    String? planWhen,
    String? planObstacle,
  }) {
    final when = planWhen?.trim();
    final obstacle = planObstacle?.trim();
    final parts = <String>[
      dailyAction,
      if (when != null && when.isNotEmpty) 'Your plan: $when.',
      if (obstacle != null && obstacle.isNotEmpty) 'Watch for: $obstacle.',
    ];
    return parts.join(' ');
  }

  int _boundedCommitmentNudgeCount(int requested, AccountabilityTone tone) {
    return switch (tone) {
      AccountabilityTone.gentle => requested.clamp(1, 3),
      AccountabilityTone.balanced => requested.clamp(3, 6),
      AccountabilityTone.firm => requested.clamp(4, 10),
    };
  }

  (DateTime, DateTime) _commitmentNudgeWindow(
    DateTime now,
    String? planWhen,
    AccountabilityTone tone,
  ) {
    final anchorHour = _planAnchorHour(planWhen);
    final startHourRaw = switch (tone) {
      AccountabilityTone.gentle => (anchorHour - 1).clamp(7, 20),
      AccountabilityTone.balanced => (anchorHour - 3).clamp(7, 19),
      AccountabilityTone.firm => 8,
    };
    final startHour = startHourRaw.toInt();
    final endHourRaw = switch (tone) {
      AccountabilityTone.gentle => (anchorHour + 1).clamp(startHour + 1, 21),
      AccountabilityTone.balanced => (anchorHour + 3).clamp(startHour + 1, 21),
      AccountabilityTone.firm => 20,
    };
    final endHour = endHourRaw.toInt();
    return (
      DateTime(now.year, now.month, now.day, startHour),
      DateTime(now.year, now.month, now.day, endHour),
    );
  }

  int _planAnchorHour(String? planWhen) {
    final value = planWhen?.toLowerCase() ?? '';
    if (value.contains('morning') ||
        value.contains('prayer') ||
        value.contains('breakfast')) {
      return 8;
    }
    if (value.contains('lunch') || value.contains('midday')) {
      return 12;
    }
    if (value.contains('work') ||
        value.contains('school') ||
        value.contains('afternoon')) {
      return 16;
    }
    if (value.contains('bed') ||
        value.contains('night') ||
        value.contains('evening')) {
      return 20;
    }
    return 14;
  }

  Future<void> cancelCommitmentNudges(int commitmentId) async {
    try {
      await initialize();
      if (!_platformAvailable) {
        return;
      }
      for (var i = 0; i < 10; i++) {
        await _localNotificationsPlugin.cancel(
          id: 7000 + commitmentId * 10 + i,
        );
      }
    } catch (e) {
      debugPrint('NotificationService: Error cancelling commitment nudges: $e');
    }
  }

  /// Show immediate notification when user reaches a milestone.
  /// Called when the commitment tightens at milestone days.
  Future<void> showMilestoneReachedNotification({
    required String journeyTitle,
    required int milestoneDay,
    required String newRequirement,
  }) async {
    try {
      await initialize();

      final androidDetails = AndroidNotificationDetails(
        'journey_milestones',
        'Journey Deepenings',
        channelDescription:
            'Notifications when your commitment journey tightens',
        importance: Importance.high,
        priority: Priority.high,
        color: const Color(0xFFFFC107),
        ledColor: const Color(0xFFFFC107),
        enableLights: true,
        ledOnMs: _ledOnMs,
        ledOffMs: _ledOffMs,
        enableVibration: true,
        playSound: true,
        channelShowBadge: true,
        styleInformation: BigTextStyleInformation(
          'Starting Day $milestoneDay your practice deepens: $newRequirement\n\n'
          'This is how God shapes faithfulness — layer by layer.',
        ),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        threadIdentifier: 'journey_milestones',
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Spiritual copy for milestone
      const title = 'Your journey deepens';
      final body = 'Day $milestoneDay: $newRequirement';

      await _localNotificationsPlugin.show(
        id: journeyMilestoneBaseId + milestoneDay,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: 'journey_milestone',
      );
    } catch (e) {
      debugPrint(
        'NotificationService: Error showing milestone notification: $e',
      );
    }
  }

  /// Show immediate notification when journey is completed.
  /// Celebrates completion and virtue growth silently.
  Future<void> showJourneyCompletedNotification({
    required String journeyTitle,
    required int durationDays,
    required String virtueAlignment,
  }) async {
    try {
      await initialize();

      final androidDetails = AndroidNotificationDetails(
        'journey_completions',
        'Journey Completions',
        channelDescription:
            'Celebrations when you complete a commitment journey',
        importance: Importance.high,
        priority: Priority.high,
        color: const Color(0xFF4CAF50),
        ledColor: const Color(0xFF4CAF50),
        enableLights: true,
        ledOnMs: _ledOnMs,
        ledOffMs: _ledOffMs,
        enableVibration: true,
        playSound: true,
        channelShowBadge: true,
        styleInformation: BigTextStyleInformation(
          '$durationDays days of faithful practice. Your $virtueAlignment has been tested '
          'and proven. What will God invite you into next?\n\n'
          '"Well done, good and faithful servant." — Matthew 25:21',
        ),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        threadIdentifier: 'journey_completions',
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Spiritual copy for completion - emphasizing growth, not achievement
      final spiritualTitles = [
        'You have been faithful',
        'Your journey is complete',
        'Well done',
        'A season of growth ends',
      ];

      final spiritualBodies = [
        '$durationDays days of $journeyTitle — your $virtueAlignment has grown.',
        'What will God invite you to next?',
      ].join(' ');

      final title = spiritualTitles[durationDays % spiritualTitles.length];

      await _localNotificationsPlugin.show(
        id: journeyCompletionId,
        title: title,
        body: spiritualBodies,
        notificationDetails: notificationDetails,
        payload: 'journey_completed',
      );
    } catch (e) {
      debugPrint('NotificationService: Error showing journey completion: $e');
    }
  }

  /// Cancel all journey-related notifications.
  /// Call when user abandons a journey.
  Future<void> cancelJourneyNotifications() async {
    try {
      await initialize();

      // Cancel check-in reminders
      await _localNotificationsPlugin.cancel(id: journeyCheckInBaseId);
      await _localNotificationsPlugin.cancel(id: journeyCheckInBaseId + 1);

      // Cancel milestone notifications (potential range)
      for (int i = 0; i < 50; i++) {
        await _localNotificationsPlugin.cancel(id: journeyMilestoneBaseId + i);
      }

      // Cancel completion notification
      await _localNotificationsPlugin.cancel(id: journeyCompletionId);
    } catch (e) {
      debugPrint(
        'NotificationService: Error cancelling journey notifications: $e',
      );
    }
  }
}
