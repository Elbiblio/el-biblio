import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../constants/app_routes.dart';
import '../di/app_providers.dart';
import '../../features/assessment/presentation/assessment_screen.dart';
import '../../features/bible/presentation/bible_screen.dart';
import '../../features/journal/presentation/journal_screen.dart';
import '../../features/journal/presentation/note_editor_screen.dart';
import '../../features/meditation/presentation/meditation_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen_refactored.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/today/presentation/today_screen.dart';

class _RouterRefreshNotifier extends ChangeNotifier {
  void trigger() => notifyListeners();
}

final _routerRefreshProvider = Provider<_RouterRefreshNotifier>((ref) {
  final notifier = _RouterRefreshNotifier();

  ref.listen<bool>(
    settingsProvider.select((value) => value.onboardingCompleted),
    (_, __) => notifier.trigger(),
  );

  ref.onDispose(notifier.dispose);
  return notifier;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(_routerRefreshProvider);

  return GoRouter(
    initialLocation: AppRoutes.root,
    refreshListenable: refresh,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreenRefactored(),
      ),
      GoRoute(
        path: AppRoutes.today,
        builder: (context, state) => const TodayScreen(),
      ),
      GoRoute(
        path: AppRoutes.assessment,
        builder: (context, state) => const AssessmentScreen(),
      ),
      GoRoute(
        path: AppRoutes.bible,
        builder: (context, state) => const BibleScreen(),
      ),
      GoRoute(
        path: AppRoutes.meditation,
        builder: (context, state) => const MeditationScreen(),
      ),
      GoRoute(
        path: AppRoutes.journal,
        builder: (context, state) => const JournalScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const NoteEditorScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = state.pathParameters['id'];
              return NoteEditorScreen(noteId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
    redirect: (context, state) {
      final settings = ref.read(settingsProvider);
      const onboardingPath = AppRoutes.onboarding;
      final isOnboarding = state.matchedLocation == onboardingPath;

      if (state.matchedLocation == AppRoutes.root) {
        return settings.onboardingCompleted ? AppRoutes.today : onboardingPath;
      }

      if (!settings.onboardingCompleted) {
        return isOnboarding ? null : onboardingPath;
      }

      if (isOnboarding || state.matchedLocation == AppRoutes.root) {
        return AppRoutes.today;
      }

      return null;
    },
  );
});
