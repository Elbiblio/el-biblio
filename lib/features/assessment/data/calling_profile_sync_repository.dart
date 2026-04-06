import 'package:elbiblio/core/errors/app_exception.dart';
import 'package:elbiblio/core/network/dio_client.dart';
import 'package:elbiblio/core/repository/base_repository.dart';
import 'package:logger/logger.dart';

import '../../assessment/domain/models/calling_profile.dart';

class CallingProfileSyncRepository extends BaseRepository {
  CallingProfileSyncRepository(this._dioClient, Logger logger) : super(logger);

  final DioClient _dioClient;

  Future<CallingProfile?> fetchLatest() async {
    return guard(() async {
      try {
        final response = await _dioClient.get<Map<String, dynamic>>(
          '/calling-profiles/latest',
        );

        final data = response.data;
        if (data == null) return null;

        return CallingProfile.fromMap(data);
      } catch (e) {
        // If latest doesn't exist, return null
        return null;
      }
    }, operation: 'fetch_latest_calling_profile');
  }

  Future<CallingProfile> createProfile(CallingProfile profile) async {
    return guard(() async {
      final payload = profile.toMap();

      final response = await _dioClient.post<Map<String, dynamic>>(
        '/calling-profiles',
        data: payload,
      );

      final data = response.data;
      if (data == null) {
        throw AppException('Failed to create calling profile', 'create_failed');
      }

      return CallingProfile.fromMap(data);
    }, operation: 'create_calling_profile');
  }

  Future<CallingProfile> updateProfile(CallingProfile profile) async {
    return guard(() async {
      final payload = profile.toMap();

      final response = await _dioClient.put<Map<String, dynamic>>(
        '/calling-profiles/${profile.archetypeId}',
        data: payload,
      );

      final data = response.data;
      if (data == null) {
        throw AppException('Failed to update calling profile', 'update_failed');
      }

      return CallingProfile.fromMap(data);
    }, operation: 'update_calling_profile');
  }
}
