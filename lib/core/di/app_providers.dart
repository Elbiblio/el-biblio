import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../features/auth/application/auth_notifier.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/domain/models/auth_models.dart';
import '../../features/assessment/data/assessment_api_repository.dart';
import '../../features/bible/application/bible_notifier.dart';
import '../../features/bible/application/bible_reading_notifier.dart';
import '../../features/bible/application/reading_plan_notifier.dart';
import '../../features/bible/application/verse_notifier.dart';
import '../../features/bible/data/bible_repository.dart';
import '../../features/bible/data/bible_reading_repository.dart';
import '../../features/bible/data/reading_plan_repository.dart';
import '../../features/bible/data/verse_repository.dart';
import '../../features/bible/data/services/bible_database_service.dart';
import '../../features/bible/data/services/bible_history_service.dart';
import '../../features/journal/application/journal_notifier.dart';
import '../../features/journal/application/journal_state.dart';
import '../../features/journal/data/journal_repository.dart';
import '../../features/profile/application/profile_notifier.dart';
import '../../features/profile/data/profile_repository.dart';
import '../../features/social/application/contact_notifier.dart';
import '../../features/social/application/contact_state.dart';
import '../../features/social/data/contact_repository.dart';
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
import '../application/settings_notifier.dart';
import '../application/push_token_notifier.dart';
import '../network/dio_client.dart';
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

final meditationSessionRepositoryProvider = Provider<MeditationSessionRepository>((ref) {
  return MeditationSessionRepository(Hive.box<MeditationSession>(HiveBoxes.meditationSessions));
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

final assessmentApiRepositoryProvider = Provider<AssessmentApiRepository>((ref) {
  return AssessmentApiRepository(
    ref.watch(authenticatedDioClientProvider),
    ref.watch(loggerProvider),
  );
});

final settingsStorageProvider = Provider<SettingsStorage>((ref) {
  return const SettingsStorage();
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.watch(settingsStorageProvider));
});

final soundServiceProvider = Provider<SoundService>((ref) {
  return SoundService();
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

final journalProvider = StateNotifierProvider<JournalNotifier, JournalState>((ref) {
  return JournalNotifier(ref.watch(journalRepositoryProvider));
});

final dailyAnchorsRepositoryProvider = Provider<DailyAnchorsRepository>((ref) {
  return DailyAnchorsRepository(ref.watch(loggerProvider));
});

final dailyAnchorsSyncRepositoryProvider = Provider<DailyAnchorsSyncRepository>((ref) {
  return DailyAnchorsSyncRepository(
    ref.watch(authenticatedDioClientProvider),
    ref.watch(loggerProvider),
  );
});

final dailyAnchorsProvider = StateNotifierProvider<DailyAnchorsNotifier, DailyAnchors>((ref) {
  return DailyAnchorsNotifier(
    ref: ref,
    repository: ref.watch(dailyAnchorsRepositoryProvider),
    syncRepository: ref.watch(dailyAnchorsSyncRepositoryProvider),
  );
});

final virtueProvider = StateNotifierProvider<VirtueNotifier, VirtueState>((ref) {
  final settings = ref.watch(settingsProvider);

  final notifier = VirtueNotifier(
    VirtueState.initial(
      primaryVirtue: settings.primaryVirtue,
    ),
  );

  ref.listen<AppSettings>(settingsProvider, (previous, next) {
    notifier.syncFromSettings(
      primaryVirtue: next.primaryVirtue,
    );
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

final commitmentProvider = StateNotifierProvider<CommitmentNotifier, CommitmentState>((ref) {
  return CommitmentNotifier(
    repository: ref.watch(commitmentRepositoryProvider),
  );
});

// Mood provider is defined in mood_notifier.dart

final bibleDatabaseServiceProvider = Provider<BibleDatabaseService>((ref) {
  return BibleDatabaseService(ref.watch(loggerProvider));
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
final bibleReadingProvider = StateNotifierProvider<BibleReadingNotifier, BibleReadingState>((ref) {
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

final readingPlanProvider = StateNotifierProvider<ReadingPlanNotifier, ReadingPlanState>((ref) {
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

final verseProvider = StateNotifierProvider<VerseNotifier, DailyVersesState>((ref) {
  return VerseNotifier(ref.watch(verseRepositoryProvider));
});

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return ContactRepository(
    ref.watch(dioClientProvider),
    ref.watch(loggerProvider),
  );
});

final contactProvider = StateNotifierProvider<ContactNotifier, ContactState>((ref) {
  return ContactNotifier(ref.watch(contactRepositoryProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    ref.watch(dioClientProvider),
    ref.watch(loggerProvider),
  );
});

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
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
final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService();
});

// Push token provider
final pushTokenProvider = StateNotifierProvider<PushTokenNotifier, PushTokenState>((ref) {
  return PushTokenNotifier(
    ref.watch(pushNotificationServiceProvider),
    ref.watch(dioClientProvider),
  );
});

// Country service provider
final countryServiceProvider = Provider<CountryService>((ref) {
  return CountryService(
    ref.watch(dioClientProvider),
    ref.watch(loggerProvider),
  );
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

final appLockProvider = StateNotifierProvider<AppLockNotifier, AppLockState>((ref) {
  return AppLockNotifier(ref.watch(appLockRepositoryProvider));
});
