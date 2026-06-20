import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import '../../features/auth/application/auth_notifier.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/domain/models/auth_models.dart';
import '../../features/assessment/application/calling_profile_service.dart';
import '../../features/assessment/application/assessment_notifier.dart';
import '../../features/assessment/application/pending_compass_sync_service.dart';
import '../../features/assessment/data/assessment_api_repository.dart';
import '../../features/bible/application/bible_notifier.dart';
import '../../features/bible/application/bible_reading_notifier.dart';
import '../../features/bible/application/reading_plan_notifier.dart';
import '../../features/bible/application/verse_notifier.dart';
import '../../features/bible/data/bible_repository.dart';
import '../../features/bible/data/bible_reading_repository.dart';
import '../../features/bible/data/reading_plan_repository.dart';
import '../../features/bible/data/verse_repository.dart';
import '../../features/bible/data/services/enhanced_bible_database_service.dart';
import '../../features/bible/data/services/bible_history_service.dart';
import '../../features/journal/application/journal_notifier.dart';
import '../../features/journal/application/journal_state.dart';
import '../../features/journal/data/journal_repository.dart';
import '../../features/profile/application/profile_notifier.dart';
import '../../features/profile/data/profile_repository.dart';
import '../../features/social/application/contact_notifier.dart';
import '../../features/social/application/contact_state.dart';
import '../../features/social/data/contact_repository.dart';
import '../../features/commitments/application/graduated_commitment_notifier.dart';
import '../../features/commitments/application/commitment_journey_notifier.dart';
import '../../features/commitments/data/commitment_journey_repository.dart';
import '../../features/mission/application/service_opportunity_notifier.dart';
import '../../features/mission/data/service_opportunity_repository.dart';
import '../../features/mission/domain/models/service_opportunity.dart';
import '../../features/vision/application/vision_notifier.dart';
import '../../features/vision/application/vision_state.dart';
import '../../features/vision/application/daily_verse_social_notifier.dart';
import '../../features/vision/application/daily_verse_social_state.dart';
import '../../features/vision/data/daily_verse_social_repository.dart';
import '../../features/vision/data/vision_repository.dart';
import '../../features/vision/domain/vision_models.dart';
import '../../features/commitments/data/graduated_commitment_repository.dart';
import '../../features/today/application/commitment_notifier.dart';
import '../../features/today/application/daily_anchors_notifier.dart';
import '../../features/today/application/virtue_notifier.dart';
import '../../features/today/application/virtue_state.dart';
import '../../features/today/data/commitment_repository.dart';
import '../../features/today/data/daily_anchors_repository.dart';
import '../../features/today/data/daily_anchors_sync_repository.dart';
import '../../features/today/domain/models/daily_anchors.dart';
import '../../features/meditation/data/repositories/meditation_session_api_repository.dart';
import '../../features/meditation/data/repositories/meditation_session_repository.dart';
import '../../features/meditation/domain/models/meditation_session.dart';
import '../../features/mission/application/mission_notifier.dart';
import '../../features/mission/application/mission_state.dart';
import '../../features/mission/data/mission_sync_repository.dart';
import '../../features/assessment/data/calling_profile_sync_repository.dart';
import '../../features/assessment/data/weekly_plan_sync_repository.dart';
import '../../features/today/data/spiritual_pulse_sync_repository.dart';
import '../application/settings_notifier.dart';
import '../application/push_token_notifier.dart';
import '../models/accountability_tone.dart';
import '../network/dio_client.dart';
import '../services/analytics/app_analytics_service.dart';
import '../services/connectivity_service.dart';
import '../services/sound_service.dart';
import '../services/notifications/notification_service.dart';
import '../services/notifications/push_notification_service.dart';
import '../services/country_service.dart';
import '../storage/app_settings.dart';
import '../storage/settings_storage.dart';
import '../storage/hive_boxes.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import '../services/xp_service.dart';
import '../application/xp_notifier.dart';
import '../../features/app_lock/application/app_lock_notifier.dart';
import '../../features/app_lock/application/app_lock_state.dart';
import '../../features/app_lock/data/app_lock_repository.dart';
import '../../features/app_lock/data/app_usage_service.dart';
import '../../features/alignment/data/alignment_repository.dart';
import '../../features/alignment/application/alignment_notifier.dart';
import '../../features/alignment/application/habit_notifier.dart';
import '../../features/alignment/application/forty_day_notifier.dart';
import '../../features/today/application/pillar_score_notifier.dart';
import '../../features/today/domain/models/pillar_score.dart';

