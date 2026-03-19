import 'package:dio/dio.dart';
import 'package:elbiblio/core/errors/app_exception.dart';
import 'package:elbiblio/core/network/dio_client.dart';
import 'package:elbiblio/features/meditation/data/repositories/meditation_session_api_repository.dart';
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
  group('MeditationSessionApiRepository', () {
    test('uses canonical endpoint when available', () async {
      final client = _FakeDioClient([201]);
      final repository = MeditationSessionApiRepository(client, Logger());

      await repository.createSession(durationMinutes: 10);

      expect(client.requestedPaths, ['/meditation-sessions']);
    });

    test('falls back to underscore endpoint on 404', () async {
      final client = _FakeDioClient([404, 201]);
      final repository = MeditationSessionApiRepository(client, Logger());

      await repository.createSession(durationMinutes: 10);

      expect(client.requestedPaths, ['/meditation-sessions', '/meditation_sessions']);
    });

    test('throws when fallback endpoint fails', () async {
      final client = _FakeDioClient([404, 422]);
      final repository = MeditationSessionApiRepository(client, Logger());

      expect(
        () => repository.createSession(durationMinutes: 10),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
