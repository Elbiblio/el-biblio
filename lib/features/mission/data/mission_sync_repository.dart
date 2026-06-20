import 'package:elbiblio/core/errors/app_exception.dart';
import 'package:elbiblio/core/network/dio_client.dart';
import 'package:elbiblio/core/repository/base_repository.dart';
import 'package:logger/logger.dart';

import '../domain/models/mission_action.dart';
import '../domain/models/evangelism_conversation.dart';
import '../domain/models/generosity_record.dart';
import '../domain/models/person_commitment.dart';
import '../domain/models/service_opportunity.dart';
import '../domain/models/accountability_check_in.dart';

class MissionSyncRepository extends BaseRepository {
  MissionSyncRepository(this._dioClient, Logger logger) : super(logger);

  final DioClient _dioClient;

  List<Map<String, dynamic>> _payload(dynamic responseData) {
    if (responseData is List) return responseData.cast<Map<String, dynamic>>();
    if (responseData is Map && responseData['data'] is List) return (responseData['data'] as List).cast<Map<String, dynamic>>();
    return [];
  }

  // ========== Mission Actions ==========
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

      return _payload(response.data)
          .map((json) => MissionAction.fromMap(json))
          .toList();
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

  // ========== Evangelism Conversations ==========
  Future<List<EvangelismConversation>> fetchEvangelismConversations({
    bool? ongoing,
    bool? needsFollowUp,
  }) async {
    return guard(() async {
      final queryParams = <String, dynamic>{};
      if (ongoing != null) queryParams['ongoing'] = ongoing;
      if (needsFollowUp != null) queryParams['needs_follow_up'] = needsFollowUp;

      final response = await _dioClient.get<List<dynamic>>(
        '/evangelism-conversations',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      return _payload(response.data)
          .map((json) => EvangelismConversation.fromMap(json))
          .toList();
    }, operation: 'fetch_evangelism_conversations');
  }

  Future<EvangelismConversation> createEvangelismConversation(EvangelismConversation conversation) async {
    return guard(() async {
      final response = await _dioClient.post<Map<String, dynamic>>(
        '/evangelism-conversations',
        data: conversation.toMap(),
      );

      final data = response.data;
      if (data == null) {
        throw AppException('Failed to create evangelism conversation', 'create_failed');
      }

      return EvangelismConversation.fromMap(data);
    }, operation: 'create_evangelism_conversation');
  }

  Future<EvangelismConversation> recordEvangelismFollowUp(
    String conversationId, {
    String? notes,
    String? newResponseType,
    List<String>? newPrayerRequests,
    String? decisionMade,
  }) async {
    return guard(() async {
      final response = await _dioClient.post<Map<String, dynamic>>(
        '/evangelism-conversations/$conversationId/follow-up',
        data: {
          if (notes != null) 'notes': notes,
          if (newResponseType != null) 'new_response_type': newResponseType,
          if (newPrayerRequests != null) 'new_prayer_requests': newPrayerRequests,
          if (decisionMade != null) 'decision_made': decisionMade,
          'follow_up_date': DateTime.now().toIso8601String(),
        },
      );

      final data = response.data;
      if (data == null) {
        throw AppException('Failed to record follow-up', 'followup_failed');
      }

      return EvangelismConversation.fromMap(data);
    }, operation: 'record_evangelism_follow_up');
  }

  // ========== Generosity Records ==========
  Future<List<GenerosityRecord>> fetchGenerosityRecords({
    String? type,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return guard(() async {
      final queryParams = <String, dynamic>{};
      if (type != null) queryParams['type'] = type;
      if (category != null) queryParams['category'] = category;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();

      final response = await _dioClient.get<List<dynamic>>(
        '/generosity-records',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      return _payload(response.data)
          .map((json) => GenerosityRecord.fromMap(json))
          .toList();
    }, operation: 'fetch_generosity_records');
  }

  Future<GenerosityRecord> createGenerosityRecord(GenerosityRecord record) async {
    return guard(() async {
      final response = await _dioClient.post<Map<String, dynamic>>(
        '/generosity-records',
        data: record.toMap(),
      );

      final data = response.data;
      if (data == null) {
        throw AppException('Failed to create generosity record', 'create_failed');
      }

      return GenerosityRecord.fromMap(data);
    }, operation: 'create_generosity_record');
  }

  Future<Map<String, dynamic>> getGenerositySummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return guard(() async {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();

      final response = await _dioClient.get<Map<String, dynamic>>(
        '/generosity-records/summary',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      return response.data ?? {};
    }, operation: 'get_generosity_summary');
  }

  // ========== Person Commitments ==========
  Future<List<PersonCommitment>> fetchPersonCommitments({
    bool? active,
    bool? needsFollowUp,
  }) async {
    return guard(() async {
      final queryParams = <String, dynamic>{};
      if (active != null) queryParams['active'] = active;
      if (needsFollowUp != null) queryParams['needs_follow_up'] = needsFollowUp;

      final response = await _dioClient.get<List<dynamic>>(
        '/person-commitments',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      return _payload(response.data)
          .map((json) => PersonCommitment.fromMap(json))
          .toList();
    }, operation: 'fetch_person_commitments');
  }

  Future<PersonCommitment> createPersonCommitment(PersonCommitment commitment) async {
    return guard(() async {
      final response = await _dioClient.post<Map<String, dynamic>>(
        '/person-commitments',
        data: commitment.toMap(),
      );

      final data = response.data;
      if (data == null) {
        throw AppException('Failed to create person commitment', 'create_failed');
      }

      return PersonCommitment.fromMap(data);
    }, operation: 'create_person_commitment');
  }

  Future<PersonCommitment> recordContact(String commitmentId, {
    String? actionId,
    DateTime? nextFollowUpAt,
    String? notes,
  }) async {
    return guard(() async {
      final response = await _dioClient.post<Map<String, dynamic>>(
        '/person-commitments/$commitmentId/contact',
        data: {
          if (actionId != null) 'action_id': actionId,
          if (nextFollowUpAt != null) 'next_follow_up_at': nextFollowUpAt.toIso8601String(),
          if (notes != null) 'notes': notes,
        },
      );

      final data = response.data;
      if (data == null) {
        throw AppException('Failed to record contact', 'contact_failed');
      }

      return PersonCommitment.fromMap(data);
    }, operation: 'record_contact');
  }

  // ========== Service Opportunities ==========
  Future<List<ServiceOpportunity>> fetchServiceOpportunities({
    String? category,
    String? locationType,
  }) async {
    return guard(() async {
      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;
      if (locationType != null) queryParams['location_type'] = locationType;

      final response = await _dioClient.get<List<dynamic>>(
        '/service-opportunities',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      return _payload(response.data)
          .map((json) => ServiceOpportunity.fromMap(json))
          .toList();
    }, operation: 'fetch_service_opportunities');
  }

  Future<List<ServiceOpportunity>> generateServiceMatches() async {
    return guard(() async {
      final response = await _dioClient.post<List<dynamic>>(
        '/service-opportunities/generate-matches',
      );

      return _payload(response.data)
          .map((json) => ServiceOpportunity.fromMap(json['service_opportunity'] ?? json))
          .toList();
    }, operation: 'generate_service_matches');
  }

  Future<void> commitToServiceOpportunity(String opportunityId) async {
    return guard(() async {
      await _dioClient.post<dynamic>('/service-opportunities/$opportunityId/commit');
    }, operation: 'commit_to_service_opportunity');
  }

  Future<void> completeServiceOpportunity(String opportunityId) async {
    return guard(() async {
      await _dioClient.post<dynamic>('/service-opportunities/$opportunityId/complete');
    }, operation: 'complete_service_opportunity');
  }

  // ========== Accountability Check-Ins ==========
  Future<List<AccountabilityCheckIn>> fetchAccountabilityCheckIns({
    String? status,
    bool? pending,
  }) async {
    return guard(() async {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (pending != null) queryParams['pending'] = pending;

      final response = await _dioClient.get<List<dynamic>>(
        '/accountability-check-ins',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final data = response.data;
      if (data == null) return [];

      return data.map((json) {
        final map = json as Map<String, dynamic>;
        return AccountabilityCheckIn.fromMap(map);
      }).toList();
    }, operation: 'fetch_accountability_check_ins');
  }

  Future<AccountabilityCheckIn> requestCheckIn({
    required String partnerUserId,
    required DateTime weekStartDate,
    String? note,
    List<String>? verifiedCommitmentIds,
  }) async {
    return guard(() async {
      final response = await _dioClient.post<Map<String, dynamic>>(
        '/accountability-check-ins',
        data: {
          'partner_user_id': partnerUserId,
          'week_start_date': weekStartDate.toIso8601String(),
          'note': note,
          'verified_commitment_ids': verifiedCommitmentIds ?? [],
        },
      );

      final data = response.data;
      if (data == null) {
        throw AppException('Failed to request check-in', 'request_failed');
      }

      return AccountabilityCheckIn.fromMap(data);
    }, operation: 'request_check_in');
  }

  Future<AccountabilityCheckIn> confirmCheckIn(
    String checkInId, {
    String? confirmationNote,
    List<String>? verifiedCommitments,
  }) async {
    return guard(() async {
      final response = await _dioClient.post<Map<String, dynamic>>(
        '/accountability-check-ins/$checkInId/confirm',
        data: {
          if (confirmationNote != null) 'confirmation_note': confirmationNote,
          if (verifiedCommitments != null) 'verified_commitments': verifiedCommitments,
        },
      );

      final data = response.data;
      if (data == null) {
        throw AppException('Failed to confirm check-in', 'confirm_failed');
      }

      return AccountabilityCheckIn.fromMap(data);
    }, operation: 'confirm_check_in');
  }

  Future<Map<String, dynamic>> getAccountabilityStats() async {
    return guard(() async {
      final response = await _dioClient.get<Map<String, dynamic>>(
        '/accountability-check-ins/stats',
      );
      return response.data ?? {};
    }, operation: 'get_accountability_stats');
  }
}
