import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('solution onboarding screen uses one intentional light reveal', () {
    final source = File(
      'lib/features/onboarding/presentation/widgets/the_solution_view.dart',
    ).readAsStringSync();
    final revealCount = RegExp(r'LightRaysReveal\(').allMatches(source).length;

    expect(revealCount, 1);
    expect(source, contains('rotate: false'));
  });

  test('repeated light animation respects reduced motion', () {
    final source = File(
      'lib/shared/widgets/light_rays_reveal.dart',
    ).readAsStringSync();

    expect(source, contains('disableAnimations'));
    expect(source, contains('!reducedMotion'));
  });
}
