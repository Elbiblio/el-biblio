import 'package:elbiblio/core/services/notifications/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationService daily check-in action', () {
    final service = NotificationService();

    tearDown(() {
      service.setDailyCheckInActionHandler(null);
    });

    test('returns fallback outcome when handler is not set', () async {
      final outcome = await service.executeDailyCheckInAction(payload: 'check_in_reminder');
      expect(outcome, NotificationActionOutcome.fallbackNavigation);
    });

    test('returns success outcome and emits success event', () async {
      service.setDailyCheckInActionHandler(() async {});

      final eventFuture = service.actionEvents.first;
      final outcome = await service.executeDailyCheckInAction(payload: 'check_in_reminder');
      final event = await eventFuture;

      expect(outcome, NotificationActionOutcome.success);
      expect(event.actionId, 'action_0');
      expect(event.outcome, NotificationActionOutcome.success);
    });

    test('returns failed outcome when handler throws', () async {
      service.setDailyCheckInActionHandler(() async {
        throw Exception('fail');
      });

      final outcome = await service.executeDailyCheckInAction(payload: 'check_in_reminder');
      expect(outcome, NotificationActionOutcome.failed);
    });
  });
}
