import 'package:dio/dio.dart';
import 'package:elbiblio/core/network/dio_client.dart';
import 'package:elbiblio/features/today/data/daily_anchors_sync_repository.dart';
import 'package:elbiblio/features/today/domain/models/daily_anchors.dart';
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
  group('DailyAnchorsSyncRepository', () {
    final anchors = DailyAnchors.empty(DateTime(2026, 3, 10));

    test('syncs successfully on primary endpoint', () async {
      final client = _FakeDioClient([201]);
      final repository = DailyAnchorsSyncRepository(client, Logger());

      final synced = await repository.syncAnchors(anchors);

      expect(synced, isTrue);
      expect(client.requestedPaths, ['/daily-anchors']);
    });

    test('falls back to secondary endpoint when primary returns 404', () async {
      final client = _FakeDioClient([404, 200]);
      final repository = DailyAnchorsSyncRepository(client, Logger());

      final synced = await repository.syncAnchors(anchors);

      expect(synced, isTrue);
      expect(client.requestedPaths, ['/daily-anchors', '/daily_anchors']);
    });
  });
}
