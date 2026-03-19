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
import '../../../features/today/domain/models/daily_anchors.dart';

enum NotificationActionOutcome { success, fallbackNavigation, failed }

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

  bool _initialized = false;
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
      debugPrint('NotificationService: Starting initialization...');
      
      tz.initializeTimeZones();

      const androidInitSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      final iosInitSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        notificationCategories: [
          DarwinNotificationCategory(
            _dailyCheckInCategory,
            actions: <DarwinNotificationAction>[
              DarwinNotificationAction.plain(_actionDidThis, 'I did this'),
              DarwinNotificationAction.plain(_actionJournal, 'Journal'),
            ],
          ),
          DarwinNotificationCategory(
            _commitmentCategory,
            actions: <DarwinNotificationAction>[
              DarwinNotificationAction.plain(_actionCommitmentView, 'View'),
              DarwinNotificationAction.plain(_actionCommitmentDone, 'I did this'),
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
      );

      _initialized = true;
      debugPrint('NotificationService: Initialization completed');
    } catch (e, stackTrace) {
      debugPrint('NotificationService: Initialization failed: $e');
      debugPrint('NotificationService: Stack trace: $stackTrace');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('NotificationService: Notification tapped with payload: ${response.payload}');
    debugPrint('NotificationService: Action ID: ${response.actionId}');
    
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
    if (context == null) {
      debugPrint('NotificationService: No context available for action handling');
      return;
    }
    
    try {
      switch (actionId) {
        case _actionDidThis:
          _handleIDidThis(context, payload);
          break;
        case _actionJournal:
          _handleJournalAction(context, payload);
          break;
        case _actionCommitmentView:
        case _actionCommitmentDone:
          _goToRoute(AppRoutes.today);
          break;
        default:
          debugPrint('NotificationService: Unknown action ID: $actionId');
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
        content: Text('Could not record check-in automatically. Please confirm it on Today.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<NotificationActionOutcome> executeDailyCheckInAction({String? payload}) async {
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
    if (context == null) {
      debugPrint('NotificationService: No context available for navigation');
      return;
    }
    
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
          payload == 'commitment_locked_in') {
        _goToRoute(AppRoutes.today);
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
    if (context == null) {
      debugPrint('NotificationService: No context available for route $route');
      return;
    }
    GoRouter.of(context).go(route);
  }
  
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
      
      debugPrint('NotificationService: Scheduled for ${resolved.toLocal()} (timezone: ${tz.local.name})');
      return resolved;
    } catch (e) {
      debugPrint('NotificationService: Error resolving timezone, falling back to local: $e');
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
        debugPrint('NotificationService: Critical error in timezone fallback: $fallbackError');
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
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        actions: actions,
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier:
            actionLabels != null && actionLabels.isNotEmpty
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
      debugPrint('NotificationService: Error scheduling notification with actions: $e');
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
        bigPicturePath = await _downloadAndSaveFile(bigPicture, 'bigPicture_$id');
      }

      AndroidNotificationDetails androidDetails;
      DarwinNotificationDetails iosDetails;

      if (bigPicturePath != null) {
        final bigPictureStyleInformation = BigPictureStyleInformation(
          FilePathAndroidBitmap(bigPicturePath),
          largeIcon: largeIconPath != null ? FilePathAndroidBitmap(largeIconPath) : null,
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
          largeIcon: largeIconPath != null ? FilePathAndroidBitmap(largeIconPath) : null,
        );
        
        iosDetails = DarwinNotificationDetails(
          attachments: largeIconPath != null ? [DarwinNotificationAttachment(largeIconPath)] : null,
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
          matchDateTimeComponents:
              repeatDaily ? DateTimeComponents.time : null,
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
      debugPrint('NotificationService: showCommitmentLockInNotification called');
      debugPrint('NotificationService: commitmentTitle=$commitmentTitle');
      debugPrint('NotificationService: virtueType=$virtueType');
      
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

  Future<void> scheduleDailyReminders({
    required String morningTime,
    required String eveningTime,
    required bool morningEnabled,
    required bool eveningEnabled,
  }) async {
    try {
      await initialize();
      debugPrint('NotificationService: Scheduling daily reminders...');

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
        debugPrint('NotificationService: Morning reminder scheduled for $morningTime');
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
        debugPrint('NotificationService: Evening reminder scheduled for $eveningTime');
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
      debugPrint('NotificationService: Daily reminders cancelled');
    } catch (e) {
      debugPrint('NotificationService: Error cancelling daily reminders: $e');
    }
  }

  Future<void> _scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'daily_reminders',
      'Daily Reminders',
      channelDescription: 'Morning and evening spiritual reminders',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFF638B6C),
      ledColor: Color(0xFF638B6C),
      enableLights: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
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

    // Schedule backup notification 30 minutes later
    await _scheduleBackupNotification(
      originalId: id,
      title: title,
      body: body,
      payload: payload,
      delay: const Duration(minutes: 30),
    );
  }

  Future<void> _scheduleBackupNotification({
    required int originalId,
    required String title,
    required String body,
    required String payload,
    required Duration delay,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'backup_reminders',
        'Backup Reminders',
        channelDescription: 'Backup notifications for missed reminders',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        color: Color(0xFF638B6C),
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final backupId = originalId + 1000; // Backup ID offset
      final scheduledDate = tz.TZDateTime.now(tz.local).add(delay);

      await _localNotificationsPlugin.zonedSchedule(
        id: backupId,
        title: title,
        body: '$body (Backup reminder)',
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: '${payload}_backup',
      );

      debugPrint('NotificationService: Backup notification scheduled for ID $backupId');
    } catch (e) {
      debugPrint('NotificationService: Error scheduling backup notification: $e');
    }
  }

  DateTime _parseTime(String timeString) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts.length > 1 ? int.parse(parts[1]) : 0;
    return DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, hour, minute);
  }

  Future<void> _saveScheduledReminderInfo(bool morningEnabled, bool eveningEnabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('morning_reminder_scheduled', morningEnabled);
      await prefs.setBool('evening_reminder_scheduled', eveningEnabled);
      await prefs.setString('last_reminder_update', DateTime.now().toIso8601String());
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
      final morningScheduled = prefs.getBool('morning_reminder_scheduled') ?? false;
      final eveningScheduled = prefs.getBool('evening_reminder_scheduled') ?? false;
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
          debugPrint('NotificationService: Daily reminders restored from persistence');
        }
      }
    } catch (e) {
      debugPrint('NotificationService: Error restoring daily reminders: $e');
    }
  }

  Future<void> requestPermissions() async {
    if (Platform.isIOS) {
      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _localNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
    }
  }

  Stream<String> get pushTokenStream => const Stream.empty();
  Stream get pushMessageStream => const Stream.empty();
  String? get currentPushToken => null;

  Future<Map<String, dynamic>> getDeviceInfo() async {
    return {};
  }

  Future<void> subscribeToTopic(String topic) async {
    debugPrint('NotificationService: subscribeToTopic called (stub)');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    debugPrint('NotificationService: unsubscribeToTopic called (stub)');
  }

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
      
      canvas.drawCircle(
        const Offset(size / 2, size / 2),
        size / 2,
        paint,
      );
      
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
        Offset(
          (size - textPainter.width) / 2,
          (size - textPainter.height) / 2,
        ),
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
}
