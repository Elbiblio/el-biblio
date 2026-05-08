import 'package:elbiblio/core/theme/app_typography.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app typography uses stable spacing and readable UI body styles', () {
    final textTheme = AppTypography.textTheme(1);
    final styles = [
      textTheme.displayLarge,
      textTheme.displayMedium,
      textTheme.displaySmall,
      textTheme.headlineLarge,
      textTheme.headlineMedium,
      textTheme.headlineSmall,
      textTheme.titleLarge,
      textTheme.titleMedium,
      textTheme.titleSmall,
      textTheme.bodyLarge,
      textTheme.bodyMedium,
      textTheme.bodySmall,
      textTheme.labelLarge,
      textTheme.labelMedium,
      textTheme.labelSmall,
    ];

    for (final style in styles) {
      expect(style?.letterSpacing, 0);
    }

    expect(textTheme.bodyMedium?.fontFamily, 'Inter');
    expect(textTheme.titleMedium?.fontFamily, 'Inter');
    expect(textTheme.headlineMedium?.fontFamily, 'InstrumentSerif');
  });
}
