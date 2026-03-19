import 'package:logger/logger.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/repository/base_repository.dart';

class AssessmentApiRepository extends BaseRepository {
  AssessmentApiRepository(this._client, Logger logger) : super(logger);

  final DioClient _client;

  Future<void> submitAssessment(Map<String, dynamic> payload) {
    return guard(() async {
      final endpoints = <String>[
        '/compass-assessments',
        '/compass_assessments',
      ];

      for (var i = 0; i < endpoints.length; i++) {
        final response = await _client.post<Map<String, dynamic>>(
          endpoints[i],
          data: payload,
        );

        final statusCode = response.statusCode ?? 500;
        if (statusCode < 400) {
          return;
        }

        final isLastEndpoint = i == endpoints.length - 1;
        if (isLastEndpoint || statusCode != 404) {
          throw NetworkException(
            'Unable to sync assessment right now.',
            response.data,
          );
        }
      }
    }, operation: 'submit_assessment');
  }
}
