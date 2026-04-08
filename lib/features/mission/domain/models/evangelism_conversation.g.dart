// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evangelism_conversation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EvangelismConversationImpl _$$EvangelismConversationImplFromJson(
        Map<String, dynamic> json) =>
    _$EvangelismConversationImpl(
      id: json['id'] as String,
      personProfileId: json['personProfileId'] as String?,
      personName: json['personName'] as String,
      method: json['method'] as String,
      initialContext: json['initialContext'] as String?,
      contentShared: json['contentShared'] as String?,
      responseType: json['responseType'] as String?,
      notes: json['notes'] as String?,
      prayerRequests: (json['prayerRequests'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      conversationDate: DateTime.parse(json['conversationDate'] as String),
      isOngoing: json['isOngoing'] as bool? ?? true,
      decisionMade: json['decisionMade'] as String?,
      decisionDate: json['decisionDate'] == null
          ? null
          : DateTime.parse(json['decisionDate'] as String),
      followUpDates: (json['followUpDates'] as List<dynamic>?)
          ?.map((e) => DateTime.parse(e as String))
          .toList(),
      nextFollowUpAt: json['nextFollowUpAt'] == null
          ? null
          : DateTime.parse(json['nextFollowUpAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$EvangelismConversationImplToJson(
        _$EvangelismConversationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'personProfileId': instance.personProfileId,
      'personName': instance.personName,
      'method': instance.method,
      'initialContext': instance.initialContext,
      'contentShared': instance.contentShared,
      'responseType': instance.responseType,
      'notes': instance.notes,
      'prayerRequests': instance.prayerRequests,
      'conversationDate': instance.conversationDate.toIso8601String(),
      'isOngoing': instance.isOngoing,
      'decisionMade': instance.decisionMade,
      'decisionDate': instance.decisionDate?.toIso8601String(),
      'followUpDates':
          instance.followUpDates?.map((e) => e.toIso8601String()).toList(),
      'nextFollowUpAt': instance.nextFollowUpAt?.toIso8601String(),
      'metadata': instance.metadata,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
