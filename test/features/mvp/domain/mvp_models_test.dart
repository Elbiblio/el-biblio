import 'package:elbiblio/features/mvp/domain/mvp_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

void main() {
  group('MVP models', () {
    test('visibility modes parse safely', () {
      expect(
        MvpVisibilityMode.fromValue('nickname'),
        MvpVisibilityMode.nickname,
      );
      expect(
        MvpVisibilityMode.fromValue('unexpected'),
        MvpVisibilityMode.anonymous,
      );
    });

    test('commitment membership detects today check-in and progress', () {
      final membership = MvpCommitmentMembership.fromJson({
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
      });

      expect(membership.checkedInToday, isTrue);
      expect(membership.progress, 0.1);
      expect(membership.nudgeCountPerDay, 5);
    });

    test('milestone icon mapping is exhaustive for known keys', () {
      expect(MilestoneEvent.iconForKey('compass'), LucideIcons.compass);
      expect(MilestoneEvent.iconForKey('users'), LucideIcons.users);
      expect(MilestoneEvent.iconForKey('flag'), LucideIcons.flag);
      expect(MilestoneEvent.iconForKey('check-circle'), LucideIcons.checkCircle);
      expect(
        MilestoneEvent.iconForKey('message-circle'),
        LucideIcons.messageCircle,
      );
      expect(
        MilestoneEvent.iconForKey('heart-handshake'),
        LucideIcons.heartHandshake,
      );
      expect(MilestoneEvent.iconForKey('send'), LucideIcons.send);
      expect(
        MilestoneEvent.iconForKey('calendar-heart'),
        LucideIcons.calendarHeart,
      );
      expect(MilestoneEvent.iconForKey('unknown'), LucideIcons.sparkles);
    });
  });
}
