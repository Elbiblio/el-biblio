import 'package:flutter/material.dart';

import '../../features/assessment/domain/models/calling_profile.dart';
import '../../features/assessment/domain/models/weekly_plan.dart';
import '../../features/mission/domain/models/accountability_partner.dart';
import '../../features/mission/domain/models/mission_action.dart';
import '../../features/mission/domain/models/person_profile.dart';
import '../../features/today/domain/models/daily_anchors.dart';
import '../theme/app_theme_mode.dart';

class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.brightness,
    required this.onboardingCompleted,
    required this.lifestyle,
    required this.morningTime,
    required this.eveningTime,
    required this.morningReminderEnabled,
    required this.eveningReminderEnabled,
    required this.primaryVirtue,
    required this.streakCount,
    required this.longestStreakCount,
    required this.lastCheckIn,
    required this.lastIntegrityScore,
    required this.lastIntegrityDate,
    required this.unlockedBadges,
    required this.lastRecalibrationPromptDate,
    required this.socialPresenceOptIn,
    required this.contactsImported,
    required this.bibleFontSize,
    required this.hasCompletedPhoneSetup,
    required this.hasCompletedPreOnboarding,
    required this.hasSeenAssessmentPrompt,
    required this.selectedTTSVoice,
    required this.lastPrayerGuideDate,
    required this.primaryArchetypeId,
    required this.commitmentCategory,
    required this.primaryMissionFocus,
    required this.missionActions,
    required this.accountabilityPartner,
    required this.personProfiles,
    required this.hasSeenCommitmentWelcome,
    required this.callingProfile,
    required this.currentWeeklyPlan,
    required this.spiritualPulseByDate,
  });

  final AppThemeMode themeMode;
  final Brightness brightness;
  final bool onboardingCompleted;
  final String lifestyle;
  final String morningTime;
  final String eveningTime;
  final bool morningReminderEnabled;
  final bool eveningReminderEnabled;
  final VirtueType primaryVirtue;
  final int streakCount;
  final int longestStreakCount;
  final DateTime? lastCheckIn;
  final int lastIntegrityScore;
  final DateTime? lastIntegrityDate;
  final Map<String, String> unlockedBadges;
  final DateTime? lastRecalibrationPromptDate;
  final bool socialPresenceOptIn;
  final bool contactsImported;
  final double bibleFontSize;
  final bool hasCompletedPhoneSetup;
  final bool hasCompletedPreOnboarding;
  final bool hasSeenAssessmentPrompt;
  final String selectedTTSVoice;
  final DateTime? lastPrayerGuideDate;
  final String? primaryArchetypeId;
  final String? commitmentCategory;
  final String? primaryMissionFocus;
  final List<MissionAction> missionActions;
  final AccountabilityPartner? accountabilityPartner;
  final List<PersonProfile> personProfiles;
  final bool hasSeenCommitmentWelcome;
  final CallingProfile? callingProfile;
  final WeeklyPlan? currentWeeklyPlan;
  final Map<String, SpiritualPulseResponse> spiritualPulseByDate;

  factory AppSettings.defaults() {
    return const AppSettings(
      themeMode: AppThemeMode.adaptive,
      brightness: Brightness.light,
      onboardingCompleted: false,
      lifestyle: 'Student',
      morningTime: '07:30',
      eveningTime: '21:00',
      morningReminderEnabled: true,
      eveningReminderEnabled: true,
      primaryVirtue: VirtueType.humility,
      streakCount: 0,
      longestStreakCount: 0,
      lastCheckIn: null,
      lastIntegrityScore: 0,
      lastIntegrityDate: null,
      unlockedBadges: {},
      lastRecalibrationPromptDate: null,
      socialPresenceOptIn: false,
      contactsImported: false,
      bibleFontSize: 16.0,
      hasCompletedPhoneSetup: false,
      hasCompletedPreOnboarding: false,
      hasSeenAssessmentPrompt: false,
      selectedTTSVoice: 'default',
      lastPrayerGuideDate: null,
      primaryArchetypeId: null,
      commitmentCategory: null,
      primaryMissionFocus: null,
      missionActions: [],
      accountabilityPartner: null,
      personProfiles: [],
      hasSeenCommitmentWelcome: false,
      callingProfile: null,
      currentWeeklyPlan: null,
      spiritualPulseByDate: {},
    );
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    if (map.isEmpty) {
      return AppSettings.defaults();
    }

    final unlockedBadgesRaw = map['unlockedBadges'];
    final unlockedBadges = unlockedBadgesRaw is Map
        ? unlockedBadgesRaw.map(
            (key, value) => MapEntry(
              key.toString(),
              value.toString(),
            ),
          )
        : <String, String>{};
    final missionActionsRaw = map['missionActions'];
    final missionActions = missionActionsRaw is List
        ? missionActionsRaw
            .whereType<Map>()
            .map(
              (item) => MissionAction.fromMap(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
        : <MissionAction>[];
    final accountabilityPartnerRaw = map['accountabilityPartner'];
    final personProfilesRaw = map['personProfiles'];
    final personProfiles = personProfilesRaw is List
        ? personProfilesRaw
            .whereType<Map>()
            .map(
              (item) => PersonProfile.fromMap(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
        : <PersonProfile>[];
    final spiritualPulseRaw = map['spiritualPulseByDate'];
    final spiritualPulseByDate = spiritualPulseRaw is Map
        ? spiritualPulseRaw.map(
            (key, value) => MapEntry(
              key.toString(),
              SpiritualPulseResponse.fromJson(
                Map<String, dynamic>.from(value as Map),
              ),
            ),
          )
        : <String, SpiritualPulseResponse>{};

    return AppSettings(
      themeMode: AppThemeModeX.fromStorage(
        (map['themeMode'] ?? map['themeVariant']) as String?,
      ),
      brightness: (map['brightness'] as String?) == 'dark'
          ? Brightness.dark
          : Brightness.light,
      onboardingCompleted: map['onboardingCompleted'] as bool? ?? false,
      lifestyle: map['lifestyle'] as String? ?? 'Student',
      morningTime: map['morningTime'] as String? ?? '07:30',
      eveningTime: map['eveningTime'] as String? ?? '21:00',
      morningReminderEnabled: map['morningReminderEnabled'] as bool? ?? true,
      eveningReminderEnabled: map['eveningReminderEnabled'] as bool? ?? true,
      primaryVirtue:
          VirtueTypeX.fromStorage(map['primaryVirtue'] as String?) ?? VirtueType.humility,
      streakCount: map['streakCount'] as int? ?? 0,
      longestStreakCount: map['longestStreakCount'] as int? ?? 0,
      lastCheckIn: map['lastCheckIn'] == null
          ? null
          : DateTime.tryParse(map['lastCheckIn'] as String),
      lastIntegrityScore: map['lastIntegrityScore'] as int? ?? 0,
      lastIntegrityDate: map['lastIntegrityDate'] == null
          ? null
          : DateTime.tryParse(map['lastIntegrityDate'] as String),
      unlockedBadges: unlockedBadges,
      lastRecalibrationPromptDate: map['lastRecalibrationPromptDate'] == null
          ? null
          : DateTime.tryParse(map['lastRecalibrationPromptDate'] as String),
      socialPresenceOptIn: map['socialPresenceOptIn'] as bool? ?? false,
      contactsImported: map['contactsImported'] as bool? ?? false,
      bibleFontSize: (map['bibleFontSize'] as num?)?.toDouble() ?? 16.0,
      hasCompletedPhoneSetup: map['hasCompletedPhoneSetup'] as bool? ?? false,
      hasCompletedPreOnboarding: map['hasCompletedPreOnboarding'] as bool? ?? false,
      hasSeenAssessmentPrompt: map['hasSeenAssessmentPrompt'] as bool? ?? false,
      selectedTTSVoice: map['selectedTTSVoice'] as String? ?? 'default',
      lastPrayerGuideDate: map['lastPrayerGuideDate'] == null
          ? null
          : DateTime.tryParse(map['lastPrayerGuideDate'] as String),
      primaryArchetypeId: map['primaryArchetypeId'] as String?,
      commitmentCategory: map['commitmentCategory'] as String?,
      primaryMissionFocus: map['primaryMissionFocus'] as String?,
      missionActions: missionActions,
      accountabilityPartner: accountabilityPartnerRaw is Map
          ? AccountabilityPartner.fromMap(
              Map<String, dynamic>.from(accountabilityPartnerRaw),
            )
          : null,
      personProfiles: personProfiles,
      hasSeenCommitmentWelcome: map['hasSeenCommitmentWelcome'] as bool? ?? false,
      callingProfile: map['callingProfile'] is Map
          ? CallingProfile.fromMap(Map<String, dynamic>.from(map['callingProfile'] as Map))
          : null,
      currentWeeklyPlan: map['currentWeeklyPlan'] is Map
          ? WeeklyPlan.fromMap(Map<String, dynamic>.from(map['currentWeeklyPlan'] as Map))
          : null,
      spiritualPulseByDate: spiritualPulseByDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'themeVariant': themeMode.name,
      'themeMode': themeMode.name,
      'brightness': brightness == Brightness.dark ? 'dark' : 'light',
      'onboardingCompleted': onboardingCompleted,
      'lifestyle': lifestyle,
      'morningTime': morningTime,
      'eveningTime': eveningTime,
      'morningReminderEnabled': morningReminderEnabled,
      'eveningReminderEnabled': eveningReminderEnabled,
      'primaryVirtue': primaryVirtue.name,
      'streakCount': streakCount,
      'longestStreakCount': longestStreakCount,
      'lastCheckIn': lastCheckIn?.toIso8601String(),
      'lastIntegrityScore': lastIntegrityScore,
      'lastIntegrityDate': lastIntegrityDate?.toIso8601String(),
      'unlockedBadges': unlockedBadges,
      'lastRecalibrationPromptDate': lastRecalibrationPromptDate?.toIso8601String(),
      'socialPresenceOptIn': socialPresenceOptIn,
      'contactsImported': contactsImported,
      'bibleFontSize': bibleFontSize,
      'hasCompletedPhoneSetup': hasCompletedPhoneSetup,
      'hasCompletedPreOnboarding': hasCompletedPreOnboarding,
      'hasSeenAssessmentPrompt': hasSeenAssessmentPrompt,
      'selectedTTSVoice': selectedTTSVoice,
      'lastPrayerGuideDate': lastPrayerGuideDate?.toIso8601String(),
      'primaryArchetypeId': primaryArchetypeId,
      'commitmentCategory': commitmentCategory,
      'primaryMissionFocus': primaryMissionFocus,
      'missionActions': missionActions.map((item) => item.toMap()).toList(),
      'accountabilityPartner': accountabilityPartner?.toMap(),
      'personProfiles': personProfiles.map((item) => item.toMap()).toList(),
      'hasSeenCommitmentWelcome': hasSeenCommitmentWelcome,
      'callingProfile': callingProfile?.toMap(),
      'currentWeeklyPlan': currentWeeklyPlan?.toMap(),
      'spiritualPulseByDate': spiritualPulseByDate.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    };
  }

  AppSettings copyWith({
    AppThemeMode? themeMode,
    Brightness? brightness,
    bool? onboardingCompleted,
    String? lifestyle,
    String? morningTime,
    String? eveningTime,
    bool? morningReminderEnabled,
    bool? eveningReminderEnabled,
    VirtueType? primaryVirtue,
    int? streakCount,
    int? longestStreakCount,
    DateTime? lastCheckIn,
    int? lastIntegrityScore,
    DateTime? lastIntegrityDate,
    Map<String, String>? unlockedBadges,
    DateTime? lastRecalibrationPromptDate,
    bool? socialPresenceOptIn,
    bool? contactsImported,
    double? bibleFontSize,
    bool? hasCompletedPhoneSetup,
    bool? hasCompletedPreOnboarding,
    bool? hasSeenAssessmentPrompt,
    String? selectedTTSVoice,
    DateTime? lastPrayerGuideDate,
    String? primaryArchetypeId,
    String? commitmentCategory,
    String? primaryMissionFocus,
    List<MissionAction>? missionActions,
    AccountabilityPartner? accountabilityPartner,
    List<PersonProfile>? personProfiles,
    bool? hasSeenCommitmentWelcome,
    CallingProfile? callingProfile,
    WeeklyPlan? currentWeeklyPlan,
    Map<String, SpiritualPulseResponse>? spiritualPulseByDate,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      brightness: brightness ?? this.brightness,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      lifestyle: lifestyle ?? this.lifestyle,
      morningTime: morningTime ?? this.morningTime,
      eveningTime: eveningTime ?? this.eveningTime,
      morningReminderEnabled: morningReminderEnabled ?? this.morningReminderEnabled,
      eveningReminderEnabled: eveningReminderEnabled ?? this.eveningReminderEnabled,
      primaryVirtue: primaryVirtue ?? this.primaryVirtue,
      streakCount: streakCount ?? this.streakCount,
      longestStreakCount: longestStreakCount ?? this.longestStreakCount,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      lastIntegrityScore: lastIntegrityScore ?? this.lastIntegrityScore,
      lastIntegrityDate: lastIntegrityDate ?? this.lastIntegrityDate,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
      lastRecalibrationPromptDate:
          lastRecalibrationPromptDate ?? this.lastRecalibrationPromptDate,
      socialPresenceOptIn: socialPresenceOptIn ?? this.socialPresenceOptIn,
      contactsImported: contactsImported ?? this.contactsImported,
      bibleFontSize: bibleFontSize ?? this.bibleFontSize,
      hasCompletedPhoneSetup: hasCompletedPhoneSetup ?? this.hasCompletedPhoneSetup,
      hasCompletedPreOnboarding: hasCompletedPreOnboarding ?? this.hasCompletedPreOnboarding,
      hasSeenAssessmentPrompt: hasSeenAssessmentPrompt ?? this.hasSeenAssessmentPrompt,
      selectedTTSVoice: selectedTTSVoice ?? this.selectedTTSVoice,
      lastPrayerGuideDate: lastPrayerGuideDate ?? this.lastPrayerGuideDate,
      primaryArchetypeId: primaryArchetypeId ?? this.primaryArchetypeId,
      commitmentCategory: commitmentCategory ?? this.commitmentCategory,
      primaryMissionFocus: primaryMissionFocus ?? this.primaryMissionFocus,
      missionActions: missionActions ?? this.missionActions,
      accountabilityPartner: accountabilityPartner ?? this.accountabilityPartner,
      personProfiles: personProfiles ?? this.personProfiles,
      hasSeenCommitmentWelcome: hasSeenCommitmentWelcome ?? this.hasSeenCommitmentWelcome,
      callingProfile: callingProfile ?? this.callingProfile,
      currentWeeklyPlan: currentWeeklyPlan ?? this.currentWeeklyPlan,
      spiritualPulseByDate: spiritualPulseByDate ?? this.spiritualPulseByDate,
    );
  }
}
