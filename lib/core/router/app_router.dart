import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../constants/app_routes.dart';
import '../di/app_providers.dart';
import '../services/notifications/notification_service.dart';
import '../../features/assessment/presentation/fear_first_assessment_screen.dart';
import '../../features/assessment/presentation/assessment_screen.dart';
import '../../features/assessment/presentation/assessment_rating_screen.dart';
import '../../features/assessment/presentation/assessment_path_screen.dart';
import '../../features/assessment/presentation/assessment_action_plan_screen.dart';
import '../../features/assessment/presentation/assessment_results_screen.dart';
import '../../features/bible/presentation/bible_library_screen.dart';
import '../../features/bible/presentation/reading_plan_detail_screen.dart';
import '../../features/bible/presentation/bible_screen.dart';
import '../../features/journal/presentation/journal_screen.dart';
import '../../features/journal/presentation/note_editor_screen.dart';
import '../../features/journal/presentation/note_reader_screen.dart';
import '../../features/meditation/presentation/screens/meditation_home_screen.dart';
import '../../features/meditation/presentation/meditation_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/presentation/pre_onboarding_screen.dart';
import '../../features/profile/presentation/about_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/reminder_settings_screen.dart';
import '../../features/time_diagnose/presentation/screens/time_diagnose_start_screen.dart';
import '../../features/time_diagnose/presentation/screens/time_diagnose_configure_screen.dart';
import '../../features/time_diagnose/presentation/screens/time_diagnose_analysis_screen.dart';
import '../../features/app_lock/presentation/screens/app_lock_dashboard_screen.dart';
import '../../features/app_lock/presentation/screens/app_lock_setup_screen.dart';
import '../../features/app_lock/presentation/screens/app_lock_limit_reached_screen.dart';
import '../../features/social/presentation/invite_screen.dart';
import '../../features/commitments/presentation/screens/commitment_journey_screen.dart';
import '../../features/commitments/presentation/screens/commitment_active_screen.dart';
import '../../features/commitments/presentation/screens/commitment_completion_screen.dart';
import '../../features/today/presentation/today_screen.dart';
import '../../shared/widgets/app_shell.dart';

final _rootNavigatorKey = NotificationService.navigatorKey;
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class _RouterRefreshNotifier extends ChangeNotifier {
  void trigger() => notifyListeners();
}

