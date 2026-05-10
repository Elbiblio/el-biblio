import 'package:elbiblio/core/application/settings_notifier.dart';
import 'package:elbiblio/core/di/app_providers.dart';
import 'package:elbiblio/core/storage/app_settings.dart';
import 'package:elbiblio/features/vision/application/vision_notifier.dart';
import 'package:elbiblio/features/vision/data/vision_repository.dart';
import 'package:elbiblio/features/vision/domain/vision_models.dart';
import 'package:elbiblio/features/vision/presentation/screens/commit_screen.dart';
import 'package:elbiblio/features/vision/presentation/screens/reflect_screen.dart';
import 'package:elbiblio/features/vision/presentation/screens/tribe_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
        expect(
          find.text('Nudges are accountability, not pressure'),
          findsOneWidget,
        );
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

      expect(find.text('Keep the commitment'), findsOneWidget);
      expect(find.text(_gratitudePlan.title), findsOneWidget);
      expect(find.text('Check in for today'), findsOneWidget);
      expect(find.text('Checked in today.'), findsNothing);
      expect(find.text('Increase to 5 nudges'), findsOneWidget);
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

      expect(find.text('Reflect together'), findsOneWidget);
      expect(find.text('Check-in open'), findsOneWidget);
      expect(find.text('Check in today first'), findsOneWidget);
      expect(find.text('Check in for today'), findsOneWidget);
      expect(find.text('Share one honest reflection'), findsNothing);
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
        expect(find.text('One reflection'), findsOneWidget);
        expect(find.text('Share one honest reflection'), findsOneWidget);
        expect(find.text('Post reflection'), findsOneWidget);
        expect(
          find.text(
            'No reflections yet. The feed grows one honest post at a time.',
          ),
          findsOneWidget,
        );
      },
    );

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
      expect(find.text('Reflection shared'), findsOneWidget);
      expect(find.text('Your reflection for today is posted.'), findsOneWidget);
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
      expect(find.text('Tribe hangouts'), findsOneWidget);
      expect(
        find.text(
          'No live gatherings in Watchman yet. Start one when your tribe needs voice, prayer, or encouragement.',
        ),
        findsOneWidget,
      );
      expect(find.text('Start tribe hangout'), findsOneWidget);
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

      expect(find.text('Tribe check-in room'), findsOneWidget);
      expect(find.text('3/8 joined'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Join'))
            .enabled,
        isTrue,
      );
    });

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
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Join'));
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
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Join'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Join'));
      await tester.pumpAndSettle();

      expect(
        find.text('We could not join this tribe hangout.'),
        findsOneWidget,
      );
    });
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
  }) : _activeCommitment = activeCommitment,
       _primaryTribe = primaryTribe,
       _feedResult =
           feedResult ??
           const CommitmentFeedResult(reflections: [], postedToday: false),
       _hangouts = hangouts,
       _joinedHangout = joinedHangout,
       _joinHangoutError = joinHangoutError;

  final CommitmentSeason? _activeCommitment;
  final TribeMembership? _primaryTribe;
  final CommitmentFeedResult _feedResult;
  final List<CommitmentHangout> _hangouts;
  final CommitmentHangout? _joinedHangout;
  final Object? _joinHangoutError;

  @override
  Future<VisionBootstrap> bootstrap() async {
    return VisionBootstrap(
      visibilityMode: VisibilityMode.nickname,
      visibilityAlias: 'Quiet Walker',
      primaryTribe: _primaryTribe,
      activeCommitment: _activeCommitment,
      dailyQuestion: null,
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
    return const [_gratitudePlan];
  }

  @override
  Future<CommitmentFeedResult> feed(int commitmentId) async => _feedResult;

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
  Future<List<CommitmentHangout>> visibleHangouts() async => _hangouts;

  @override
  Future<List<VisionNotificationItem>> notifications() async => const [];

  @override
  Future<CommitmentSeason> checkIn({
    required int commitmentId,
    String? note,
  }) async {
    return _season(checkedInToday: true);
  }

  @override
  Future<CommitmentHangout> joinHangout(int hangoutId) async {
    final error = _joinHangoutError;
    if (error != null) throw error;
    return _joinedHangout ?? _liveHangout(canJoin: false);
  }

  @override
  Future<void> reactToReflection({
    required int reflectionId,
    required String reactionType,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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

CommitmentHangout _liveHangout({required bool canJoin}) {
  return CommitmentHangout(
    id: 99,
    title: 'Tribe check-in room',
    status: 'live',
    participantCount: 3,
    maxParticipants: 8,
    canJoin: canJoin,
    scopeType: 'tribe',
    scopeId: _watchmanTribe.id,
    liveKit: null,
  );
}