final meditationSessionRepositoryProvider =
    Provider<MeditationSessionRepository>((ref) {
      return MeditationSessionRepository(
        Hive.box<MeditationSession>(HiveBoxes.meditationSessions),
      );
    });

final meditationSessionApiRepositoryProvider =
    Provider<MeditationSessionApiRepository>((ref) {
      return MeditationSessionApiRepository(
        ref.watch(dioClientProvider),
        ref.watch(loggerProvider),
      );
    });

final loggerProvider = Provider<Logger>((ref) {
  return Logger();
});

final firebaseAnalyticsProvider = Provider<FirebaseAnalytics>((ref) {
  return FirebaseAnalytics.instance;
});

final analyticsProvider = Provider<AppAnalyticsService>((ref) {
  return AppAnalyticsService(
    ref.watch(loggerProvider),
    ref.watch(firebaseAnalyticsProvider),
  );
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService(ref.watch(loggerProvider));
});

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(ref.watch(loggerProvider));
});

final authenticatedDioClientProvider = Provider<DioClient>((ref) {
  final authState = ref.watch(authProvider);
  final dioClient = ref.watch(dioClientProvider);

  // Update the dio client with the current token
  dioClient.updateAuthToken(authState.token);

  return dioClient;
});

final assessmentApiRepositoryProvider = Provider<AssessmentApiRepository>((
  ref,
) {
  return AssessmentApiRepository(
    ref.watch(authenticatedDioClientProvider),
    ref.watch(loggerProvider),
  );
});

final pendingCompassSyncServiceProvider = Provider<PendingCompassSyncService>((
  ref,
) {
  return PendingCompassSyncService(ref.watch(loggerProvider));
});

final pendingCompassSyncProvider = Provider<void>((ref) {
  final service = ref.watch(pendingCompassSyncServiceProvider);
  var isSyncing = false;

  Future<void> attemptSync() async {
    if (isSyncing) return;

    final auth = ref.read(authProvider);
    final payload = ref.read(settingsProvider).pendingCompassSubmission;
    if (!auth.isAuthenticated || auth.token?.isNotEmpty != true) return;
    if (payload == null || payload.isEmpty) return;

    isSyncing = true;
    try {
      await service.trySync(
        isAuthenticated: auth.isAuthenticated,
        payload: payload,
        submit: (submission) => ref
            .read(assessmentApiRepositoryProvider)
            .submitAssessment(submission),
        clear: ref
            .read(settingsProvider.notifier)
            .clearPendingCompassSubmission,
      );
    } finally {
      isSyncing = false;
    }
  }

  ref.listen<AuthState>(authProvider, (previous, next) {
    if (next.isAuthenticated && previous?.token != next.token) {
      Future.microtask(attemptSync);
    }
  });
  ref.listen<Map<String, dynamic>?>(
    settingsProvider.select((settings) => settings.pendingCompassSubmission),
    (_, next) {
      if (next != null && next.isNotEmpty) {
        Future.microtask(attemptSync);
      }
    },
  );

  Future.microtask(attemptSync);
});

final visionRepositoryProvider = Provider<VisionRepository>((ref) {
  return VisionRepository(
    ref.watch(authenticatedDioClientProvider),
    ref.watch(loggerProvider),
  );
});

final visionProvider = StateNotifierProvider<VisionNotifier, VisionState>((
  ref,
) {
  return VisionNotifier(
    ref.watch(visionRepositoryProvider),
    ref.watch(notificationServiceProvider),
    topArchetypes: () {
      final assessment = ref.read(assessmentProvider);
      final settings = ref.read(settingsProvider);
      final names = <String>[
        ...assessment.selectedArchetypes.map((archetype) => archetype.name),
        ...settings.selectedArchetypeIds,
        if (settings.primaryArchetypeId?.isNotEmpty == true)
          settings.primaryArchetypeId!,
      ];
      return {
        for (final name in names)
          if (name.trim().isNotEmpty) name.trim(),
      }.toList();
    },
    saveFirstCheckInPlan:
        ({required int commitmentId, String? when, String? obstacle}) {
          return ref
              .read(settingsProvider.notifier)
              .setFirstCheckInPlan(
                commitmentId: commitmentId,
                when: when,
                obstacle: obstacle,
              );
        },
    localPlanContext: (commitmentId) {
      final settings = ref.read(settingsProvider);
      if (settings.firstCheckInPlanCommitmentId != commitmentId) {
        return const CommitmentPlanContext();
      }
      return CommitmentPlanContext(
        when: settings.firstCheckInPlanWhen,
        obstacle: settings.firstCheckInPlanObstacle,
      );
    },
    accountabilityTone: () => ref.read(settingsProvider).accountabilityTone,
    startCommitmentReviewSeason:
        ({
          required DateTime startedAt,
          CommitmentMonthlyReviewOutcome? outcome,
        }) {
          return ref
              .read(settingsProvider.notifier)
              .startCommitmentReviewSeason(
                startedAt: startedAt,
                outcome: outcome,
              );
        },
  );
});

