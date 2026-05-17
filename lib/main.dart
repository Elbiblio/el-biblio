import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:window_manager/window_manager.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'core/di/app_providers.dart';
import 'core/router/app_router.dart';
import 'core/services/notifications/notification_service.dart';
import 'core/services/xp_service.dart';
import 'core/storage/hive_service.dart';
import 'core/theme/app_theme.dart';
import 'features/bible/data/services/enhanced_bible_database_service.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize timeago locales to prevent warnings
    timeago.setLocaleMessages('en', timeago.EnMessages());
    timeago.setLocaleMessages('en_US', timeago.EnMessages());

    // Initialize Firebase only on mobile platforms with error handling
    if (!kIsWeb) {
      try {
        await Firebase.initializeApp();
      } catch (e) {
        debugPrint(
          'Firebase initialization failed (continuing without Firebase): $e',
        );
        // Continue without Firebase - this shouldn't block the app
      }
    }

    // Configure window for desktop platforms (Windows, macOS, Linux)
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      await windowManager.ensureInitialized();

      // Set tablet-like dimensions (portrait mode)
      await windowManager.setSize(const Size(450, 800));
      await windowManager.setMinimumSize(const Size(400, 700));
      await windowManager.setMaximumSize(const Size(500, 900));

      // Center the window on screen
      await windowManager.center();

      // Set window title
      await windowManager.setTitle('El-Biblio');

      // Restrict to portrait mode by preventing landscape resizing
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }

    // Initialize SQLite FFI only on desktop platforms
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // Initialize core services first
    await HiveService.initialize();

    // Initialize XP service
    await XPService.instance.initialize();

    runApp(const ProviderScope(child: CompassApp()));

    // Defer heavy initialization to after app is running
    _deferredInitialization();
  } catch (e, stackTrace) {
    debugPrint('App initialization failed: $e');
    debugPrint('Stack trace: $stackTrace');

    // Show error screen instead of hanging on splash
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Initialization Error',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ElBiblio could not start: $e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Restart ElBiblio or contact support.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Defer heavy initialization to prevent blocking main thread
Future<void> _deferredInitialization() async {
  try {
    // Use compute to move heavy operations off main thread
    Future.microtask(() async {
      // Initialize Notifications with error handling
      try {
        await NotificationService().initialize();
      } catch (e) {
        debugPrint('Notification initialization failed: $e');
        // Continue without notifications
      }
    });

    // Defer Bible database initialization - just ensure default DB is copied
    // Don't create a standalone service here; the provider-managed instance
    // (bibleDatabaseServiceProvider) handles lifecycle. We only need to
    // ensure the bundled asset is copied to disk so the first read is fast.
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        final bibleService = EnhancedBibleDatabaseService(Logger());
        await bibleService.init();
        // Do NOT dispose here - that removes the WidgetsBinding observer
        // and closes all database connections. The provider-managed instance
        // will handle its own lifecycle.
      } catch (e) {
        debugPrint('Bible database initialization failed: $e');
        // Continue without Bible database
      }
    });
  } catch (e) {
    debugPrint('Deferred initialization failed: $e');
  }
}

class CompassApp extends ConsumerWidget {
  const CompassApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(themeProvider);
    final router = ref.watch(appRouterProvider);
    ref.watch(pendingCompassSyncProvider);
    final textScaleFactor =
        WidgetsBinding.instance.platformDispatcher.textScaleFactor;

    final lightTheme = AppThemeFactory.build(
      appTheme.copyWith(brightness: Brightness.light),
      textScaleFactor: textScaleFactor,
    );

    final darkTheme = AppThemeFactory.build(
      appTheme.copyWith(brightness: Brightness.dark),
      textScaleFactor: textScaleFactor,
    );

    final themeMode = appTheme.brightness == Brightness.dark
        ? ThemeMode.dark
        : ThemeMode.light;

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
