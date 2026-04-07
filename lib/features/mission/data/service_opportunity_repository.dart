import 'package:logger/logger.dart';

import '../../../core/network/dio_client.dart';
import '../domain/models/service_opportunity.dart';
import '../domain/models/kingdom_action_models.dart';

/// Repository for fetching service opportunities from the backend API
class ServiceOpportunityRepository {
  final DioClient _dioClient;
  final Logger _logger;

  ServiceOpportunityRepository(this._dioClient, this._logger);

  /// Fetch service opportunities from the backend
  Future<List<ServiceOpportunity>> getServiceOpportunities({
    String? category,
    String? locationType,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;
      if (locationType != null) queryParams['location_type'] = locationType;

      final response = await _dioClient.get(
        '/api/service-opportunities',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data['data'] as List<dynamic>?;
        if (responseData != null) {
          return responseData
              .map((json) => ServiceOpportunity.fromMap(json as Map<String, dynamic>))
              .toList();
        }
      }

      throw Exception('Invalid response format');
    } catch (e) {
      _logger.e('Failed to fetch service opportunities from API: $e');
      rethrow;
    }
  }

  /// Fetch matched service opportunities for the current user
  Future<List<ServiceMatch>> getMatchedOpportunities() async {
    try {
      final response = await _dioClient.post(
        '/api/service-opportunities/generate-matches',
      );

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data['data'] as List<dynamic>?;
        if (responseData != null) {
          return responseData
              .map((json) => _parseServiceMatch(json as Map<String, dynamic>))
              .toList();
        }
      }

      throw Exception('Invalid response format');
    } catch (e) {
      _logger.e('Failed to fetch matched opportunities from API: $e');
      rethrow;
    }
  }

  /// Commit to a service opportunity
  Future<bool> commitToOpportunity(String opportunityId) async {
    try {
      final response = await _dioClient.post(
        '/api/service-opportunities/$opportunityId/commit',
      );

      return response.statusCode == 200;
    } catch (e) {
      _logger.e('Failed to commit to opportunity: $e');
      return false;
    }
  }

  ServiceMatch _parseServiceMatch(Map<String, dynamic> json) {
    return ServiceMatch(
      opportunityId: json['service_opportunity_id'] as String? ?? json['id'] as String,
      title: json['title'] as String,
      matchScore: (json['match_score'] as num?)?.toDouble() ?? 0.0,
      matchReasons: (json['match_reasons'] as List<dynamic>?)?.cast<String>() ?? [],
      category: json['category'] as String,
      burdenAlignment: json['burden_alignment'] as String?,
      tendencyAlignment: json['tendency_alignment'] as String?,
    );
  }
}
