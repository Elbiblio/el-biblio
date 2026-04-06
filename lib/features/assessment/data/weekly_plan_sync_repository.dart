import 'package:elbiblio/core/errors/app_exception.dart';
import 'package:elbiblio/core/network/dio_client.dart';
import 'package:elbiblio/core/repository/base_repository.dart';
import 'package:logger/logger.dart';

import '../../assessment/domain/models/weekly_plan.dart';

class WeeklyPlanSyncRepository extends BaseRepository {
  WeeklyPlanSyncRepository(this._dioClient, Logger logger) : super(logger);

  final DioClient _dioClient;

  Future<WeeklyPlan?> fetchCurrent() async {
    return guard(() async {
      try {
        final response = await _dioClient.get<Map<String, dynamic>>(
          '/weekly-plans/current',
        );

        final data = response.data;
        if (data == null) return null;

        return WeeklyPlan.fromMap(data);
      } catch (e) {
        // If current doesn't exist, return null
        return null;
      }
    }, operation: 'fetch_current_weekly_plan');
  }

  Future<WeeklyPlan> createPlan(WeeklyPlan plan) async {
    return guard(() async {
      final payload = plan.toMap();

      final response = await _dioClient.post<Map<String, dynamic>>(
        '/weekly-plans',
        data: payload,
      );

      final data = response.data;
      if (data == null) {
        throw AppException('Failed to create weekly plan', 'create_failed');
      }

      return WeeklyPlan.fromMap(data);
    }, operation: 'create_weekly_plan');
  }

  Future<WeeklyPlan> updatePlan(WeeklyPlan plan) async {
    return guard(() async {
      final payload = plan.toMap();

      final response = await _dioClient.put<Map<String, dynamic>>(
        '/weekly-plans/${plan.id}',
        data: payload,
      );

      final data = response.data;
      if (data == null) {
        throw AppException('Failed to update weekly plan', 'update_failed');
      }

      return WeeklyPlan.fromMap(data);
    }, operation: 'update_weekly_plan');
  }
}
