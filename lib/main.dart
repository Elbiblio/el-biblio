import 'dart:async';

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
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timeago locales to prevent warnings.
  timeago.setLocaleMessages('en', timeago.EnMessages());
  timeago.setLocaleMessages('en_US', timeago.EnMessages());

  runApp(const ProviderScope(child: AppStartup()));
}

Future<void> _initializeApp() async {
  await _initializeFirebase();
  await _configureDesktopWindow();
  _configureDesktopDatabase();

  // These services must be ready before CompassApp builds because several
  // providers read Hive boxes synchronously.
  await HiveService.initialize().timeout(
    const Duration(seconds: 20),
    onTimeout: () => throw TimeoutException(
      'Storage initialization timed out. Restart El-Biblio and try again.',
    ),
  );

  await XPService.instance.initialize().timeout(
    const Duration(seconds: 10),
    onTimeout: () => throw TimeoutException(
      'XP initialization timed out. Restart El-Biblio and try again.',
    ),
  );

  unawaited(_deferredInitialization());
}

Future<void> _initializeFirebase() async {
  if (kIsWeb) {
    return;
  }

  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 8));
  } on TimeoutException catch (e) {
    debugPrint('Firebase initialization timed out (continuing): $e');
  } catch (e) {
    debugPrint('Firebase initialization failed (continuing): $e');
  }
}

Future<void> _configureDesktopWindow() async {
  if (kIsWeb || !_isDesktopPlatform) {
    return;
  }

  await windowManager.ensureInitialized();

  // Set tablet-like dimensions (portrait mode).
  await windowManager.setSize(const Size(450, 800));
  await windowManager.setMinimumSize(const Size(400, 700));
  await windowManager.setMaximumSize(const Size(500, 900));
  await windowManager.center();
  await windowManager.setTitle('El-Biblio');

  // Restrict to portrait mode by preventing landscape resizing.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

void _configureDesktopDatabase() {
  if (kIsWeb || !_isDesktopPlatform) {
    return;
  }

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

bool get _isDesktopPlatform =>
    defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.linux ||
    defaultTargetPlatform == TargetPlatform.macOS;

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

class AppStartup extends StatefulWidget {
  const AppStartup({super.key});

  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  late Future<void> _startupFuture;

  @override
  void initState() {
    super.initState();
    _startupFuture = _initializeApp();
  }

  void _retry() {
    setState(() {
      _startupFuture = _initializeApp();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _startupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          return const CompassApp();
        }

        if (snapshot.hasError) {
          debugPrint('App initialization failed: ${snapshot.error}');
          debugPrint('Stack trace: ${snapshot.stackTrace}');
          return StartupErrorApp(error: snapshot.error, onRetry: _retry);
        }

        return const StartupSplashApp();
      },
    );
  }
}

class StartupSplashApp extends StatelessWidget {
  const StartupSplashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF8FBF6),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/app_icon.png',
                width: 88,
                height: 88,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.menu_book_rounded,
                    size: 72,
                    color: Color(0xFF496C54),
                  );
                },
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFF496C54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({
    required this.error,
    required this.onRetry,
    super.key,
  });

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF8FBF6),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Color(0xFFB3261E),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Initialization Error',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF17251B),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'El-Biblio could not start: $error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF34433A),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: onRetry,
                    child: const Text('Try again'),
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
