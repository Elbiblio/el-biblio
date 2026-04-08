// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_opportunity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ServiceOpportunityImpl _$$ServiceOpportunityImplFromJson(
        Map<String, dynamic> json) =>
    _$ServiceOpportunityImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      timeCommitment: json['timeCommitment'] as String,
      organization: json['organization'] as String?,
      contactInfo: json['contactInfo'] as String?,
      requiredSkills: (json['requiredSkills'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      burdenTags: (json['burdenTags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      tendencyTags: (json['tendencyTags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      locationType: json['locationType'] as String? ?? 'local',
      status: json['status'] as String? ?? 'active',
      volunteerCount: (json['volunteerCount'] as num?)?.toInt() ?? 0,
      maxVolunteers: (json['maxVolunteers'] as num?)?.toInt(),
      startsAt: json['startsAt'] == null
          ? null
          : DateTime.parse(json['startsAt'] as String),
      endsAt: json['endsAt'] == null
          ? null
          : DateTime.parse(json['endsAt'] as String),
      userMatchStatus: json['userMatchStatus'] as String?,
      matchScore: (json['matchScore'] as num?)?.toDouble(),
      matchReasons: (json['matchReasons'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$ServiceOpportunityImplToJson(
        _$ServiceOpportunityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'category': instance.category,
      'timeCommitment': instance.timeCommitment,
      'organization': instance.organization,
      'contactInfo': instance.contactInfo,
      'requiredSkills': instance.requiredSkills,
      'burdenTags': instance.burdenTags,
      'tendencyTags': instance.tendencyTags,
      'locationType': instance.locationType,
      'status': instance.status,
      'volunteerCount': instance.volunteerCount,
      'maxVolunteers': instance.maxVolunteers,
      'startsAt': instance.startsAt?.toIso8601String(),
      'endsAt': instance.endsAt?.toIso8601String(),
      'userMatchStatus': instance.userMatchStatus,
      'matchScore': instance.matchScore,
      'matchReasons': instance.matchReasons,
      'metadata': instance.metadata,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
