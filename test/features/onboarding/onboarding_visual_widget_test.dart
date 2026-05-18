import 'package:elbiblio/core/theme/app_theme.dart';
import 'package:elbiblio/core/theme/app_theme_mode.dart';
import 'package:elbiblio/core/theme/app_theme_time.dart';
import 'package:elbiblio/features/onboarding/presentation/widgets/the_noise_view.dart';
import 'package:elbiblio/features/onboarding/presentation/widgets/the_solution_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const viewports = <Size>[Size(390, 844), Size(768, 1024), Size(1280, 800)];

  for (final size in viewports) {
    testWidgets(
      'opening screen renders cleanly at ${size.width}x${size.height}',
      (tester) async {
        await _pumpOnboardingViewport(
          tester,
          size: size,
          child: const TheNoiseView(),
        );

        expect(
          find.text('Make room for the life God is forming in you.'),
          findsOneWidget,
        );
        expect(find.text('Elbiblio'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'solution screen renders cleanly at ${size.width}x${size.height}',
      (tester) async {
        await _pumpOnboardingViewport(
          tester,
          size: size,
          child: const TheSolutionView(),
        );

        expect(find.textContaining('A quieter path'), findsOneWidget);
        expect(find.text('Spiritual compass'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Future<void> _pumpOnboardingViewport(
  WidgetTester tester, {
  required Size size,
  required Widget child,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final theme = AppThemeFactory.build(
    const AppTheme(
      mode: AppThemeMode.adaptive,
      brightness: Brightness.light,
      timeOfDay: AppThemeTimeOfDay.morning,
    ),
    textScaleFactor: 1,
  );

  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: SafeArea(
          child: MediaQuery(
            data: MediaQueryData(size: size),
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
