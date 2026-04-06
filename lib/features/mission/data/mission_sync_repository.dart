import 'package:elbiblio/core/errors/app_exception.dart';
import 'package:elbiblio/core/network/dio_client.dart';
import 'package:elbiblio/core/repository/base_repository.dart';
import 'package:logger/logger.dart';

import '../domain/models/mission_action.dart';

class MissionSyncRepository extends BaseRepository {
  MissionSyncRepository(this._dioClient, Logger logger) : super(logger);

  final DioClient _dioClient;

  Future<List<MissionAction>> fetchActions({String? focus}) async {
    return guard(() async {
      final queryParams = <String, dynamic>{};
      if (focus != null) {
        queryParams['focus'] = focus;
      }

      final response = await _dioClient.get<List<dynamic>>(
        '/mission-actions',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final data = response.data;
      if (data == null) return [];

      return data.map((json) {
        final map = json as Map<String, dynamic>;
        return MissionAction.fromMap(map);
      }).toList();
    }, operation: 'fetch_mission_actions');
  }

  Future<MissionAction> createAction(MissionAction action) async {
    return guard(() async {
      final payload = <String, dynamic>{
        'id': action.id,
        'title': action.title,
        'description': action.description,
        'focus': action.focus.name,
        'created_at': action.createdAt.toIso8601String(),
        if (action.completedAt != null) 'completed_at': action.completedAt!.toIso8601String(),
        if (action.personName != null) 'person_name': action.personName,
        if (action.notes != null) 'notes': action.notes,
        'requires_follow_up': action.requiresFollowUp,
        if (action.followUpCompletedAt != null) 'follow_up_completed_at': action.followUpCompletedAt!.toIso8601String(),
        if (action.evangelismContentId != null) 'evangelism_content_id': action.evangelismContentId,
      };

      final response = await _dioClient.post<Map<String, dynamic>>(
        '/mission-actions',
        data: payload,
      );

      final data = response.data;
      if (data == null) {
        throw AppException('Failed to create mission action', 'create_failed');
      }

      return MissionAction.fromMap(data);
    }, operation: 'create_mission_action');
  }

  Future<MissionAction> updateAction(MissionAction action) async {
    return guard(() async {
      final payload = <String, dynamic>{
        'title': action.title,
        'description': action.description,
        'focus': action.focus.name,
        if (action.completedAt != null) 'completed_at': action.completedAt!.toIso8601String(),
        if (action.personName != null) 'person_name': action.personName,
        if (action.notes != null) 'notes': action.notes,
        'requires_follow_up': action.requiresFollowUp,
        if (action.followUpCompletedAt != null) 'follow_up_completed_at': action.followUpCompletedAt!.toIso8601String(),
        if (action.evangelismContentId != null) 'evangelism_content_id': action.evangelismContentId,
      };

      final response = await _dioClient.put<Map<String, dynamic>>(
        '/mission-actions/${action.id}',
        data: payload,
      );

      final data = response.data;
      if (data == null) {
        throw AppException('Failed to update mission action', 'update_failed');
      }

      return MissionAction.fromMap(data);
    }, operation: 'update_mission_action');
  }

  Future<void> deleteAction(String id) async {
    return guard(() async {
      await _dioClient.delete<dynamic>('/mission-actions/$id');
    }, operation: 'delete_mission_action');
  }
}
