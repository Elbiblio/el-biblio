import 'package:dio/dio.dart';
import 'package:elbiblio/core/network/dio_client.dart';
import 'package:elbiblio/features/assessment/application/assessment_notifier.dart';
import 'package:elbiblio/features/assessment/data/assessment_api_repository.dart';
import 'package:elbiblio/features/assessment/domain/models/archetype.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

class _FakeDioClient extends DioClient {
  _FakeDioClient(this._statusCode) : super(Logger());

  final int _statusCode;
  Map<String, dynamic>? lastPayload;

  @override
  Future<Response<T>> post<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    lastPayload = data as Map<String, dynamic>?;
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: _statusCode,
      data: <String, dynamic>{} as T,
    );
  }
}

void main() {
  group('AssessmentNotifier', () {
    test('buildSubmission maps selected data correctly', () {
      final notifier = AssessmentNotifier();
      final archetype = Archetype.allArchetypes.first;

      notifier.setArchetypes([archetype]);
      notifier.saveArchetypeAssessment(archetype.name, 10, 'some');
      notifier.setPath('development');
      notifier.setTasks(const ['dev_1']);

      final submission = notifier.buildSubmission().toJson();

      expect(submission['selected_archetypes'], [archetype.name]);
      expect((submission['assessment_data'] as Map<String, dynamic>).containsKey(archetype.name), isTrue);
      expect(submission['selected_path'], 'development');
      expect(submission['selected_tasks'], ['dev_1']);
    });

    test('submitCurrentAssessment sets synced state on success', () async {
      final notifier = AssessmentNotifier();
      final archetype = Archetype.allArchetypes.first;
      final fakeClient = _FakeDioClient(200);
      final repository = AssessmentApiRepository(fakeClient, Logger());

      notifier.setArchetypes([archetype]);
      notifier.saveArchetypeAssessment(archetype.name, 10, 'some');

      final ok = await notifier.submitCurrentAssessment(repository);

      expect(ok, isTrue);
      expect(notifier.state.syncError, isNull);
      expect(notifier.state.lastSyncedAt, isNotNull);
      expect(fakeClient.lastPayload, isNotNull);
    });

    test('submitCurrentAssessment sets syncError on failure', () async {
      final notifier = AssessmentNotifier();
      final archetype = Archetype.allArchetypes.first;
      final repository = AssessmentApiRepository(_FakeDioClient(500), Logger());

      notifier.setArchetypes([archetype]);
      notifier.saveArchetypeAssessment(archetype.name, 10, 'some');

      final ok = await notifier.submitCurrentAssessment(repository);

      expect(ok, isFalse);
      expect(notifier.state.syncError, isNotNull);
    });
  });
}