final _routerRefreshProvider = Provider<_RouterRefreshNotifier>((ref) {
  final notifier = _RouterRefreshNotifier();

  ref.listen<bool>(
    settingsProvider.select((value) => value.onboardingCompleted),
    (_, __) => notifier.trigger(),
  );

  ref.listen<bool>(
    settingsProvider.select((value) => value.hasCompletedPreOnboarding),
    (_, __) => notifier.trigger(),
  );

  ref.listen<bool>(
    authProvider.select((value) => value.isAuthenticated),
    (_, __) => notifier.trigger(),
  );

  ref.onDispose(notifier.dispose);
  return notifier;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(_routerRefreshProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.root,
    refreshListenable: refresh,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: '/pre-onboarding',
        builder: (context, state) => const PreOnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.bibleReader,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final bookName =
              Uri.decodeComponent(state.uri.queryParameters['book'] ?? '');
          final chapter = state.uri.queryParameters['chapter'];
          final verse = state.uri.queryParameters['verse'];
          final isPlanMode = state.uri.queryParameters['planMode'] == 'true';

          return BibleScreen(
            bookName: bookName.isNotEmpty ? bookName : null,
            chapter: chapter != null ? int.tryParse(chapter) : null,
            verse: verse != null ? int.tryParse(verse) : null,
            isPlanMode: isPlanMode,
          );
        },
      ),
      GoRoute(
        path: '${AppRoutes.biblePlanDetails}/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final idRaw = state.pathParameters['id'];
          final id = int.tryParse(idRaw ?? '');

          return ReadingPlanDetailScreen(planId: id ?? 0);
        },
      ),
      GoRoute(
        path: AppRoutes.timeDiagnose,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TimeDiagnoseStartScreen(),
        routes: [
          GoRoute(
            path: 'configure',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const TimeDiagnoseConfigureScreen(),
          ),
          GoRoute(
            path: 'analysis',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const TimeDiagnoseAnalysisScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.appLockDashboard,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AppLockDashboardScreen(),
        routes: [
          GoRoute(
            path: 'setup',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const AppLockSetupScreen(),
          ),
          GoRoute(
            path: 'limit-reached',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final packageName = state.uri.queryParameters['package'] ?? '';
              return AppLockLimitReachedScreen(packageName: packageName);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/invite',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const InviteScreen(),
      ),
      GoRoute(
        path: AppRoutes.commitmentJourney,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CommitmentJourneyScreen(),
      ),
      GoRoute(
        path: AppRoutes.commitmentActive,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CommitmentActiveScreen(),
      ),
      GoRoute(
        path: AppRoutes.commitmentCompletion,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CommitmentCompletionScreen(),
      ),
      GoRoute(
        path: AppRoutes.about,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.meditation}/session',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MeditationScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.today,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TodayScreen()),
          ),
          GoRoute(
            path: AppRoutes.assessment,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: FearFirstAssessmentScreen()),
            routes: [
              GoRoute(
                path: 'compass',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const AssessmentScreen(),
              ),
              GoRoute(
                path: 'quick-results',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const AssessmentResultsScreen(),
              ),
              GoRoute(
                path: 'rating',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const AssessmentRatingScreen(),
              ),
              GoRoute(
                path: 'path',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const AssessmentPathScreen(),
              ),
              GoRoute(
                path: 'action-plan',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const AssessmentActionPlanScreen(),
              ),
              GoRoute(
                path: 'results',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const AssessmentResultsScreen(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.bible,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: BibleLibraryScreen()),
          ),
          GoRoute(
            path: AppRoutes.meditation,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MeditationHomeScreen()),
          ),
          GoRoute(
            path: AppRoutes.journal,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: JournalScreen()),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return NoteEditorScreen(
                    initialTitle: extra?['initialTitle'] as String?,
                    initialText: extra?['initialText'] as String?,
                    initialVirtues: extra?['initialVirtues'] as List<String>?,
                  );
                },
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id'];
                  return NoteReaderScreen(noteId: id!);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return NoteEditorScreen(noteId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
            routes: [
              GoRoute(
                path: 'reminders',
                builder: (context, state) => const ReminderSettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final settings = ref.read(settingsProvider);
      final authState = ref.read(authProvider);

      final isPreOnboarding = state.matchedLocation == '/pre-onboarding';
      final isOnboarding = state.matchedLocation == AppRoutes.onboarding;

      if (state.matchedLocation == AppRoutes.root) {
        if (settings.onboardingCompleted &&
            settings.hasCompletedPreOnboarding) {
          // If both onboarding and pre-onboarding are complete, go to today
          return AppRoutes.today;
        } else if (settings.onboardingCompleted &&
            !settings.hasCompletedPreOnboarding) {
          // Onboarding complete but account not created - go to pre-onboarding
          return '/pre-onboarding';
        } else {
          // Always start with onboarding flow first
          return AppRoutes.onboarding;
        }
      }

      // If user hasn't completed onboarding, keep them in onboarding
      if (!settings.onboardingCompleted) {
        if (isOnboarding) {
          return null;
        }
        return AppRoutes.onboarding;
      }

      // If onboarding is complete but not authenticated, they need to create account
      if (!authState.isAuthenticated && !settings.hasCompletedPreOnboarding) {
        if (isPreOnboarding) {
          return null;
        }
        return '/pre-onboarding';
      }

      if (isPreOnboarding ||
          isOnboarding ||
          state.matchedLocation == AppRoutes.root) {
        return AppRoutes.today;
      }

      return null;
    },
  );
});
