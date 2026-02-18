import 'package:flutter/material.dart';

import '../../features/today/domain/models/daily_anchors.dart';
import '../theme/app_theme_variant.dart';

class AppSettings {
  const AppSettings({
    required this.themeVariant,
    required this.brightness,
    required this.onboardingCompleted,
    required this.primaryVirtue,
    required this.neglectedVirtue,
    required this.journalReminderTime,
    required this.notificationWindow,
    required this.remindersEnabled,
    required this.streakCount,
    required this.lastCheckIn,
    required this.socialPresenceOptIn,
    required this.contactsImported,
    required this.bibleFontSize,
  });

  final AppThemeVariant themeVariant;
  final Brightness brightness;
  final bool onboardingCompleted;
  final VirtueType primaryVirtue;
  final VirtueType neglectedVirtue;
  final String journalReminderTime;
  final String notificationWindow;
  final bool remindersEnabled;
  final int streakCount;
  final DateTime? lastCheckIn;
  final bool socialPresenceOptIn;
  final bool contactsImported;
  final double bibleFontSize;

  factory AppSettings.defaults() {
    return const AppSettings(
      themeVariant: AppThemeVariant.sage,
      brightness: Brightness.light,
      onboardingCompleted: false,
      primaryVirtue: VirtueType.humility,
      neglectedVirtue: VirtueType.knowledge,
      journalReminderTime: '20:30',
      notificationWindow: 'gentle',
      remindersEnabled: true,
      streakCount: 0,
      lastCheckIn: null,
      socialPresenceOptIn: false,
      contactsImported: false,
      bibleFontSize: 16.0,
    );
  }

  factory AppSettings.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null || map.isEmpty) {
      return AppSettings.defaults();
    }

    return AppSettings(
      themeVariant: AppThemeVariantX.fromStorage(map['themeVariant'] as String?),
      brightness: (map['brightness'] as String?) == 'dark'
          ? Brightness.dark
          : Brightness.light,
      onboardingCompleted: map['onboardingCompleted'] as bool? ?? false,
      primaryVirtue:
          VirtueTypeX.fromStorage(map['primaryVirtue'] as String?) ?? VirtueType.humility,
      neglectedVirtue:
          VirtueTypeX.fromStorage(map['neglectedVirtue'] as String?) ?? VirtueType.knowledge,
      journalReminderTime: map['journalReminderTime'] as String? ?? '20:30',
      notificationWindow: map['notificationWindow'] as String? ?? 'gentle',
      remindersEnabled: map['remindersEnabled'] as bool? ?? true,
      streakCount: map['streakCount'] as int? ?? 0,
      lastCheckIn: map['lastCheckIn'] == null
          ? null
          : DateTime.tryParse(map['lastCheckIn'] as String),
      socialPresenceOptIn: map['socialPresenceOptIn'] as bool? ?? false,
      contactsImported: map['contactsImported'] as bool? ?? false,
      bibleFontSize: (map['bibleFontSize'] as num?)?.toDouble() ?? 16.0,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'themeVariant': themeVariant.name,
      'brightness': brightness == Brightness.dark ? 'dark' : 'light',
      'onboardingCompleted': onboardingCompleted,
      'primaryVirtue': primaryVirtue.name,
      'neglectedVirtue': neglectedVirtue.name,
      'journalReminderTime': journalReminderTime,
      'notificationWindow': notificationWindow,
      'remindersEnabled': remindersEnabled,
      'streakCount': streakCount,
      'lastCheckIn': lastCheckIn?.toIso8601String(),
      'socialPresenceOptIn': socialPresenceOptIn,
      'contactsImported': contactsImported,
      'bibleFontSize': bibleFontSize,
    };
  }

  AppSettings copyWith({
    AppThemeVariant? themeVariant,
    Brightness? brightness,
    bool? onboardingCompleted,
    VirtueType? primaryVirtue,
    VirtueType? neglectedVirtue,
    String? journalReminderTime,
    String? notificationWindow,
    bool? remindersEnabled,
    int? streakCount,
    DateTime? lastCheckIn,
    bool? socialPresenceOptIn,
    bool? contactsImported,
    double? bibleFontSize,
  }) {
    return AppSettings(
      themeVariant: themeVariant ?? this.themeVariant,
      brightness: brightness ?? this.brightness,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      primaryVirtue: primaryVirtue ?? this.primaryVirtue,
      neglectedVirtue: neglectedVirtue ?? this.neglectedVirtue,
      journalReminderTime: journalReminderTime ?? this.journalReminderTime,
      notificationWindow: notificationWindow ?? this.notificationWindow,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      streakCount: streakCount ?? this.streakCount,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      socialPresenceOptIn: socialPresenceOptIn ?? this.socialPresenceOptIn,
      contactsImported: contactsImported ?? this.contactsImported,
      bibleFontSize: bibleFontSize ?? this.bibleFontSize,
    );
  }
}
