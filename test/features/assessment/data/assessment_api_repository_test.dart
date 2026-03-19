import 'package:dio/dio.dart';
import 'package:elbiblio/core/errors/app_exception.dart';
import 'package:elbiblio/core/network/dio_client.dart';
import 'package:elbiblio/features/assessment/data/assessment_api_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

class _FakeDioClient extends DioClient {
  _FakeDioClient(this._responses) : super(Logger());

  final List<int> _responses;
  final List<String> requestedPaths = <String>[];
  int _index = 0;

  @override
  Future<Response<T>> post<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    requestedPaths.add(path);
    final statusCode = _responses[_index.clamp(0, _responses.length - 1)];
    _index++;
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: statusCode,
      data: <String, dynamic>{} as T,
    );
  }
}

void main() {
  group('AssessmentApiRepository', () {
    final payload = <String, dynamic>{'selected_archetypes': ['Artisan']};

    test('uses canonical endpoint when available', () async {
      final client = _FakeDioClient([200]);
      final repository = AssessmentApiRepository(client, Logger());

      await repository.submitAssessment(payload);

      expect(client.requestedPaths, ['/compass-assessments']);
    });

    test('falls back to underscore endpoint on 404', () async {
      final client = _FakeDioClient([404, 200]);
      final repository = AssessmentApiRepository(client, Logger());

      await repository.submitAssessment(payload);

      expect(client.requestedPaths, ['/compass-assessments', '/compass_assessments']);
    });

    test('throws when fallback endpoint fails', () async {
      final client = _FakeDioClient([404, 500]);
      final repository = AssessmentApiRepository(client, Logger());

      expect(
        () => repository.submitAssessment(payload),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