final dailyVerseSocialRepositoryProvider = Provider<DailyVerseSocialRepository>(
  (ref) {
    return DailyVerseSocialRepository(
      ref.watch(authenticatedDioClientProvider),
      ref.watch(loggerProvider),
    );
  },
);

final dailyVerseSocialProvider =
    StateNotifierProvider<DailyVerseSocialNotifier, DailyVerseSocialState>((
      ref,
    ) {
      return DailyVerseSocialNotifier(
        ref.watch(dailyVerseSocialRepositoryProvider),
      );
    });

final settingsStorageProvider = Provider<SettingsStorage>((ref) {
  return const SettingsStorage();
});

final callingProfileServiceProvider = Provider<CallingProfileService>((ref) {
  return CallingProfileService();
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  return SettingsNotifier(
    ref.watch(settingsStorageProvider),
    ref.watch(analyticsProvider),
    ref.watch(callingProfileServiceProvider),
  );
});

final missionProvider = StateNotifierProvider<MissionNotifier, MissionState>((
  ref,
) {
  final settings = ref.watch(settingsProvider);
  final notifier = MissionNotifier(
    settingsNotifier: ref.read(settingsProvider.notifier),
    analytics: ref.watch(analyticsProvider),
    notificationService: ref.watch(notificationServiceProvider),
    serviceOpportunityRepository: ref.watch(
      serviceOpportunityRepositoryProvider,
    ),
    logger: ref.watch(loggerProvider),
    initialSettings: settings,
  );

  ref.listen<AppSettings>(settingsProvider, (previous, next) {
    notifier.syncFromSettings(next);
  });

  return notifier;
});

final soundServiceProvider = Provider<SoundService>((ref) {
  final service = SoundService.instance;
  ref.onDispose(service.dispose);
  return service;
});

final themeProvider = StateNotifierProvider<ThemeNotifier, AppTheme>((ref) {
  return ThemeNotifier(ref.watch(settingsStorageProvider));
});

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return JournalRepository(
    ref.watch(dioClientProvider),
    ref.watch(loggerProvider),
  );
});

final journalProvider = StateNotifierProvider<JournalNotifier, JournalState>((
  ref,
) {
  return JournalNotifier(
    ref.watch(journalRepositoryProvider),
    ref.watch(analyticsProvider),
  );
});

final dailyAnchorsRepositoryProvider = Provider<DailyAnchorsRepository>((ref) {
  return DailyAnchorsRepository(ref.watch(loggerProvider));
});

final dailyAnchorsSyncRepositoryProvider = Provider<DailyAnchorsSyncRepository>(
  (ref) {
    return DailyAnchorsSyncRepository(
      ref.watch(authenticatedDioClientProvider),
      ref.watch(loggerProvider),
    );
  },
);

final missionSyncRepositoryProvider = Provider<MissionSyncRepository>((ref) {
  return MissionSyncRepository(
    ref.watch(authenticatedDioClientProvider),
    ref.watch(loggerProvider),
  );
});

final callingProfileSyncRepositoryProvider =
    Provider<CallingProfileSyncRepository>((ref) {
      return CallingProfileSyncRepository(
        ref.watch(authenticatedDioClientProvider),
        ref.watch(loggerProvider),
      );
    });

final weeklyPlanSyncRepositoryProvider = Provider<WeeklyPlanSyncRepository>((
  ref,
) {
  return WeeklyPlanSyncRepository(
    ref.watch(authenticatedDioClientProvider),
    ref.watch(loggerProvider),
  );
});

final spiritualPulseSyncRepositoryProvider =
    Provider<SpiritualPulseSyncRepository>((ref) {
      return SpiritualPulseSyncRepository(
        ref.watch(authenticatedDioClientProvider),
        ref.watch(loggerProvider),
      );
    });

final dailyAnchorsProvider =
    StateNotifierProvider<DailyAnchorsNotifier, DailyAnchors>((ref) {
      return DailyAnchorsNotifier(
        ref: ref,
        repository: ref.watch(dailyAnchorsRepositoryProvider),
        syncRepository: ref.watch(dailyAnchorsSyncRepositoryProvider),
        spiritualPulseSyncRepository: ref.watch(
          spiritualPulseSyncRepositoryProvider,
        ),
      );
    });

