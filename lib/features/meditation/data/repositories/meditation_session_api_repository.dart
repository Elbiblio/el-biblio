import 'package:logger/logger.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/repository/base_repository.dart';

class MeditationSessionApiRepository extends BaseRepository {
  MeditationSessionApiRepository(this._client, Logger logger) : super(logger);

  final DioClient _client;

  Future<void> createSession({
    required int durationMinutes,
    String? virtue,
    DateTime? startedAt,
    DateTime? endedAt,
  }) {
    return guard(() async {
      final data = {
        'duration_minutes': durationMinutes,
        if (virtue != null && virtue.isNotEmpty) 'virtue': virtue,
        if (startedAt != null) 'started_at': _formatDateTime(startedAt),
        if (endedAt != null) 'ended_at': _formatDateTime(endedAt),
      };

      final endpoints = <String>[
        '/meditation-sessions',
        '/meditation_sessions',
      ];

      for (var i = 0; i < endpoints.length; i++) {
        final response = await _client.post(
          endpoints[i],
          data: data,
        );

        final statusCode = response.statusCode ?? 500;
        if (statusCode < 400) {
          return;
        }

        final isLastEndpoint = i == endpoints.length - 1;
        if (isLastEndpoint || statusCode != 404) {
          throw NetworkException(
            'Unable to sync meditation session.',
            response.data,
          );
        }
      }
    }, operation: 'create_meditation_session');
  }

  String _formatDateTime(DateTime dateTime) {
    final y = dateTime.year.toString().padLeft(4, '0');
    final m = dateTime.month.toString().padLeft(2, '0');
    final d = dateTime.day.toString().padLeft(2, '0');
    final hh = dateTime.hour.toString().padLeft(2, '0');
    final mm = dateTime.minute.toString().padLeft(2, '0');
    final ss = dateTime.second.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm:$ss';
  }
}
