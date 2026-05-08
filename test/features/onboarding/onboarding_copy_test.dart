import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('active onboarding and vision copy avoids deprecated product language', () {
    final paths = [
      'lib/features/onboarding/presentation/onboarding_screen.dart',
      'lib/features/onboarding/presentation/widgets/the_noise_view.dart',
      'lib/features/onboarding/presentation/widgets/the_solution_view.dart',
      'lib/features/onboarding/presentation/widgets/discover_identity_view.dart',
      'lib/features/onboarding/presentation/widgets/your_account_view.dart',
      'lib/features/vision/presentation/screens/today_screen.dart',
      'lib/features/vision/presentation/screens/reflect_screen.dart',
      'lib/features/vision/presentation/screens/commit_screen.dart',
      'lib/features/vision/presentation/screens/tribe_screen.dart',
      'lib/features/vision/presentation/screens/grow_screen.dart',
      'lib/features/vision/presentation/screens/vision_onboarding_flow_screen.dart',
    ];

    const blockedPhrases = [
      'Begin my clarity journey',
      'Games, Faith & Prayer',
      'spiritual superpower',
      'Complete today',
      'room service is live',
      'Crush',
      'Leaderboard',
      'Public feed',
    ];

    for (final path in paths) {
      final source = File(path).readAsStringSync();
      for (final phrase in blockedPhrases) {
        expect(source, isNot(contains(phrase)), reason: '$path: $phrase');
      }
    }
  });
}
