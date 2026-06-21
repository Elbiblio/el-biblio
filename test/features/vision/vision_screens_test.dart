import 'package:elbiblio/core/application/settings_notifier.dart';
import 'package:elbiblio/core/di/app_providers.dart';
import 'package:elbiblio/core/errors/app_exception.dart';
import 'package:elbiblio/core/network/dio_client.dart';
import 'package:elbiblio/core/services/notifications/notification_service.dart';
import 'package:elbiblio/core/storage/app_settings.dart';
import 'package:elbiblio/features/auth/application/auth_notifier.dart';
import 'package:elbiblio/features/auth/domain/models/auth_models.dart';
import 'package:elbiblio/features/bible/domain/models/verse.dart';
import 'package:elbiblio/features/vision/application/daily_verse_social_notifier.dart';
import 'package:elbiblio/features/vision/application/vision_notifier.dart';
import 'package:elbiblio/features/vision/data/daily_verse_social_repository.dart';
import 'package:elbiblio/features/vision/data/vision_repository.dart';
import 'package:elbiblio/features/vision/domain/daily_verse_social_models.dart';
import 'package:elbiblio/features/vision/domain/vision_models.dart';
import 'package:elbiblio/features/vision/presentation/screens/commit_screen.dart';
import 'package:elbiblio/features/vision/presentation/screens/grow_screen.dart';
import 'package:elbiblio/features/vision/presentation/screens/reflect_screen.dart';
import 'package:elbiblio/features/vision/presentation/screens/tribe_screen.dart';
import 'package:elbiblio/features/vision/presentation/widgets/daily_verse_social_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Vision core screens', () {
    testWidgets(
      'Commit shows commitment choices when there is no active season',
      (tester) async {
        final repository = _FakeVisionRepository(activeCommitment: null);

        await tester.pumpVisionScreen(
          const CommitScreen(),
          repository: repository,
        );

        expect(find.text('Choose one commitment'), findsOneWidget);
        expect(find.text('Reminders'), findsOneWidget);
        expect(find.text(_gratitudePlan.title), findsOneWidget);
        expect(find.text('Review and begin'), findsOneWidget);
        expect(find.text('Check in for today'), findsNothing);
      },
    );

    testWidgets('Commit shows active unchecked season with check-in action', (
      tester,
    ) async {
      final repository = _FakeVisionRepository(
        activeCommitment: _season(checkedInToday: false),
      );

      await tester.pumpVisionScreen(
        const CommitScreen(),
        repository: repository,
      );

      expect(find.text(_gratitudePlan.title), findsWidgets);
      expect(find.text('Mark today'), findsOneWidget);
      expect(find.text('Adjust load'), findsOneWidget);
      expect(find.text('Checked in today.'), findsNothing);
      await tester.scrollUntilVisible(find.text('Add support: 5/day'), 180);
      await tester.pumpAndSettle();
      expect(find.text('Add support: 5/day'), findsOneWidget);
    });

    testWidgets('Reflect gates posting until an unchecked season checks in', (
      tester,
    ) async {
      final repository = _FakeVisionRepository(
        activeCommitment: _season(checkedInToday: false),
      );

      await tester.pumpVisionScreen(
        const ReflectScreen(),
        repository: repository,
      );

      expect(find.text('Reflect'), findsOneWidget);
      expect(find.text('Check-in needed'), findsOneWidget);
      expect(find.text('Check in first'), findsOneWidget);
      expect(find.text('Check in for today'), findsOneWidget);
      expect(find.text('How did today feel?'), findsNothing);
    });

    testWidgets('Reflect leads with the commitment composer before the verse', (
      tester,
    ) async {
      final repository = _FakeVisionRepository(
        activeCommitment: _season(checkedInToday: true),
      );

      await tester.pumpVisionScreen(
        const ReflectScreen(),
        repository: repository,
      );

      expect(find.text('How did today feel?'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Community verse'), 180);
      await tester.pumpAndSettle();

      expect(find.text('Community verse'), findsOneWidget);
      expect(find.textContaining('Let all that you do'), findsOneWidget);
    });

    testWidgets('Daily community verse opens a response sheet', (tester) async {
      final repository = _FakeVisionRepository(
        activeCommitment: _season(checkedInToday: true),
      );

      await tester.pumpVisionScreen(
        const ReflectScreen(),
        repository: repository,
      );

      await tester.scrollUntilVisible(find.text('Respond'), 180);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Respond'));
      await tester.pumpAndSettle();

      expect(find.text('Response'), findsOneWidget);
      expect(find.text('Share response'), findsOneWidget);
      expect(find.text('Today\'s responses'), findsOneWidget);
      expect(find.text('Read'), findsOneWidget);
    });

    testWidgets('Daily community verse sheet opens above shell bottom nav', (
      tester,
    ) async {
      final rootObserver = _PopupRouteObserver();
      final nestedObserver = _PopupRouteObserver();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier()),
            dailyVerseSocialProvider.overrideWith(
              (ref) =>
                  DailyVerseSocialNotifier(_FakeDailyVerseSocialRepository()),
            ),
          ],
          child: MaterialApp(
            navigatorObservers: [rootObserver],
            home: Scaffold(
              body: Navigator(
                observers: [nestedObserver],
                onGenerateRoute: (_) => MaterialPageRoute<void>(
                  builder: (_) => const SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: DailyVerseSocialCard(),
                  ),
                ),
              ),
              bottomNavigationBar: const SizedBox(
                height: 96,
                child: Center(child: Text('Shell nav')),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Respond'));
      await tester.pumpAndSettle();

      expect(rootObserver.popupPushes, 1);
      expect(nestedObserver.popupPushes, 0);
      expect(find.text('Share response'), findsOneWidget);
      expect(find.text('Shell nav'), findsOneWidget);
    });

    testWidgets('Reflect check-in unlocks the composer in the same flow', (
      tester,
    ) async {
      final repository = _FakeVisionRepository(
        activeCommitment: _season(checkedInToday: false),
      );

      await tester.pumpVisionScreen(
        const ReflectScreen(),
        repository: repository,
      );
      await tester.scrollUntilVisible(find.text('Check in for today'), 180);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Check in for today'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('How did today feel?'), 180);
      await tester.pumpAndSettle();

      expect(repository.checkInCount, 1);
      expect(find.text('How did today feel?'), findsOneWidget);
    });

    testWidgets(
      'Reflect lets a checked-in season post when no reflection exists',
      (tester) async {
        final repository = _FakeVisionRepository(
          activeCommitment: _season(checkedInToday: true),
          feedResult: const CommitmentFeedResult(
            reflections: [],
            postedToday: false,
          ),
        );

        await tester.pumpVisionScreen(
          const ReflectScreen(),
          repository: repository,
        );
        expect(find.text('Checked in today'), findsOneWidget);
        expect(find.text('Post open'), findsOneWidget);

        await tester.scrollUntilVisible(find.text('How did today feel?'), 180);
        await tester.pumpAndSettle();
        expect(find.text('How did today feel?'), findsOneWidget);
        expect(find.text('Easy'), findsOneWidget);
        expect(find.text('Mixed'), findsOneWidget);
        expect(find.text('Hard'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text('Be the first steady note for this commitment.'),
          180,
        );
        await tester.pumpAndSettle();

        expect(find.text('Post reflection'), findsNothing);
        expect(
          find.text('Be the first steady note for this commitment.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('Reflect posts a trimmed reflection as the visible alias', (
      tester,
    ) async {
      final repository = _FakeVisionRepository(
        activeCommitment: _season(checkedInToday: true),
        feedResult: const CommitmentFeedResult(
          reflections: [],
          postedToday: false,
        ),
      );

      await tester.pumpVisionScreen(
        const ReflectScreen(),
        repository: repository,
      );
      await tester.scrollUntilVisible(find.text('Hard'), 180);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hard'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('vision_reflection_text_field')),
        '  I chose patience before replying.  ',
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -80));
      await tester.pumpAndSettle();
      final postButton = find
          .byKey(const Key('vision_reflection_post_button'))
          .hitTestable();
      expect(postButton, findsOneWidget);

      await tester.tap(postButton);
      await tester.pumpAndSettle();

      expect(
        repository.postedReflectionContent,
        'I chose patience before replying.',
      );
      expect(repository.postedReflectionAlias, 'Quiet Walker');
      await tester.drag(find.byType(ListView), const Offset(0, 500));
      await tester.pumpAndSettle();
      expect(find.text('Reflection shared'), findsOneWidget);
      expect(find.text('I chose patience before replying.'), findsOneWidget);
    });

    testWidgets('Reflect treats duplicate daily post as already complete', (
      tester,
    ) async {
      final repository = _FakeVisionRepository(
        activeCommitment: _season(checkedInToday: true),
        postReflectionError: ApiRequestException(
          statusCode: 409,
          message: 'Reflection already posted today.',
        ),
      );

      await tester.pumpVisionScreen(
        const ReflectScreen(),
        repository: repository,
      );
      await tester.scrollUntilVisible(find.text('Easy'), 180);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Easy'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('vision_reflection_text_field')),
        'It felt possible.',
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -80));
      await tester.pumpAndSettle();
      final postButton = find
          .byKey(const Key('vision_reflection_post_button'))
          .hitTestable();
      expect(postButton, findsOneWidget);
      await tester.tap(postButton);
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, 500));
      await tester.pumpAndSettle();
      expect(find.text('Reflection shared'), findsOneWidget);
    });

    testWidgets('Reflect shows posted state and existing reflection', (
      tester,
    ) async {
      final repository = _FakeVisionRepository(
        activeCommitment: _season(checkedInToday: true),
        feedResult: CommitmentFeedResult(
          reflections: [_reflection],
          postedToday: true,
        ),
      );

      await tester.pumpVisionScreen(
        const ReflectScreen(),
        repository: repository,
      );
      expect(find.text('Shared today'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Reflection shared'), 180);
      await tester.pumpAndSettle();
      expect(find.text('Reflection shared'), findsOneWidget);
      expect(find.text('Your reflection for today is posted.'), findsOneWidget);

      await tester.scrollUntilVisible(find.text(_reflection.alias), 180);
      await tester.pumpAndSettle();

      expect(find.text(_reflection.alias), findsOneWidget);
      expect(find.text(_reflection.content), findsOneWidget);
      expect(find.text('Post reflection'), findsNothing);
    });

    testWidgets('Tribe shows empty hangout state for a joined tribe', (
      tester,
    ) async {
      final repository = _FakeVisionRepository(
        primaryTribe: _tribeMembership,
        hangouts: const [],
      );

      await tester.pumpVisionScreen(
        const TribeScreen(),
        repository: repository,
      );

      expect(find.text('Watchman'), findsWidgets);

      await tester.scrollUntilVisible(find.text('Tribe hangouts'), 180);
      await tester.pumpAndSettle();

      expect(find.text('Tribe hangouts'), findsOneWidget);
      expect(
        find.text('No live rooms yet. Start a short prayer check-in.'),
        findsOneWidget,
      );
      expect(find.text('Start tribe hangout'), findsOneWidget);
    });

    testWidgets('Tribe hides the current tribe from other recommendations', (
      tester,
    ) async {
      final repository = _FakeVisionRepository(primaryTribe: _tribeMembership);

      await tester.pumpVisionScreen(
        const TribeScreen(),
        repository: repository,
      );

      expect(find.text('Primary tribe'), findsOneWidget);
      expect(find.text('Other tribes'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Joined'), findsNothing);
    });

    testWidgets('Tribe leads with recommendations before joining', (
      tester,
    ) async {
      final repository = _FakeVisionRepository(
        activeCommitment: null,
        primaryTribe: null,
      );

      await tester.pumpVisionScreen(
        const TribeScreen(),
        repository: repository,
      );

      expect(find.text('Find your tribe'), findsOneWidget);
      expect(find.text('Recommended tribes'), findsOneWidget);
      expect(find.text('Watchman'), findsOneWidget);
      expect(find.text('Join tribe'), findsOneWidget);
      expect(find.text('After joining'), findsOneWidget);
      expect(find.text('Tribe hangouts'), findsNothing);
    });

    testWidgets('Tribe keeps joined workflow focused on rituals and invite', (
      tester,
    ) async {
      final repository = _FakeVisionRepository(primaryTribe: _tribeMembership);

      await tester.pumpVisionScreen(
        const TribeScreen(),
        repository: repository,
      );

      expect(find.text('Watchman'), findsWidgets);
      expect(find.text('Play together'), findsNothing);
      await tester.scrollUntilVisible(find.text('Actions'), 180);
      await tester.pumpAndSettle();
      expect(find.text('Invite'), findsOneWidget);
      expect(find.text('Hangout'), findsOneWidget);
      expect(find.text('Weekly reflection'), findsOneWidget);
    });

    testWidgets('Tribe joins a recommendation and reveals joined workflow', (
      tester,
    ) async {
      final repository = _FakeVisionRepository(
        activeCommitment: null,
        primaryTribe: null,
      );

      await tester.pumpVisionScreen(
        const TribeScreen(),
        repository: repository,
      );
      await tester.tap(find.text('Join tribe'));
      await tester.pumpAndSettle();

      expect(repository.joinedTribeIds, [1]);
      expect(find.text('You joined Watchman'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Primary tribe'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Tribe hangouts'), 180);
      await tester.pumpAndSettle();

      expect(find.text('Tribe hangouts'), findsOneWidget);
    });

    testWidgets('Tribe visibility initials save normalized initials', (
      tester,
    ) async {
      final repository = _FakeVisionRepository(primaryTribe: _tribeMembership);

      await tester.pumpVisionScreen(
        const TribeScreen(),
        repository: repository,
      );
      await tester.tap(find.byTooltip('How I appear'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Initials'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repository.savedVisibilityMode, VisibilityMode.initials);
      expect(repository.savedVisibilityAlias, 'QW');
      expect(find.text('Visibility updated.'), findsOneWidget);
    });

    testWidgets('Tribe shows a live hangout card', (tester) async {
      final repository = _FakeVisionRepository(
        primaryTribe: _tribeMembership,
        hangouts: [_liveHangout(canJoin: true)],
      );

      await tester.pumpVisionScreen(
        const TribeScreen(),
        repository: repository,
      );
      await tester.scrollUntilVisible(find.text('Tribe check-in room'), 180);
      await tester.pumpAndSettle();

      expect(find.text('Tribe check-in room'), findsOneWidget);
      expect(find.text('3/8 joined'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Join'))
            .enabled,
        isTrue,
      );
    });

    testWidgets(
      'Tribe enables rejoin for joined hangout even when canJoin is false',
      (tester) async {
        final repository = _FakeVisionRepository(
          primaryTribe: _tribeMembership,
          hangouts: [
            _liveHangout(
              canJoin: false,
              joinedByMe: true,
              participantCount: 8,
              maxParticipants: 8,
            ),
          ],
        );

        await tester.pumpVisionScreen(
          const TribeScreen(),
          repository: repository,
        );
        await tester.scrollUntilVisible(
          find.widgetWithText(FilledButton, 'Rejoin'),
          180,
        );
        await tester.pumpAndSettle();

        expect(
          tester
              .widget<FilledButton>(find.widgetWithText(FilledButton, 'Rejoin'))
              .enabled,
          isTrue,
        );

        await tester.tap(find.widgetWithText(FilledButton, 'Rejoin'));
        await tester.pumpAndSettle();

        expect(
          find.text('We could not join this tribe hangout.'),
          findsOneWidget,
        );
        expect(find.text('This tribe hangout is full.'), findsNothing);
      },
    );

    testWidgets('Tribe surfaces LiveKit absence after joining a hangout', (
      tester,
    ) async {
      final repository = _FakeVisionRepository(
        primaryTribe: _tribeMembership,
        hangouts: [_liveHangout(canJoin: true)],
        joinedHangout: _liveHangout(canJoin: false),
      );

      await tester.pumpVisionScreen(
        const TribeScreen(),
        repository: repository,
      );
      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Join'),
        180,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Join'));
      await tester.pumpAndSettle();

      expect(
        find.text('We could not join this tribe hangout.'),
        findsOneWidget,
      );
    });

    testWidgets('Tribe surfaces repository errors when joining a hangout', (
      tester,
    ) async {
      final repository = _FakeVisionRepository(
        primaryTribe: _tribeMembership,
        hangouts: [_liveHangout(canJoin: true)],
        joinHangoutError: StateError('Live room unavailable'),
      );

      await tester.pumpVisionScreen(
        const TribeScreen(),
        repository: repository,
      );
      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Join'),
        180,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Join'));
      await tester.pumpAndSettle();

      expect(
        find.text('We could not join this tribe hangout.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Tribe creates a hangout and surfaces missing audio credentials',
      (tester) async {
        final repository = _FakeVisionRepository(
          primaryTribe: _tribeMembership,
        );

        await tester.pumpVisionScreen(
          const TribeScreen(),
          repository: repository,
        );
        await tester.scrollUntilVisible(find.text('Tribe hangouts'), 180);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Start tribe hangout'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).last, '');
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<FilledButton>(find.widgetWithText(FilledButton, 'Start'))
              .enabled,
          isFalse,
        );

        await tester.enterText(find.byType(TextField).last, 'Prayer room');
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<FilledButton>(find.widgetWithText(FilledButton, 'Start'))
              .enabled,
          isTrue,
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Start'));
        await tester.pumpAndSettle();

        expect(repository.createdHangoutTitle, 'Prayer room');
        expect(repository.createdHangoutScopeType, 'tribe');
        expect(repository.createdHangoutScopeId, _watchmanTribe.id);
        expect(repository.createdHangoutMaxParticipants, 8);
        expect(
          find.text(
            'Tribe hangout started, but audio credentials were unavailable.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('Grow saves a daily question answer through the runtime flow', (
      tester,
    ) async {
      final repository = _FakeVisionRepository(dailyQuestion: _dailyQuestion);

      await tester.pumpVisionScreen(const GrowScreen(), repository: repository);
      await tester.scrollUntilVisible(find.text(_dailyQuestion.question), 180);
      await tester.pumpAndSettle();
      await tester.tap(find.text('I can pause before replying.'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save choice'));
      await tester.pumpAndSettle();

      expect(repository.savedQuestionId, _dailyQuestion.id);
      expect(repository.savedQuestionAnswer, 'I can pause before replying.');
      expect(find.text('Answer saved'), findsOneWidget);
    });

    test(
      'VisionNotifier refreshes commitments for the selected tribe',
      () async {
        final repository = _FakeVisionRepository(activeCommitment: null);
        final notifier = VisionNotifier(repository, NotificationService());

        await notifier.loadCommitmentsForTribe(7);

        expect(repository.requestedCommitmentTribeIds, [7]);
        expect(notifier.state.recommendedCommitments, [_gratitudePlan]);

        notifier.dispose();
      },
    );
  });
}

extension on WidgetTester {
  Future<void> pumpVisionScreen(
    Widget child, {
    required _FakeVisionRepository repository,
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: [
          visionProvider.overrideWith(
            (ref) => VisionNotifier(
              repository,
              ref.watch(notificationServiceProvider),
            ),
          ),
          authProvider.overrideWith((ref) => _FakeAuthNotifier()),
          dailyVerseSocialProvider.overrideWith(
            (ref) =>
                DailyVerseSocialNotifier(_FakeDailyVerseSocialRepository()),
          ),
          settingsProvider.overrideWith(
            (ref) => _FakeSettingsNotifier(AppSettings.defaults()),
          ),
        ],
        child: MaterialApp(home: child),
      ),
    );
    await pump();
    await pumpAndSettle();
  }
}

class _FakeVisionRepository implements VisionRepository {
  _FakeVisionRepository({
    CommitmentSeason? activeCommitment = _defaultSeason,
    TribeMembership? primaryTribe,
    CommitmentFeedResult? feedResult,
    List<CommitmentHangout> hangouts = const [],
    CommitmentHangout? joinedHangout,
    Object? joinHangoutError,
    Object? postReflectionError,
    DailyGrowthQuestion? dailyQuestion,
    List<TribeGameLeaderboardEntry> gameLeaderboard = const [],
  }) : _activeCommitment = activeCommitment,
       _primaryTribe = primaryTribe,
       _feedResult =
           feedResult ??
           const CommitmentFeedResult(reflections: [], postedToday: false),
       _hangouts = hangouts,
       _joinedHangout = joinedHangout,
       _joinHangoutError = joinHangoutError,
       _postReflectionError = postReflectionError,
       _dailyQuestion = dailyQuestion,
       _gameLeaderboard = gameLeaderboard;

  final CommitmentSeason? _activeCommitment;
  TribeMembership? _primaryTribe;
  final CommitmentFeedResult _feedResult;
  final List<CommitmentHangout> _hangouts;
  final CommitmentHangout? _joinedHangout;
  final Object? _joinHangoutError;
  final Object? _postReflectionError;
  final DailyGrowthQuestion? _dailyQuestion;
  final List<TribeGameLeaderboardEntry> _gameLeaderboard;
  final List<int> joinedTribeIds = [];
  VisibilityMode? savedVisibilityMode;
  String? savedVisibilityAlias;
  int? savedQuestionId;
  String? savedQuestionAnswer;
  String? createdHangoutTitle;
  String? createdHangoutScopeType;
  int? createdHangoutScopeId;
  int? createdHangoutMaxParticipants;
  final List<int?> requestedCommitmentTribeIds = [];
  int checkInCount = 0;
  String? postedReflectionContent;
  String? postedReflectionAlias;

  @override
  Future<VisionBootstrap> bootstrap() async {
    return VisionBootstrap(
      visibilityMode: VisibilityMode.nickname,
      visibilityAlias: 'Quiet Walker',
      primaryTribe: _primaryTribe,
      activeCommitment: _activeCommitment,
      dailyQuestion: _dailyQuestion,
    );
  }

  @override
  Future<List<TribeIdentity>> recommendedTribes({
    List<String> archetypes = const [],
  }) async {
    return const [_watchmanTribe];
  }

  @override
  Future<List<CommitmentPlan>> recommendedCommitments({int? tribeId}) async {
    requestedCommitmentTribeIds.add(tribeId);
    return const [_gratitudePlan];
  }

  @override
  Future<CommitmentFeedResult> feed(int commitmentId) async => _feedResult;

  @override
  Future<TribeMembership> joinTribe({
    required int tribeId,
    required VisibilityMode visibilityMode,
    String? displayAlias,
  }) async {
    joinedTribeIds.add(tribeId);
    final tribe = tribeId == _watchmanTribe.id
        ? _watchmanTribe
        : TribeIdentity(
            id: tribeId,
            name: 'Joined tribe',
            slug: 'joined-tribe',
            description: 'A joined tribe.',
            iconKey: 'circle',
          );
    _primaryTribe = TribeMembership(
      tribe: tribe,
      visibilityMode: visibilityMode,
      displayAlias: displayAlias ?? 'Anonymous',
      isPrimary: true,
    );
    return _primaryTribe!;
  }

  @override
  Future<void> updateVisibility({
    required VisibilityMode visibilityMode,
    String? alias,
  }) async {
    savedVisibilityMode = visibilityMode;
    savedVisibilityAlias = alias;
  }

  @override
  Future<TribePulse> tribePulse(int tribeId) async {
    return const TribePulse(
      returnedCount: 2,
      activeMembersCount: 9,
      reflectionCount: 1,
      supportCount: 4,
      items: [],
    );
  }

  @override
  Future<List<WeeklyRitualReflection>> weeklyRitual(int tribeId) async {
    return const [];
  }

  @override
  Future<List<TribeGameLeaderboardEntry>> gameLeaderboard({
    int limit = 5,
  }) async {
    return _gameLeaderboard.take(limit).toList(growable: false);
  }

  @override
  Future<List<CommitmentHangout>> visibleHangouts() async => _hangouts;

  @override
  Future<List<VisionNotificationItem>> notifications() async => const [];

  @override
  Future<CommitmentSeason> checkIn({
    required int commitmentId,
    List<String> completedItemIds = const [],
    String? note,
  }) async {
    checkInCount += 1;
    return _season(checkedInToday: true);
  }

  @override
  Future<CommitmentReflection> postReflection({
    required int commitmentId,
    required String content,
    required String alias,
  }) async {
    final error = _postReflectionError;
    if (error != null) throw error;
    postedReflectionContent = content.trim();
    postedReflectionAlias = alias;
    return CommitmentReflection(
      id: 77,
      alias: alias,
      content: content.trim(),
      createdAt: DateTime(2026, 5, 13, 9),
      authorTribeName: _watchmanTribe.name,
    );
  }

  @override
  Future<CommitmentHangout> joinHangout(int hangoutId) async {
    final error = _joinHangoutError;
    if (error != null) throw error;
    return _joinedHangout ?? _liveHangout(canJoin: false);
  }

  @override
  Future<CommitmentHangout> leaveHangout(int hangoutId) async {
    return _liveHangout(canJoin: true);
  }

  @override
  Future<void> reactToReflection({
    required int reflectionId,
    required String reactionType,
  }) async {}

  @override
  Future<CommitmentHangout> createHangout({
    required String title,
    required String scopeType,
    int? scopeId,
    required int maxParticipants,
    bool startNow = true,
  }) async {
    createdHangoutTitle = title.trim();
    createdHangoutScopeType = scopeType;
    createdHangoutScopeId = scopeId;
    createdHangoutMaxParticipants = maxParticipants;
    return CommitmentHangout(
      id: 123,
      title: title.trim(),
      status: 'live',
      participantCount: 1,
      maxParticipants: maxParticipants,
      canJoin: false,
      scopeType: scopeType,
      scopeId: scopeId,
      joinedByMe: true,
      liveKit: null,
    );
  }

  @override
  Future<void> answerDailyQuestion({
    required int questionId,
    required String answer,
  }) async {
    savedQuestionId = questionId;
    savedQuestionAnswer = answer.trim();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _FakeAuthNotifier()
    : super(
        const AuthState(
          isInitialized: true,
          isAuthenticated: true,
          user: _authUser,
          token: 'test-token',
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDailyVerseSocialRepository extends DailyVerseSocialRepository {
  _FakeDailyVerseSocialRepository()
    : super(_NoopDioClient(), Logger(level: Level.off));

  @override
  Future<Verse?> todayVerse() async => _dailyVerse;

  @override
  Future<List<DailyVerseReflection>> reflectionsForVerse(
    int verseId, {
    int perPage = 20,
  }) async {
    return const [];
  }
}

class _NoopDioClient extends DioClient {
  _NoopDioClient() : super(Logger(level: Level.off));
}

class _PopupRouteObserver extends NavigatorObserver {
  int popupPushes = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute) {
      popupPushes += 1;
    }
    super.didPush(route, previousRoute);
  }
}

class _FakeSettingsNotifier extends StateNotifier<AppSettings>
    implements SettingsNotifier {
  _FakeSettingsNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _watchmanTribe = TribeIdentity(
  id: 1,
  name: 'Watchman Circle',
  slug: 'watchman-circle',
  description: 'For people rebuilding attention, vigilance, and prayer.',
  iconKey: 'compass',
);

const _tribeMembership = TribeMembership(
  tribe: _watchmanTribe,
  visibilityMode: VisibilityMode.nickname,
  displayAlias: 'Quiet Walker',
  isPrimary: true,
);

const _gratitudePlan = CommitmentPlan(
  id: 7,
  title: '30 Days of Gratitude',
  description: 'Practice daily gratitude in small, honest moments.',
  durationDays: 30,
  category: 'gratitude',
  dailyAction: 'Name one concrete gift from today and thank God for it.',
  nudgeMin: 3,
  nudgeMax: 10,
);

const _defaultSeason = CommitmentSeason(
  plan: _gratitudePlan,
  currentDay: 4,
  completedDaysCount: 3,
  nudgeCountPerDay: 3,
);

final _reflection = CommitmentReflection(
  id: 12,
  alias: 'Quiet Walker',
  content: 'I noticed grace before reaching for distraction.',
  createdAt: DateTime(2026, 5, 9, 12),
  reactionCount: 2,
  authorTribeName: 'Watchman Circle',
  authorCompletedChallengesCount: 1,
  authorCurrentStreakCount: 3,
);

const _dailyQuestion = DailyGrowthQuestion(
  id: 51,
  question: 'Where did grace ask you to slow down today?',
  conciseExplanation: 'A plain prompt for noticing one faithful moment.',
  spiritualInsight: 'Patience is often practiced before it is felt.',
  practicalPerspective: 'Name the moment, then choose one next response.',
  realWorldContext: 'Daily reflection is easier when it starts small.',
  dailyLivingGuide: 'Pause before the next reply that feels urgent.',
  answerOptions: [
    'I can pause before replying.',
    'I can pray before deciding.',
    'I can ask for help.',
  ],
);

const _authUser = User(
  id: '42',
  email: 'quiet@example.com',
  firstName: 'Quiet',
  lastName: 'Walker',
);

final _dailyVerse = Verse(
  id: 15,
  text: 'Let all that you do be done in love.',
  reference: '1 Corinthians 16:14',
  referenceDisplay: '1 Corinthians 16:14',
  translation: 'WEB',
  book: '1 Corinthians',
  chapter: 16,
  verseNumber: 14,
  createdAt: DateTime(2026, 5, 18, 8),
  date: DateTime(2026, 5, 18),
);

CommitmentSeason _season({required bool checkedInToday}) {
  final now = DateTime.now();
  return CommitmentSeason(
    plan: _gratitudePlan,
    currentDay: 4,
    completedDaysCount: checkedInToday ? 4 : 3,
    nudgeCountPerDay: 3,
    lastCheckInAt: checkedInToday
        ? DateTime(now.year, now.month, now.day, 9)
        : DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(const Duration(days: 1)),
  );
}

CommitmentHangout _liveHangout({
  required bool canJoin,
  bool joinedByMe = false,
  int participantCount = 3,
  int maxParticipants = 8,
}) {
  return CommitmentHangout(
    id: 99,
    title: 'Tribe check-in room',
    status: 'live',
    participantCount: participantCount,
    maxParticipants: maxParticipants,
    canJoin: canJoin,
    scopeType: 'tribe',
    joinedByMe: joinedByMe,
    scopeId: _watchmanTribe.id,
    liveKit: null,
  );
}