final virtueProvider = StateNotifierProvider<VirtueNotifier, VirtueState>((
  ref,
) {
  final settings = ref.watch(settingsProvider);

  final notifier = VirtueNotifier(
    VirtueState.initial(primaryVirtue: settings.primaryVirtue),
  );

  ref.listen<AppSettings>(settingsProvider, (previous, next) {
    notifier.syncFromSettings(primaryVirtue: next.primaryVirtue);
  });

  return notifier;
});

final commitmentRepositoryProvider = Provider<CommitmentRepository>((ref) {
  return CommitmentRepository(
    ref.watch(authenticatedDioClientProvider),
    ref.watch(loggerProvider),
    connectivityService: ref.watch(connectivityServiceProvider),
  );
});

final commitmentProvider =
    StateNotifierProvider<CommitmentNotifier, CommitmentState>((ref) {
      return CommitmentNotifier(
        repository: ref.watch(commitmentRepositoryProvider),
      );
    });

// Mood provider is defined in mood_notifier.dart

final bibleDatabaseServiceProvider = Provider<EnhancedBibleDatabaseService>((
  ref,
) {
  final service = EnhancedBibleDatabaseService(ref.watch(loggerProvider));
  // Fire-and-forget initialization — copies bundled Bible DB and loads mappings.
  // init() is idempotent and safe to call multiple times.
  service.init();
  return service;
});

final bibleHistoryServiceProvider = Provider<BibleHistoryService>((ref) {
  return BibleHistoryService(ref.watch(loggerProvider));
});

final bibleRepositoryProvider = Provider<BibleRepository>((ref) {
  return BibleRepository(
    ref.watch(dioClientProvider),
    ref.watch(loggerProvider),
    ref.watch(bibleDatabaseServiceProvider),
    ref.watch(bibleHistoryServiceProvider),
  );
});

final bibleReadingRepositoryProvider = Provider<BibleReadingRepository>((ref) {
  return BibleReadingRepository(
    ref.watch(dioClientProvider),
    ref.watch(loggerProvider),
  );
});
final bibleReadingProvider =
    StateNotifierProvider<BibleReadingNotifier, BibleReadingState>((ref) {
      return BibleReadingNotifier(
        ref.watch(bibleReadingRepositoryProvider),
        ref.watch(settingsStorageProvider),
      );
    });

final readingPlanRepositoryProvider = Provider<ReadingPlanRepository>((ref) {
  return ReadingPlanRepository(
    ref.watch(dioClientProvider),
    ref.watch(loggerProvider),
  );
});

final readingPlanProvider =
    StateNotifierProvider<ReadingPlanNotifier, ReadingPlanState>((ref) {
      return ReadingPlanNotifier(ref.watch(readingPlanRepositoryProvider));
    });

final bibleProvider = StateNotifierProvider<BibleNotifier, BibleState>((ref) {
  final settings = ref.watch(settingsProvider);
  return BibleNotifier(
    ref.watch(bibleRepositoryProvider),
    ref.watch(settingsStorageProvider),
    ref.watch(bibleReadingProvider.notifier),
    initialFontSize: settings.bibleFontSize,
  );
});

final verseRepositoryProvider = Provider<VerseRepository>((ref) {
  return VerseRepository(
    ref.watch(dioClientProvider),
    ref.watch(loggerProvider),
  );
});

final verseProvider = StateNotifierProvider<VerseNotifier, DailyVersesState>((
  ref,
) {
  return VerseNotifier(ref.watch(verseRepositoryProvider));
});

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return ContactRepository(
    ref.watch(dioClientProvider),
    ref.watch(loggerProvider),
  );
});

final contactProvider = StateNotifierProvider<ContactNotifier, ContactState>((
  ref,
) {
  return ContactNotifier(ref.watch(contactRepositoryProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    ref.watch(dioClientProvider),
    ref.watch(loggerProvider),
  );
});

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((
  ref,
) {
  return ProfileNotifier(ref.watch(profileRepositoryProvider));
});

// Auth providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(dioClientProvider),
    ref.watch(loggerProvider),
  );
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final notifier = AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(dioClientProvider),
    ref.watch(pushTokenProvider.notifier),
  );

  // Initialize auth when provider is first created
  Future.microtask(() => notifier.initialize());

  // Initialize push token monitoring after auth is set up
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(pushTokenProvider.notifier).initialize();
  });

  return notifier;
});

