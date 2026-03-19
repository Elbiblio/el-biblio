import 'package:elbiblio/core/network/dio_client.dart';
import 'package:elbiblio/core/repository/base_repository.dart';
import 'package:logger/logger.dart';

import '../domain/models/daily_anchors.dart';

class DailyAnchorsSyncRepository extends BaseRepository {
  DailyAnchorsSyncRepository(this._dioClient, Logger logger) : super(logger);

  final DioClient _dioClient;

  static const List<String> _syncEndpoints = <String>[
    '/daily-anchors',
    '/daily_anchors',
    '/daily-check-ins',
    '/daily_check_ins',
  ];

  Future<bool> syncAnchors(DailyAnchors anchors) async {
    final payload = <String, dynamic>{
      'date': anchors.date.toIso8601String(),
      'is_completed': anchors.isCompleted,
      'integrity_points': anchors.integrityPoints,
      'core_virtue': <String, dynamic>{
        'type': anchors.coreVirtue.type.name,
        'is_completed': anchors.coreVirtue.isCompleted,
      },
      'habit': <String, dynamic>{
        'title': anchors.habit.title,
        'is_completed': anchors.habit.isCompleted,
        'is_locked_in': anchors.habit.isLockedIn,
      },
      'energy_action': <String, dynamic>{
        'title': anchors.energyAction.title,
        'is_completed': anchors.energyAction.isCompleted,
      },
    };

    for (final endpoint in _syncEndpoints) {
      try {
        final response = await _dioClient.post(endpoint, data: payload);
        final statusCode = response.statusCode ?? 0;
        if (statusCode >= 200 && statusCode < 300) {
          return true;
        }

        if (statusCode == 404) {
          continue;
        }
      } catch (error, stackTrace) {
        logger.w('Daily anchors sync failed for $endpoint', error: error, stackTrace: stackTrace);
      }
    }

    return false;
  }
}
