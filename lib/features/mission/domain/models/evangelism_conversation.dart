import 'package:freezed_annotation/freezed_annotation.dart';

part 'evangelism_conversation.freezed.dart';
part 'evangelism_conversation.g.dart';

@freezed
class EvangelismConversation with _$EvangelismConversation {
  const factory EvangelismConversation({
    required String id,
    String? personProfileId,
    required String personName,
    required String method,
    String? initialContext,
    String? contentShared,
    String? responseType,
    String? notes,
    List<String>? prayerRequests,
    required DateTime conversationDate,
    @Default(true) bool isOngoing,
    String? decisionMade,
    DateTime? decisionDate,
    List<DateTime>? followUpDates,
    DateTime? nextFollowUpAt,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _EvangelismConversation;

  factory EvangelismConversation.fromJson(Map<String, dynamic> json) =>
      _$EvangelismConversationFromJson(json);

  factory EvangelismConversation.fromMap(Map<String, dynamic> map) {
    return EvangelismConversation(
      id: map['id'] as String,
      personProfileId: map['person_profile_id'] as String?,
      personName: map['person_name'] as String,
      method: map['method'] as String,
      initialContext: map['initial_context'] as String?,
      contentShared: map['content_shared'] as String?,
      responseType: map['response_type'] as String?,
      notes: map['notes'] as String?,
      prayerRequests: (map['prayer_requests'] as List<dynamic>?)?.cast<String>(),
      conversationDate: DateTime.parse(map['conversation_date'] as String),
      isOngoing: map['is_ongoing'] as bool? ?? true,
      decisionMade: map['decision_made'] as String?,
      decisionDate: map['decision_date'] != null
          ? DateTime.parse(map['decision_date'] as String)
          : null,
      followUpDates: (map['follow_up_dates'] as List<dynamic>?)
          ?.map((e) => DateTime.parse(e as String))
          .toList(),
      nextFollowUpAt: map['next_follow_up_at'] != null
          ? DateTime.parse(map['next_follow_up_at'] as String)
          : null,
      metadata: map['metadata'] as Map<String, dynamic>?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}

/// Extension for EvangelismConversation to add toMap method
extension EvangelismConversationExtension on EvangelismConversation {
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'person_profile_id': personProfileId,
      'person_name': personName,
      'method': method,
      'initial_context': initialContext,
      'content_shared': contentShared,
      'response_type': responseType,
      'notes': notes,
      'prayer_requests': prayerRequests,
      'conversation_date': conversationDate.toIso8601String(),
      'is_ongoing': isOngoing,
      'decision_made': decisionMade,
      'decision_date': decisionDate?.toIso8601String(),
      'follow_up_dates': followUpDates?.map((e) => e.toIso8601String()).toList(),
      'next_follow_up_at': nextFollowUpAt?.toIso8601String(),
      'metadata': metadata,
    };
  }
}
