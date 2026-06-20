import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/services/notifications/notification_service.dart';
import '../../../core/services/notifications/push_template_engine.dart';
import '../../commit/data/commitment_media_catalog.dart';
import '../../commit/data/notification_escalation.dart';
import '../domain/models/commitment_schedule.dart';

class OverlayNotificationService {
  OverlayNotificationService();

  /// Shares the same [FlutterLocalNotificationsPlugin] instance owned by
  /// [NotificationService] so initialization state and permissions are managed
  /// from a single source of truth.
  FlutterLocalNotificationsPlugin get _localNotifications =>
      NotificationService().plugin;

  static const String _overlayChannelId = 'commitment_overlay';
  static const String _headsUpChannelId = 'commitment_heads_up';
  static const int _overlayBaseId = 20000000;
  static const int _headsUpBaseId = 10000000;
  static const int _preReminderBaseId = 30000000;
  static const Duration _overlayDelay = Duration(seconds: 30);

  Future<void> initialize() async {
    // Initialization is owned by NotificationService — no-op here.
  }

  /// Tier 1: Heads-up banner notification with category backdrop image.
  /// Shows as popup when phone is unlocked. NO full-screen intent.
  Future<ByteArrayAndroidBitmap> _loadImageAsBitmap(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      return ByteArrayAndroidBitmap(data.buffer.asUint8List());
    } catch (_) {
      return ByteArrayAndroidBitmap(Uint8List(0));
    }
  }

  Future<void> scheduleHeadsUp({
    required OverlayNotification notification,
    required DateTime scheduledDate,
    required String category,
    DateTimeComponents recurrence = DateTimeComponents.time,
  }) async {
    final media = CommitmentMediaCatalog.getMedia(category);
    final backdropBitmap = await _loadImageAsBitmap(media.backgroundImage);

    final bigPictureStyle = BigPictureStyleInformation(
      backdropBitmap,
      contentTitle: notification.title,
      summaryText: notification.body,
      htmlFormatContentTitle: true,
      htmlFormatSummaryText: true,
    );

    final androidDetails = AndroidNotificationDetails(
      _headsUpChannelId,
      'Commitment Reminder',
      channelDescription: 'Gentle heads-up reminders for commitments',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: false,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      color: media.accentColor,
      ledColor: media.accentColor,
      enableLights: true,
      ledOnMs: 1000,
      ledOffMs: 500,
      enableVibration: true,
      playSound: true,
      styleInformation: bigPictureStyle,
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'check_in',
          'I did this',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        const AndroidNotificationAction(
          'skip',
          'Skip',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
      categoryIdentifier: 'commitment_heads_up',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.zonedSchedule(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: recurrence,
      payload: 'heads_up:${notification.commitmentId}',
    );
  }

  /// Tier 2: Full-screen overlay that wakes the phone.
  /// Scheduled 30s after heads-up as fallback for locked/no-response.
  Future<void> scheduleFullScreenOverlay({
    required OverlayNotification notification,
    required DateTime scheduledDate,
    required String category,
    DateTimeComponents recurrence = DateTimeComponents.time,
  }) async {
    final media = CommitmentMediaCatalog.getMedia(category);

    final androidDetails = AndroidNotificationDetails(
      _overlayChannelId,
      'Commitment Check-Ins',
      channelDescription: 'Full-screen commitment check-in overlay',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      color: media.accentColor,
      ledColor: media.accentColor,
      enableLights: true,
      ledOnMs: 1000,
      ledOffMs: 500,
      enableVibration: true,
      playSound: true,
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'check_in',
          'I did this',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        const AndroidNotificationAction(
          'skip',
          'Skip',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        const AndroidNotificationAction(
          'talk',
          'Talk to companion',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
      categoryIdentifier: 'commitment_checkin',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final encodedTitle = Uri.encodeQueryComponent(notification.title);
    final encodedBody = Uri.encodeQueryComponent(notification.body);
    await _localNotifications.zonedSchedule(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: recurrence,
      payload:
          'commitment_overlay|${notification.commitmentId}|$category|$encodedTitle|$encodedBody',
    );
  }

  Future<void> showImmediate(OverlayNotification notification) async {
    const androidDetails = AndroidNotificationDetails(
      _overlayChannelId,
      'Commitment Check-Ins',
      channelDescription: 'Rich overlay notifications for commitment check-ins',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      enableVibration: true,
      playSound: true,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'check_in',
          'I did this',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'skip',
          'Skip',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'talk',
          'Talk to companion',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
      categoryIdentifier: 'commitment_overlay',
    );

    const showDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _localNotifications.show(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      notificationDetails: showDetails,
      payload: 'commitment_overlay|${notification.commitmentId}',
    );
  }

  Future<void> cancelOverlay(int notificationId) async {
    await _localNotifications.cancel(id: notificationId);
  }

  Future<void> cancelAllForCommitment(int commitmentId) async {
    for (var d = 1; d <= 7; d++) {
      for (var i = 0; i < 20; i++) {
        await _localNotifications.cancel(
          id: _overlayBaseId + commitmentId * 1000 + d * 10 + i,
        );
        await _localNotifications.cancel(
          id: _headsUpBaseId + commitmentId * 1000 + d * 10 + i,
        );
        await _localNotifications.cancel(
          id: _preReminderBaseId + commitmentId * 1000 + d * 10 + i,
        );
      }
    }
  }

  /// Schedule both Tier 1 (heads-up) and Tier 2 (full-screen) for each
  /// check-in time. Integrates CommitmentMediaCatalog for visuals,
  /// PushTemplateEngine for messages, and NotificationEscalation for tone.
  Future<void> scheduleFromSchedule({
    required CommitmentSchedule schedule,
    required String commitmentTitle,
    required String category,
    required int totalDays,
    String userName = 'You',
    int consecutiveMisses = 0,
    int currentDay = 1,
  }) async {
    // Cancel old notifications first, then create new ones.
    // If the creation loop fails partway, the commitment may be left without
    // notifications until the next scheduleFromSchedule call.
    // Individual scheduling calls are wrapped in try-catch below so a single
    // failure does not cascade — missing notifications are logged.
    await cancelAllForCommitment(schedule.commitmentId);

    final escalation = NotificationEscalation.levelForMisses(consecutiveMisses);
    final templateKey = NotificationEscalation.templateKey(escalation);
    final activeDays = schedule.activeDays.toSet();

    // Capture wall clock once so all scheduling uses the same base date.
    final now = DateTime.now();
    final minScheduledTime = now.add(const Duration(minutes: 1));

    // Returns the DateTime of the next occurrence of [weekday] (1=Mon..7=Sun)
    // at [time]. Skips to next week if today matches but time has passed.
    DateTime nextWeekdayAtTime(int weekday, TimeOfDay time) {
      var date = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      final daysUntil = (weekday - now.weekday) % 7;
      if (daysUntil == 0 && date.isBefore(now)) {
        return date.add(const Duration(days: 7));
      }
      return date.add(Duration(days: daysUntil));
    }

    for (var i = 0; i < schedule.checkInTimes.length; i++) {
      final time = schedule.checkInTimes[i];

      for (final day in activeDays) {
        var scheduledDate = nextWeekdayAtTime(day, time);
        if (scheduledDate.isBefore(minScheduledTime)) {
          scheduledDate = scheduledDate.add(const Duration(days: 7));
        }

        final body = PushTemplateEngine.render(
          templateKey,
          {
            'name': userName,
            'commitment': commitmentTitle,
            'day': '$currentDay',
            'total': '$totalDays',
            'days': '$consecutiveMisses',
          },
        );

        final id = _headsUpBaseId + schedule.commitmentId * 1000 + day * 10 + i;

        // Tier 1: Heads-up at check-in time, repeats weekly on this day
        try {
          final headsUpNotification = OverlayNotification(
            id: id,
            commitmentId: schedule.commitmentId,
            scheduledTime: time,
            type: OverlayNotificationType.checkIn.value,
            title: commitmentTitle,
            body: body,
            persistent: false,
            actionButtons: const [
              OverlayAction.checkIn,
              OverlayAction.skip,
            ],
          );

          await scheduleHeadsUp(
            notification: headsUpNotification,
            scheduledDate: scheduledDate,
            category: category,
            recurrence: DateTimeComponents.dayOfWeekAndTime,
          );
        } catch (e) {
          debugPrint(
            'scheduleFromSchedule: heads-up [$commitmentTitle|day$day|time$i] failed: $e',
          );
        }

        // Tier 2: Full-screen overlay 30s later, same weekly pattern
        try {
          final overlayNotification = OverlayNotification(
            id: _overlayBaseId + schedule.commitmentId * 1000 + day * 10 + i,
            commitmentId: schedule.commitmentId,
            scheduledTime: time,
            type: OverlayNotificationType.checkIn.value,
            title: commitmentTitle,
            body: body,
            persistent: true,
            actionButtons: const [
              OverlayAction.checkIn,
              OverlayAction.skip,
              OverlayAction.talkToCompanion,
            ],
          );

          await scheduleFullScreenOverlay(
            notification: overlayNotification,
            scheduledDate: scheduledDate.add(_overlayDelay),
            category: category,
            recurrence: DateTimeComponents.dayOfWeekAndTime,
          );
        } catch (e) {
          debugPrint(
            'scheduleFromSchedule: overlay [$commitmentTitle|day$day|time$i] failed: $e',
          );
        }
      }
    }

    // Pre-reminder: if escalation level requires it
    final needsPreReminder = NotificationEscalation.shouldSendPreReminder(
      escalation,
    );
    if (needsPreReminder) {
      for (var i = 0; i < schedule.checkInTimes.length; i++) {
        final time = schedule.checkInTimes[i];

        for (final day in activeDays) {
          var preDate = nextWeekdayAtTime(day, time).subtract(
            const Duration(minutes: 15),
          );
          if (preDate.isBefore(minScheduledTime)) {
            preDate = preDate.add(const Duration(days: 7));
          }

          final preBody = PushTemplateEngine.render(
            'struggle_support',
            {
              'name': userName,
              'days': '$consecutiveMisses',
            },
          );

          try {
            final preNotif = OverlayNotification(
              id: _preReminderBaseId +
                  schedule.commitmentId * 1000 +
                  day * 10 +
                  i,
              commitmentId: schedule.commitmentId,
              scheduledTime: TimeOfDay.fromDateTime(preDate),
              type: OverlayNotificationType.struggleSupport.value,
              title: 'Gentle reminder',
              body: preBody,
              persistent: false,
              actionButtons: const [],
            );

            await scheduleHeadsUp(
              notification: preNotif,
              scheduledDate: preDate,
              category: category,
              recurrence: DateTimeComponents.dayOfWeekAndTime,
            );
          } catch (e) {
            debugPrint(
              'scheduleFromSchedule: pre-reminder '
              '[$commitmentTitle|day$day|time$i] failed: $e',
            );
          }
        }
      }
    }
  }

  void dispose() {
    // Reserved for future stream cleanup when handleAction/wired.
  }
}

final overlayNotificationService = OverlayNotificationService();
