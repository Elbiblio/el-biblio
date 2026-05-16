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
      'lib/features/vision/presentation/screens/hangout_room_screen.dart',
      'lib/features/social/presentation/invite_screen.dart',
      'lib/features/grow/presentation/screens/grow_hub_screen.dart',
      'lib/features/alignment/presentation/screens/alignment_hub_screen.dart',
      'lib/core/services/notifications/notification_service.dart',
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
      'Daily Return',
      'Mark today\'s return',
      'Return today',
      'returned today',
      'Share on Path',
      'Open Path',
      'Choose a path',
      'Show me the path',
      'Plan your first return',
      'Browse paths',
      'All paths',
      'return freely',
      'same path',
      'Commitment hangout',
      'Open hangout',
      'Gentle prompts to return to your active commitment',
      'Invite Friends',
      'Friends on El-Biblio',
      'Invite Others',
      'Send Invitations',
      'clarity path',
      'identity assessment',
      'Public profile',
      'View public profile',
    ];

    for (final path in paths) {
      final source = File(path).readAsStringSync();
      for (final phrase in blockedPhrases) {
        expect(source, isNot(contains(phrase)), reason: '$path: $phrase');
      }
    }

    final reflectSource = File(
      'lib/features/vision/presentation/screens/reflect_screen.dart',
    ).readAsStringSync().toLowerCase();
    expect(reflectSource, isNot(contains('hangout')));
  });

  test(
    'commitment nudges repeat daily and restart tomorrow after check-in',
    () {
      final source = File(
        'lib/core/services/notifications/notification_service.dart',
      ).readAsStringSync();
      final notifier = File(
        'lib/features/vision/application/vision_notifier.dart',
      ).readAsStringSync();

      expect(
        source,
        contains('matchDateTimeComponents: DateTimeComponents.time'),
      );
      expect(source, contains('bool startTomorrow = false'));
      expect(source, contains('cancelCommitmentNudges'));
      expect(source, contains('Your plan:'));
      expect(source, contains('Watch for:'));
      expect(source, contains('areNotificationsEnabled'));
      expect(notifier, contains('startTomorrow: true'));
    },
  );

  test('core loop persists first check-in context and safety actions', () {
    final settings = File(
      'lib/core/storage/app_settings.dart',
    ).readAsStringSync();
    final repository = File(
      'lib/features/vision/data/vision_repository.dart',
    ).readAsStringSync();
    final onboarding = File(
      'lib/features/onboarding/presentation/onboarding_screen.dart',
    ).readAsStringSync();
    final commit = File(
      'lib/features/vision/presentation/screens/commit_screen.dart',
    ).readAsStringSync();
    final reflect = File(
      'lib/features/vision/presentation/widgets/reflection_feed_widgets.dart',
    ).readAsStringSync();
    final hangout = File(
      'lib/features/vision/presentation/screens/hangout_room_screen.dart',
    ).readAsStringSync();
    final invite = File(
      'lib/features/social/presentation/invite_screen.dart',
    ).readAsStringSync();

    expect(settings, contains('firstCheckInPlanWhen'));
    expect(repository, contains('check_in_plan_when'));
    expect(onboarding, contains('context.go(AppRoutes.today)'));
    expect(commit, contains('planWhen: planWhen'));
    expect(reflect, contains('reportReflection'));
    expect(hangout, contains('reportHangout'));
    expect(hangout, contains('source=hangout'));
    expect(invite, contains('contextType: widget.source'));
  });
}
