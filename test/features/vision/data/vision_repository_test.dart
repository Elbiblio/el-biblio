import 'package:dio/dio.dart';
import 'package:elbiblio/core/errors/app_exception.dart';
import 'package:elbiblio/core/network/dio_client.dart';
import 'package:elbiblio/features/vision/data/vision_repository.dart';
import 'package:elbiblio/features/vision/domain/vision_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

void main() {
  test(
    'bootstrap enters read-only error state without fabricated data',
    () async {
      final repository = VisionRepository(
        _OfflineDioClient(),
        Logger(level: Level.off),
      );

      final bootstrap = await repository.bootstrap();

      expect(bootstrap.dataSource, VisionDataSource.error);
      expect(bootstrap.dataSource.isReadOnly, isTrue);
      expect(bootstrap.primaryTribe, isNull);
      expect(bootstrap.activeCommitment, isNull);
      expect(bootstrap.dailyQuestion, isNull);
      expect(bootstrap.journeyEvents, isEmpty);
      expect(bootstrap.errorMessage, contains('offline'));
    },
  );

  test(
    'feed preserves a friendly error instead of silently emptying',
    () async {
      final repository = VisionRepository(
        _OfflineDioClient(),
        Logger(level: Level.off),
      );

      final result = await repository.feed(7);

      expect(result.reflections, isEmpty);
      expect(result.postedToday, isFalse);
      expect(result.errorMessage, contains('offline'));
    },
  );

  test('notifications treats backend empty-inbox response as empty', () async {
    final repository = VisionRepository(
      _EmptyNotificationsDioClient(),
      Logger(level: Level.off),
    );

    final notifications = await repository.notifications();

    expect(notifications, isEmpty);
  });
}

class _OfflineDioClient extends DioClient {
  _OfflineDioClient() : super(Logger(level: Level.off));

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    throw NetworkException('offline');
  }
}

class _EmptyNotificationsDioClient extends DioClient {
  _EmptyNotificationsDioClient() : super(Logger(level: Level.off));

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    throw ApiRequestException(
      statusCode: 400,
      message: 'Notification not found',
      details: const {'success': false, 'message': 'Notification not found'},
    );
  }
}
