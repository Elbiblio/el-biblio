import 'package:logger/logger.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/repository/base_repository.dart';

class AssessmentApiRepository extends BaseRepository {
  AssessmentApiRepository(this._client, Logger logger) : super(logger);

  final DioClient _client;
  static const String _endpoint = '/compass-assessments';

  Future<void> submitAssessment(Map<String, dynamic> payload) {
    return guard(() async {
      final response = await _client.post<Map<String, dynamic>>(
        _endpoint,
        data: payload,
      );

      final statusCode = response.statusCode ?? 500;
      if (statusCode >= 400) {
        throw NetworkException(
          'Unable to sync assessment right now.',
          response.data,
        );
      }
    }, operation: 'submit_assessment');
  }
}
