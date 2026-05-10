import 'package:elbiblio/features/vision/domain/vision_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

void main() {
  group('Vision models', () {
    test('visibility modes parse safely', () {
      expect(VisibilityMode.fromValue('nickname'), VisibilityMode.nickname);
      expect(VisibilityMode.fromValue('unexpected'), VisibilityMode.anonymous);
    });

    test('commitment season detects today check-in and progress', () {
      final season = CommitmentSeason.fromJson({
        'challenge': {
          'id': 7,
          'title': '30 Days Gratitude',
          'description': 'Practice gratitude.',
          'duration_days': 30,
          'category': 'gratitude',
          'daily_action': 'Name one gift.',
          'nudge_min': 3,
          'nudge_max': 10,
        },
        'current_day': 4,
        'completed_days_count': 3,
        'nudge_count_per_day': 5,
        'last_check_in_at': DateTime.now().toIso8601String(),
        'check_in_plan_when': 'After lunch',
        'check_in_plan_obstacle': 'Scrolling when tired',
      });

      expect(season.checkedInToday, isTrue);
      expect(season.progress, 0.1);
      expect(season.nudgeCountPerDay, 5);
      expect(season.plan.title, '30 Days Gratitude');
      expect(season.firstCheckInPlanWhen, 'After lunch');
      expect(season.firstCheckInPlanObstacle, 'Scrolling when tired');
    });

    test('journey icon mapping covers known milestone keys', () {
      expect(GrowthJourneyEvent.iconForKey('compass'), LucideIcons.compass);
      expect(GrowthJourneyEvent.iconForKey('users'), LucideIcons.users);
      expect(GrowthJourneyEvent.iconForKey('flag'), LucideIcons.flag);
      expect(
        GrowthJourneyEvent.iconForKey('check-circle'),
        LucideIcons.checkCircle,
      );
      expect(
        GrowthJourneyEvent.iconForKey('message-circle'),
        LucideIcons.messageCircle,
      );
      expect(
        GrowthJourneyEvent.iconForKey('heart-handshake'),
        LucideIcons.heartHandshake,
      );
      expect(GrowthJourneyEvent.iconForKey('send'), LucideIcons.send);
      expect(
        GrowthJourneyEvent.iconForKey('calendar-heart'),
        LucideIcons.calendarHeart,
      );
      expect(GrowthJourneyEvent.iconForKey('radio'), LucideIcons.radio);
      expect(GrowthJourneyEvent.iconForKey('unknown'), LucideIcons.sparkles);
    });

    test('tribe and reflection visible profile display cleanly', () {
      final tribe = TribeIdentity.fromJson({
        'id': 1,
        'name': 'Watchman Circle',
        'slug': 'watchman-circle',
        'description': 'A steady tribe.',
        'icon_key': 'compass',
      });
      final reflection = CommitmentReflection.fromJson({
        'id': 2,
        'author_alias': 'Quiet Walker',
        'content': 'I returned.',
        'created_at': '2026-05-09T12:00:00Z',
        'reaction_counts': {'support': 2},
        'author_profile': {
          'member_since': '2026-03-29',
          'tribe_name': 'Watchman Circle',
          'completed_challenges_count': 1,
          'current_streak_count': 3,
        },
      });

      expect(tribe.displayName, 'Watchman');
      expect(reflection.authorTribeDisplayName, 'Watchman');
      expect(reflection.authorCompletedChallengesCount, 1);
      expect(reflection.authorCurrentStreakCount, 3);
      expect(reflection.reactionCount, 2);
    });

    test('tribe pulse parses aggregate activity safely', () {
      final pulse = TribePulse.fromJson({
        'today': {
          'returned_count': 4,
          'checked_in_count': 5,
          'active_members_count': 18,
          'reflection_count': 7,
          'support_count': 14,
        },
        'items': [
          {
            'type': 'commitment_day_completed',
            'text': '4 people completed Day 30 today.',
            'icon_key': 'flag',
          },
        ],
      });

      expect(pulse.returnedCount, 5);
      expect(pulse.activeMembersCount, 18);
      expect(pulse.items.single.text, '4 people completed Day 30 today.');
    });

    test('tribe hangout and LiveKit absence parse safely', () {
      final hangout = CommitmentHangout.fromJson({
        'id': 9,
        'title': 'Tribe check-in room',
        'status': 'live',
        'participant_count': 8,
        'max_participants': 8,
        'scope_type': 'tribe',
        'scope_id': 3,
        'can_join': false,
        'livekit': null,
      });
      final event = GrowthJourneyEvent.fromJson({
        'type': 'tribe_hangout_joined',
        'title': 'Tribe hangout',
        'subtitle': 'You joined a live gathering with your tribe.',
        'icon_key': 'radio',
      });

      expect(hangout.liveKit, isNull);
      expect(hangout.canJoin, isFalse);
      expect(event.type, GrowthJourneyEventType.tribeHangoutJoined);
      expect(event.icon, LucideIcons.radio);
    });

    test('daily growth question tolerates malformed age-band payloads', () {
      final question = DailyGrowthQuestion.fromJson({
        'id': 'not-a-number',
        'questions': [
          {
            'question': 'Where do you need courage today?',
            'action_steps': [
              {'label': 'Pray', 'minutes': 'later'},
              'bad step',
            ],
          },
          'bad nested question',
        ],
        'scripture_refs': [123, 'Romans 8:1'],
        'position': 'first',
      });

      expect(question.id, 0);
      expect(question.question, 'What is one faithful step today?');
      expect(
        question.packQuestions.single.question,
        'Where do you need courage today?',
      );
      expect(question.packQuestions.single.actionSteps.single.minutes, isNull);
      expect(question.scriptureRefs, ['123', 'Romans 8:1']);
      expect(question.position, isNull);
    });
  });
}