// Notification service provider (using basic local notifications)
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Push notification service provider (Firebase FCM)
final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  return PushNotificationService();
});

// Push token provider
final pushTokenProvider =
    StateNotifierProvider<PushTokenNotifier, PushTokenState>((ref) {
      return PushTokenNotifier(
        ref.watch(pushNotificationServiceProvider),
        ref.watch(dioClientProvider),
      );
    });

// Country service provider
final countryServiceProvider = Provider<CountryService>((ref) {
  return CountryService(ref.watch(loggerProvider));
});

// XP service provider
final xpServiceProvider = Provider<XPService>((ref) {
  return XPService.instance;
});

// XP provider
final xpProvider = StateNotifierProvider<XPNotifier, XPState>((ref) {
  return XPNotifier(ref.watch(xpServiceProvider));
});

// App Lock providers
final appLockRepositoryProvider = Provider<AppLockRepository>((ref) {
  return AppLockRepository(ref.watch(loggerProvider));
});

final appUsageServiceProvider = Provider<AppUsageService>((ref) {
  return AppUsageService(ref.watch(loggerProvider));
});

final appLockProvider = StateNotifierProvider<AppLockNotifier, AppLockState>((
  ref,
) {
  return AppLockNotifier(
    ref.watch(appLockRepositoryProvider),
    ref.watch(appUsageServiceProvider),
  );
});

// Graduated commitment providers
final graduatedCommitmentRepositoryProvider =
    Provider<GraduatedCommitmentRepository>((ref) {
      return GraduatedCommitmentRepository(ref.watch(loggerProvider));
    });

final graduatedCommitmentProvider =
    StateNotifierProvider<
      GraduatedCommitmentNotifier,
      GraduatedCommitmentState
    >((ref) {
      return GraduatedCommitmentNotifier(
        repository: ref.watch(graduatedCommitmentRepositoryProvider),
        xpService: ref.watch(xpServiceProvider),
        dailyAnchorsNotifier: ref.watch(dailyAnchorsProvider.notifier),
      );
    });

// Commitment Journey providers (3/10/40-day journeys with prayer intentions)
final commitmentJourneyRepositoryProvider =
    Provider<CommitmentJourneyRepository>((ref) {
      return CommitmentJourneyRepository(
        ref.watch(authenticatedDioClientProvider),
        ref.watch(loggerProvider),
      );
    });

final commitmentJourneyProvider =
    StateNotifierProvider<CommitmentJourneyNotifier, CommitmentJourneyState>((
      ref,
    ) {
      return CommitmentJourneyNotifier(
        repository: ref.watch(commitmentJourneyRepositoryProvider),
        xpService: ref.watch(xpServiceProvider),
        notificationService: ref.watch(notificationServiceProvider),
        dailyAnchorsNotifier: ref.watch(dailyAnchorsProvider.notifier),
      );
    });

// Alignment providers
final alignmentRepositoryProvider = Provider<AlignmentRepository>((ref) {
  return AlignmentRepository(ref.watch(loggerProvider));
});

final alignmentProvider =
    StateNotifierProvider<AlignmentNotifier, AlignmentState>((ref) {
      return AlignmentNotifier(ref.watch(alignmentRepositoryProvider));
    });

final habitProvider = StateNotifierProvider<HabitNotifier, HabitState>((ref) {
  return HabitNotifier(ref.watch(alignmentRepositoryProvider));
});

final fortyDayProvider = StateNotifierProvider<FortyDayNotifier, FortyDayState>(
  (ref) {
    return FortyDayNotifier(ref.watch(alignmentRepositoryProvider));
  },
);

// Pillar Score provider — aggregates data across features for the 4 Pillars of Clarity
final pillarScoreProvider =
    StateNotifierProvider<PillarScoreNotifier, PillarScore>((ref) {
      return PillarScoreNotifier(ref);
    });

// Service Opportunity providers
final serviceOpportunityRepositoryProvider =
    Provider<ServiceOpportunityRepository>((ref) {
      return ServiceOpportunityRepository(
        ref.watch(authenticatedDioClientProvider),
        ref.watch(loggerProvider),
      );
    });

final serviceOpportunityProvider =
    StateNotifierProvider<
      ServiceOpportunityNotifier,
      AsyncValue<List<ServiceOpportunity>>
    >((ref) {
      return ServiceOpportunityNotifier(
        ref.watch(serviceOpportunityRepositoryProvider),
      );
    });
