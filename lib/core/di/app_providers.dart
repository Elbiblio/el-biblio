import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../features/bible/application/bible_notifier.dart';
import '../../features/bible/application/bible_reading_notifier.dart';
import '../../features/bible/application/verse_notifier.dart';
import '../../features/bible/data/bible_repository.dart';
import '../../features/bible/data/bible_reading_repository.dart';
import '../../features/bible/data/verse_repository.dart';
import '../../features/bible/data/services/bible_database_service.dart';
import '../../features/journal/application/journal_notifier.dart';
import '../../features/journal/application/journal_state.dart';
import '../../features/journal/data/journal_repository.dart';
import '../../features/today/application/daily_anchors_notifier.dart';
import '../../features/today/application/virtue_notifier.dart';
import '../../features/today/application/virtue_state.dart';
import '../../features/today/data/daily_anchors_repository.dart';
import '../../features/today/domain/models/daily_anchors.dart';
import '../application/settings_notifier.dart';
import '../network/dio_client.dart';
import '../services/sound_service.dart';
import '../storage/app_settings.dart';
import '../storage/settings_storage.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';

final loggerProvider = Provider<Logger>((ref) {
  return Logger();
});

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(ref.watch(loggerProvider));
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

final dailyAnchorsProvider = StateNotifierProvider<DailyAnchorsNotifier, DailyAnchors>((ref) {
  return DailyAnchorsNotifier(
    ref: ref,
    repository: ref.watch(dailyAnchorsRepositoryProvider),
  );
});

final virtueProvider = StateNotifierProvider<VirtueNotifier, VirtueState>((ref) {
  final settings = ref.watch(settingsProvider);

  final notifier = VirtueNotifier(
    VirtueState.initial(
      primaryVirtue: settings.primaryVirtue,
      neglectedVirtue: settings.neglectedVirtue,
    ),
  );

  ref.listen<AppSettings>(settingsProvider, (previous, next) {
    notifier.syncFromSettings(
      primaryVirtue: next.primaryVirtue,
      neglectedVirtue: next.neglectedVirtue,
    );
  });

  return notifier;
});

// Mood provider is defined in mood_notifier.dart

final bibleDatabaseServiceProvider = Provider<BibleDatabaseService>((ref) {
  return BibleDatabaseService(ref.watch(loggerProvider));
});

final bibleRepositoryProvider = Provider<BibleRepository>((ref) {
  return BibleRepository(
    ref.watch(dioClientProvider),
    ref.watch(loggerProvider),
    ref.watch(bibleDatabaseServiceProvider),
  );
});

final bibleReadingRepositoryProvider = Provider<BibleReadingRepository>((ref) {
  return BibleReadingRepository(
    ref.watch(dioClientProvider),
    ref.watch(loggerProvider),
  );
});
final bibleReadingProvider = StateNotifierProvider<BibleReadingNotifier, BibleReadingState>((ref) {
  return BibleReadingNotifier(ref.watch(bibleReadingRepositoryProvider));
});

final bibleProvider = StateNotifierProvider<BibleNotifier, BibleState>((ref) {
  final settings = ref.watch(settingsProvider);
  return BibleNotifier(
    ref.watch(bibleRepositoryProvider),
    ref.watch(settingsStorageProvider),
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

