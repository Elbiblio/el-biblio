import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/app_providers.dart';
import 'core/router/app_router.dart';
import 'core/storage/hive_service.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.initialize();

  runApp(const ProviderScope(child: CompassApp()));
}

class CompassApp extends ConsumerWidget {
  const CompassApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(themeProvider);
    final router = ref.watch(appRouterProvider);
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
