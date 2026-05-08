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
import '../../features/assessment/presentation/calling_profile_screen.dart';
import '../../features/assessment/presentation/assessment_results_screen.dart';
import '../../features/assessment/presentation/weekly_assessment_screen.dart';
import '../../features/bible/presentation/bible_library_screen.dart';
import '../../features/bible/presentation/reading_plan_detail_screen.dart';
import '../../features/bible/presentation/bible_screen.dart';
import '../../features/journal/presentation/journal_screen.dart';
import '../../features/journal/presentation/note_editor_screen.dart';
import '../../features/journal/presentation/note_reader_screen.dart';
import '../../features/meditation/presentation/screens/meditation_home_screen.dart';
import '../../features/meditation/presentation/meditation_screen.dart';
import '../../features/mission/presentation/mission_hub_screen.dart';
import '../../features/mission/presentation/screens/impact_history_screen.dart';
import '../../features/mission/presentation/screens/person_profile_screen.dart';
import '../../features/mission/presentation/screens/service_opportunities_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/vision/presentation/screens/commit_screen.dart';
import '../../features/vision/presentation/screens/grow_screen.dart';
import '../../features/vision/presentation/screens/notifications_screen.dart';
import '../../features/vision/presentation/screens/reflect_screen.dart';
import '../../features/vision/presentation/screens/today_screen.dart';
import '../../features/vision/presentation/screens/tribe_screen.dart';
import '../../features/vision/presentation/screens/vision_onboarding_flow_screen.dart';
import '../../features/profile/presentation/about_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/reminder_settings_screen.dart';
import '../../features/social/presentation/grow_together_screen.dart';
import '../../features/time_diagnose/presentation/screens/time_diagnose_start_screen.dart';
import '../../features/time_diagnose/presentation/screens/time_diagnose_configure_screen.dart';
import '../../features/time_diagnose/presentation/screens/time_diagnose_analysis_screen.dart';
import '../../features/app_lock/presentation/screens/app_lock_dashboard_screen.dart';
import '../../features/app_lock/presentation/screens/app_lock_setup_screen.dart';
import '../../features/app_lock/presentation/screens/app_lock_limit_reached_screen.dart';
import '../../features/social/presentation/invite_screen.dart';
import '../../features/commitments/presentation/screens/commitment_journey_screen_new.dart';
import '../../features/companion/presentation/screens/companion_chat_screen.dart';
import '../../features/churches/presentation/screens/church_finder_screen.dart';
import '../../features/commitments/presentation/screens/journey_selection_screen.dart';
import '../../features/commitments/presentation/screens/commitment_active_screen.dart';
import '../../features/commitments/presentation/screens/commitment_completion_screen.dart';
import '../../features/spiritual_aid/presentation/screens/spiritual_aid_hub_screen.dart';
import '../../features/spiritual_aid/presentation/screens/quick_prayer_screen.dart';
import '../../features/spiritual_aid/presentation/screens/faith_discuss_screen.dart';
import '../../features/spiritual_aid/presentation/screens/speak_to_me_screen.dart';
import '../../features/spiritual_aid/presentation/screens/evangelism_helper_screen.dart';
import '../../features/games/presentation/screens/games_hub_screen.dart';
import '../../features/games/presentation/screens/journey_map_screen.dart';
import '../../features/games/presentation/screens/post_game_reading_screen.dart';
import '../../features/bible/presentation/games/verse_game_screen.dart';
import '../../features/alignment/presentation/screens/alignment_hub_screen.dart';
import '../../features/alignment/presentation/screens/spiritual_profile_screen.dart';
import '../../features/alignment/presentation/screens/habit_assessment_screen.dart';
import '../../features/alignment/presentation/screens/habit_tracker_screen.dart';
import '../../features/alignment/presentation/screens/forty_day_setup_screen.dart';
import '../../features/alignment/presentation/screens/forty_day_progress_screen.dart';
import '../../features/alignment/presentation/screens/career_alignment_screen.dart';
import '../../features/faith_questions/presentation/screens/faith_questions_hub_screen.dart';
import '../../features/faith_questions/presentation/screens/faith_faq_screen.dart';
import '../../features/faith_questions/presentation/screens/faith_quiz_screen.dart';
import '../../features/faith_questions/presentation/screens/faith_quiz_results_screen.dart';
import '../theme/app_animations.dart';
import '../../shared/widgets/app_shell.dart';

