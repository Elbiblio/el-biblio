import 'package:elbiblio/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('startup splash renders a visible loading frame', (tester) async {
    await tester.pumpWidget(const StartupSplashApp());

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));

    expect(scaffold.backgroundColor, const Color(0xFFF8FBF6));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('startup error renders retry action', (tester) async {
    var retryCount = 0;

    await tester.pumpWidget(
      StartupErrorApp(
        error: 'storage unavailable',
        onRetry: () {
          retryCount += 1;
        },
      ),
    );

    expect(find.text('Initialization Error'), findsOneWidget);
    expect(find.textContaining('storage unavailable'), findsOneWidget);

    await tester.tap(find.text('Try again'));

    expect(retryCount, 1);
  });
}
