import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:elbiblio/core/network/dio_client.dart';
import 'package:elbiblio/features/auth/application/auth_notifier.dart';
import 'package:elbiblio/features/auth/data/auth_repository.dart';
import 'package:elbiblio/features/auth/domain/models/auth_models.dart';

void main() {
  group('AuthState', () {
    test('copyWith preserves restored session flag by default', () {
      const state = AuthState(isAuthenticated: true, isRestoredSession: true);

      final next = state.copyWith(isLoading: true);

      expect(next.isRestoredSession, isTrue);
    });

    test('copyWith can reset restored session flag for fresh signups', () {
      const state = AuthState(isAuthenticated: true, isRestoredSession: true);

      final next = state.copyWith(isRestoredSession: false);

      expect(next.isRestoredSession, isFalse);
    });

    test(
      'initialize marks persisted credentials as a restored session',
      () async {
        SharedPreferences.setMockInitialValues({
          'auth_token': 'stored-token',
          'user_data':
              '{"id":7,"email":"saved@example.com","first_name":"Saved"}',
        });
        final logger = Logger();
        final dioClient = DioClient(logger);
        final notifier = AuthNotifier(
          AuthRepository(dioClient, logger),
          dioClient,
        );

        await notifier.initialize();

        expect(notifier.state.isAuthenticated, isTrue);
        expect(notifier.state.isRestoredSession, isTrue);
        expect(notifier.state.token, 'stored-token');
        expect(notifier.state.user?.email, 'saved@example.com');
        expect(dioClient.currentAuthToken, 'stored-token');
      },
    );
  });
}