/// Subtle fast-fade page transition for shell routes (bottom-nav tabs).
Page<void> _fadePage({required Widget child, LocalKey? key}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: AppAnimations.fast,
    reverseTransitionDuration: AppAnimations.fast,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: AppAnimations.fadeCurve,
        ),
        child: child,
      );
    },
  );
}

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
    settingsProvider.select((value) => value.hasCompletedPostOnboarding),
    (_, __) => notifier.trigger(),
  );

  ref.listen<bool>(
    authProvider.select((value) => value.isAuthenticated),
    (_, __) => notifier.trigger(),
  );

  // Intentionally NOT listening to `accountabilityCadence`, `christianLifeBaseline`,
  // `goodHabits`, `struggles`, or `onboardingDraft` — those shape content, not
  // routing. Listening to them would trigger spurious GoRouter rebuilds on
  // every onboarding keystroke. Keep the listen-set narrow.

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
        builder: (context, state) => const Scaffold(
          backgroundColor: Color(0xFFF7FCF6),
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.postOnboarding,
        builder: (context, state) => const VisionOnboardingFlowScreen(),
      ),
      GoRoute(
        path: AppRoutes.bibleReader,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final bookName = Uri.decodeComponent(
            state.uri.queryParameters['book'] ?? '',
          );
          final chapter = state.uri.queryParameters['chapter'];
          final verse = state.uri.queryParameters['verse'];
          final isPlanMode = state.uri.queryParameters['planMode'] == 'true';
          final fromLibrary =
              state.uri.queryParameters['fromLibrary'] == 'true';

          return BibleScreen(
            bookName: bookName.isNotEmpty ? bookName : null,
            chapter: chapter != null ? int.tryParse(chapter) : null,
            verse: verse != null ? int.tryParse(verse) : null,
            isPlanMode: isPlanMode,
            openChapterSelector: fromLibrary,
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
        builder: (context, state) => const CommitmentJourneyScreenNew(),
      ),
      GoRoute(
        path: AppRoutes.journeySelection,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const JourneySelectionScreen(),
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
        path: AppRoutes.gamesVerseScramble,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const VerseGameScreen(),
      ),
      GoRoute(
        path: AppRoutes.gamesJourney,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const JourneyMapScreen(),
      ),
      GoRoute(
        path: AppRoutes.gamesPostReading,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return PostGameReadingScreen(
            bibleReference: extra['bibleReference'] as String? ?? '',
            xpEarned: extra['xpEarned'] as int? ?? 0,
            gameTitle: extra['gameTitle'] as String? ?? 'Game Complete',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.alignment,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AlignmentHubScreen(),
        routes: [
          GoRoute(
            path: 'profile',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const SpiritualProfileScreen(),
          ),
          GoRoute(
            path: 'habit-assessment',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const HabitAssessmentScreen(),
          ),
          GoRoute(
            path: 'habit-tracker',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const HabitTrackerScreen(),
          ),
          GoRoute(
            path: 'forty-day-setup',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const FortyDaySetupScreen(),
          ),
          GoRoute(
            path: 'forty-day-progress',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const FortyDayProgressScreen(),
          ),
          GoRoute(
            path: 'career',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const CareerAlignmentScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.faithQuestions,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FaithQuestionsHubScreen(),
        routes: [
          GoRoute(
            path: 'faq',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const FaithFaqScreen(),
          ),
          GoRoute(
            path: 'quiz',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const FaithQuizScreen(),
          ),
          GoRoute(
            path: 'quiz-results',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const FaithQuizResultsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.about,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: AppRoutes.weeklyAssessment,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WeeklyAssessmentScreen(),
      ),
      GoRoute(
        path: AppRoutes.companionChat,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final thread = state.uri.queryParameters['thread'] ?? 'default';
          final mode = state.uri.queryParameters['mode'] ?? 'default';
          final title = state.uri.queryParameters['title'];
          final extra = state.extra as Map<String, dynamic>?;
          final seed = extra?['seedAssistantOpener'] as String?;
          return CompanionChatScreen(
            threadKey: thread,
            mode: mode,
            title: title,
            seedAssistantOpener: seed,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.churchesNearby,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ChurchFinderScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.meditation}/session',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MeditationScreen(),
      ),
      GoRoute(
        path: AppRoutes.spiritualAid,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SpiritualAidHubScreen(),
        routes: [
          GoRoute(
            path: 'prayers',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const QuickPrayerScreen(),
          ),
          GoRoute(
            path: 'discuss',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const FaithDiscussScreen(),
          ),
          GoRoute(
            path: 'speak',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const SpeakToMeScreen(),
          ),
          GoRoute(
            path: 'evangelism',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const EvangelismHelperScreen(),
          ),
        ],
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.today,
            pageBuilder: (context, state) =>
                _fadePage(child: const TodayScreen()),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            pageBuilder: (context, state) =>
                _fadePage(child: const NotificationsScreen()),
          ),
          GoRoute(
            path: AppRoutes.reflect,
            pageBuilder: (context, state) =>
                _fadePage(child: const ReflectScreen()),
          ),
          GoRoute(
            path: AppRoutes.commit,
            pageBuilder: (context, state) =>
                _fadePage(child: const CommitScreen()),
          ),
          GoRoute(
            path: AppRoutes.tribe,
            pageBuilder: (context, state) =>
                _fadePage(child: const TribeScreen()),
          ),
          GoRoute(
            path: AppRoutes.legacyChallenge,
            redirect: (context, state) => AppRoutes.commit,
          ),
          GoRoute(
            path: AppRoutes.legacyTribes,
            redirect: (context, state) => AppRoutes.tribe,
          ),
          GoRoute(
            path: AppRoutes.legacyQuestions,
            redirect: (context, state) => AppRoutes.grow,
          ),
          GoRoute(
            path: AppRoutes.act,
            pageBuilder: (context, state) =>
                _fadePage(child: const MissionHubScreen()),
            routes: [
              GoRoute(
                path: 'history',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const ImpactHistoryScreen(),
              ),
              GoRoute(
                path: 'opportunities',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const ServiceOpportunitiesScreen(),
              ),
              GoRoute(
                path: 'people/:id',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) =>
                    PersonProfileScreen(personId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.growTogether,
            pageBuilder: (context, state) =>
                _fadePage(child: const GrowTogetherScreen()),
          ),
          GoRoute(
            path: AppRoutes.grow,
            pageBuilder: (context, state) =>
                _fadePage(child: const GrowScreen()),
          ),
          GoRoute(
            path: AppRoutes.assessment,
            pageBuilder: (context, state) =>
                _fadePage(child: const FearFirstAssessmentScreen()),
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
              GoRoute(
                path: 'calling-profile',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const CallingProfileScreen(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.bible,
            pageBuilder: (context, state) =>
                _fadePage(child: const BibleLibraryScreen()),
          ),
          GoRoute(
            path: AppRoutes.meditation,
            pageBuilder: (context, state) =>
                _fadePage(child: const MeditationHomeScreen()),
          ),
          GoRoute(
            path: AppRoutes.journal,
            pageBuilder: (context, state) =>
                _fadePage(child: const JournalScreen()),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return NoteEditorScreen(
                    initialTitle: extra?['initialTitle'] as String?,
                    initialText: extra?['initialText'] as String?,
                    initialVirtues: extra?['initialVirtues'] as List<String>?,
                    meditationSessionId:
                        extra?['meditationSessionId'] as String?,
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
            path: AppRoutes.games,
            pageBuilder: (context, state) =>
                _fadePage(child: const GamesHubScreen()),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) =>
                _fadePage(child: const ProfileScreen()),
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
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;
      final isOnboarding = loc == AppRoutes.onboarding;
      final isPostOnboarding = loc == AppRoutes.postOnboarding;

      if (auth.isInitialized && !auth.isAuthenticated) {
        return isOnboarding ? null : AppRoutes.onboarding;
      }

      // Root redirect
      if (loc == AppRoutes.root) {
        if (!settings.onboardingCompleted) return AppRoutes.onboarding;
        if (!settings.hasCompletedPostOnboarding) {
          return AppRoutes.postOnboarding;
        }
        return AppRoutes.today;
      }

      // Guard: must complete onboarding first
      if (!settings.onboardingCompleted) {
        return isOnboarding ? null : AppRoutes.onboarding;
      }

      // Guard: must complete post-onboarding before accessing the app
      if (!settings.hasCompletedPostOnboarding) {
        return isPostOnboarding ? null : AppRoutes.postOnboarding;
      }

      // Already completed — redirect away from onboarding screens
      if (isOnboarding || isPostOnboarding) {
        return AppRoutes.today;
      }

      return null;
    },
  );
});
