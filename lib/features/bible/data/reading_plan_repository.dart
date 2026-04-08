import 'package:logger/logger.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/repository/base_repository.dart';
import '../domain/models/reading_plan.dart';

class ReadingPlanRepository extends BaseRepository {
  ReadingPlanRepository(this._client, Logger logger) : super(logger);

  final DioClient _client;

  Future<List<ReadingPlan>> getReadingPlans() {
    return guard(() async {
      final response = await _client.get('/reading-plans');
      
      // Handle different response structures
      dynamic data;
      if (response.data is Map<String, dynamic>) {
        data = response.data['data'] ?? response.data['plans'] ?? response.data;
        // Handle paginated response
        if (data is Map<String, dynamic> && data['data'] != null) {
          data = data['data'];
        }
      } else {
        data = response.data;
      }
      
      if (data is! List) {
        logger.w('Expected List but got ${data.runtimeType}: $data');
        return [];
      }
      
      return data.map((json) => ReadingPlan.fromJson(json)).toList();
    }, operation: 'get_reading_plans');
  }

  Future<ReadingPlan> getReadingPlan(int id) {
    return guard(() async {
      final response = await _client.get('/reading-plans/$id');
      final data = response.data['data'] ?? response.data;
      return ReadingPlan.fromJson(data);
    }, operation: 'get_reading_plan');
  }

  Future<List<UserReadingPlan>> getActivePlans() {
    return guard(() async {
      final response = await _client.get('/reading-plans/user/active');
      
      // Handle different response structures
      dynamic data;
      if (response.data is Map<String, dynamic>) {
        data = response.data['data'] ?? response.data['plans'] ?? response.data;
        // Handle paginated response
        if (data is Map<String, dynamic> && data['data'] != null) {
          data = data['data'];
        }
      } else {
        data = response.data;
      }
      
      if (data is! List) {
        logger.w('Expected List but got ${data.runtimeType}: $data');
        return [];
      }
      
      return data.map((json) => UserReadingPlan.fromJson(json)).toList();
    }, operation: 'get_active_reading_plans');
  }

  Future<UserReadingPlan> startPlan(int id) {
    return guard(() async {
      final response = await _client.post('/reading-plans/$id/start');

      if (response.statusCode != null && response.statusCode! >= 400) {
        final message = response.data?['message'] ?? 'Failed to start reading plan';
        throw AppException(message.toString(), 'start_plan_error', '${response.statusCode}');
      }

      final data = response.data['data'] ?? response.data;
      if (data is! Map<String, dynamic>) {
        throw AppException('Invalid response format', 'parse_error', data.toString());
      }
      return UserReadingPlan.fromJson(data);
    }, operation: 'start_reading_plan');
  }
}
