import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper class for creating test widgets with common providers
class TestHelpers {
  /// Creates a test widget with a MaterialApp wrapper
  static Widget createTestWidget({
    required Widget child,
    ThemeData? theme,
  }) {
    return MaterialApp(
      theme: theme ?? ThemeData.light(),
      home: child,
    );
  }

  /// Creates a ProviderScope with overridden providers for testing
  static Widget createTestWidgetWithProviders({
    required Widget child,
    List<Override>? overrides,
    ThemeData? theme,
  }) {
    return ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(
        theme: theme ?? ThemeData.light(),
        home: child,
      ),
    );
  }

  /// Finds a widget by its text content
  static Finder findText(String text) {
    return find.text(text);
  }

  /// Finds a widget by its key
  static Finder findKey(Key key) {
    return find.byKey(key);
  }

  /// Finds a widget by its type
  static Finder findType<T>() {
    return find.byType(T);
  }

  /// Finds a widget by its widget
  static Finder findWidget(Widget widget) {
    return find.byWidget(widget);
  }

  /// Taps a widget and pumps and settles
  static Future<void> tapAndSettle(
    WidgetTester tester,
    Finder finder, {
    Duration duration = const Duration(milliseconds: 100),
  }) async {
    await tester.tap(finder);
    await tester.pump(duration);
    await tester.pumpAndSettle();
  }

  /// Scrolls until a widget is found
  static Future<void> scrollUntilVisible(
    WidgetTester tester,
    Finder scrollable,
    Finder target, {
    double delta = 100.0,
    int maxScrolls = 50,
  }) async {
    int scrollCount = 0;
    while (scrollCount < maxScrolls) {
      if (tester.any(target)) {
        return;
      }
      await tester.drag(scrollable, Offset(0, -delta));
      await tester.pumpAndSettle();
      scrollCount++;
    }
    throw Exception('Could not find widget after $maxScrolls scrolls');
  }
}

/// Extension methods for common widget test operations
extension WidgetTesterX on WidgetTester {
  /// Enters text into a text field
  Future<void> enterText(
    Finder finder,
    String text, {
    bool clearFirst = true,
  }) async {
    await tap(finder);
    await pumpAndSettle();
    
    if (clearFirst) {
      await pumpAndSettle(const Duration(milliseconds: 50));
    }
    
    await enterText(finder, text);
    await pumpAndSettle();
  }
}
