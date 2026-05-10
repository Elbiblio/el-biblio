import 'package:elbiblio/features/assessment/application/pending_compass_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

void main() {
  group('PendingCompassSyncService', () {
    test('skips sync when unauthenticated or payload is empty', () async {
      final service = PendingCompassSyncService(_silentLogger());
      var submitted = false;

      final result = await service.trySync(
        isAuthenticated: false,
        payload: {
          'selected_archetypes': ['Watchman'],
        },
        submit: (_) async => submitted = true,
        clear: () async {},
      );

      expect(result, isFalse);
      expect(submitted, isFalse);

      final emptyResult = await service.trySync(
        isAuthenticated: true,
        payload: const {},
        submit: (_) async => submitted = true,
        clear: () async {},
      );

      expect(emptyResult, isFalse);
      expect(submitted, isFalse);
    });

    test('submits and clears queued payload on success', () async {
      final service = PendingCompassSyncService(_silentLogger());
      final submitted = <Map<String, dynamic>>[];
      var cleared = false;

      final result = await service.trySync(
        isAuthenticated: true,
        payload: {
          'assessment_version': 'full_spiritual_compass_v1',
          'selected_archetypes': ['Watchman'],
        },
        submit: (payload) async => submitted.add(payload),
        clear: () async => cleared = true,
      );

      expect(result, isTrue);
      expect(submitted.single['selected_archetypes'], ['Watchman']);
      expect(cleared, isTrue);
    });

    test('keeps queued payload when submit fails', () async {
      final service = PendingCompassSyncService(_silentLogger());
      var cleared = false;

      final result = await service.trySync(
        isAuthenticated: true,
        payload: {
          'selected_archetypes': ['Watchman'],
        },
        submit: (_) async => throw StateError('offline'),
        clear: () async => cleared = true,
      );

      expect(result, isFalse);
      expect(cleared, isFalse);
    });
  });
}

Logger _silentLogger() => Logger(level: Level.off);
