import 'package:flutter/material.dart';

class CommitmentSchedule {
  final int commitmentId;
  final List<TimeOfDay> checkInTimes;
  final List<int> activeDays;
  final int skipDaysAllowed;
  final bool overlayEnabled;

  const CommitmentSchedule({
    required this.commitmentId,
    required this.checkInTimes,
    this.activeDays = const [1, 2, 3, 4, 5, 6, 7],
    this.skipDaysAllowed = 2,
    this.overlayEnabled = true,
  });

  CommitmentSchedule copyWith({
    List<TimeOfDay>? checkInTimes,
    List<int>? activeDays,
    int? skipDaysAllowed,
    bool? overlayEnabled,
  }) {
    return CommitmentSchedule(
      commitmentId: commitmentId,
      checkInTimes: checkInTimes ?? this.checkInTimes,
      activeDays: activeDays ?? this.activeDays,
      skipDaysAllowed: skipDaysAllowed ?? this.skipDaysAllowed,
      overlayEnabled: overlayEnabled ?? this.overlayEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'commitmentId': commitmentId,
    'checkInTimes': checkInTimes
        .map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
        .toList(),
    'activeDays': activeDays,
    'skipDaysAllowed': skipDaysAllowed,
    'overlayEnabled': overlayEnabled,
  };

  factory CommitmentSchedule.fromJson(Map<String, dynamic> json) {
    final times = (json['checkInTimes'] as List<dynamic>? ?? [])
        .map((e) {
          final parts = (e as String).split(':');
          return TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 8,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        })
        .toList();

    return CommitmentSchedule(
      commitmentId: json['commitmentId'] as int? ?? 0,
      checkInTimes: times,
      activeDays: (json['activeDays'] as List<dynamic>? ?? [1, 2, 3, 4, 5, 6, 7])
          .map((e) => e as int)
          .toList(),
      skipDaysAllowed: json['skipDaysAllowed'] as int? ?? 2,
      overlayEnabled: json['overlayEnabled'] as bool? ?? true,
    );
  }
}

class OverlayNotification {
  final int id;
  final int commitmentId;
  final TimeOfDay scheduledTime;
  final String type;
  final String title;
  final String body;
  final String? imageUrl;
  final String? soundPath;
  final bool persistent;
  final List<OverlayAction> actionButtons;

  const OverlayNotification({
    required this.id,
    required this.commitmentId,
    required this.scheduledTime,
    required this.type,
    required this.title,
    required this.body,
    this.imageUrl,
    this.soundPath,
    this.persistent = true,
    this.actionButtons = const [],
  });

  OverlayNotification copyWith({
    String? title,
    String? body,
    String? imageUrl,
    String? soundPath,
    bool? persistent,
    List<OverlayAction>? actionButtons,
  }) {
    return OverlayNotification(
      id: id,
      commitmentId: commitmentId,
      scheduledTime: scheduledTime,
      type: type,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      soundPath: soundPath ?? this.soundPath,
      persistent: persistent ?? this.persistent,
      actionButtons: actionButtons ?? this.actionButtons,
    );
  }
}

class OverlayAction {
  final String id;
  final String label;
  final IconData icon;

  const OverlayAction({
    required this.id,
    required this.label,
    required this.icon,
  });

  static const checkIn = OverlayAction(
    id: 'check_in',
    label: 'I did this',
    icon: Icons.check_circle_outline,
  );

  static const skip = OverlayAction(
    id: 'skip',
    label: 'Skip',
    icon: Icons.skip_next,
  );

  static const talkToCompanion = OverlayAction(
    id: 'talk',
    label: 'Talk to companion',
    icon: Icons.chat_bubble_outline,
  );

  static const journal = OverlayAction(
    id: 'journal',
    label: 'Journal',
    icon: Icons.edit_note,
  );
}

enum OverlayNotificationType {
  checkIn('check_in'),
  encouragement('encouragement'),
  milestone('milestone'),
  struggleSupport('struggle_support');

  const OverlayNotificationType(this.value);
  final String value;

  static OverlayNotificationType fromValue(String value) {
    return OverlayNotificationType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => OverlayNotificationType.checkIn,
    );
  }
}
