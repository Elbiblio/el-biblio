import 'package:elbiblio/core/network/dio_client.dart';
import 'package:elbiblio/core/repository/base_repository.dart';
import 'package:logger/logger.dart';

import '../domain/models/daily_anchors.dart';

class DailyAnchorsSyncRepository extends BaseRepository {
  DailyAnchorsSyncRepository(this._dioClient, Logger logger) : super(logger);

  final DioClient _dioClient;
  static const String _syncEndpoint = '/daily-anchors';
  static const String _legacySyncEndpoint = '/daily_anchors';

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

    try {
      final response = await _dioClient.post(_syncEndpoint, data: payload);
      final statusCode = response.statusCode ?? 0;
      if (statusCode >= 200 && statusCode < 300) {
        return true;
      }
      if (statusCode == 404) {
        final fallback = await _dioClient.post(
          _legacySyncEndpoint,
          data: payload,
        );
        final fallbackStatusCode = fallback.statusCode ?? 0;
        return fallbackStatusCode >= 200 && fallbackStatusCode < 300;
      }
    } catch (error, stackTrace) {
      logger.w(
        'Daily anchors sync failed for $_syncEndpoint',
        error: error,
        stackTrace: stackTrace,
      );
    }

    return false;
  }
}
