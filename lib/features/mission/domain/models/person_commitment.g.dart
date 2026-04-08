// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person_commitment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PersonCommitmentImpl _$$PersonCommitmentImplFromJson(
        Map<String, dynamic> json) =>
    _$PersonCommitmentImpl(
      id: json['id'] as String,
      personProfileId: json['personProfileId'] as String,
      name: json['name'] as String,
      relationship: json['relationship'] as String,
      notes: json['notes'] as String?,
      needs: json['needs'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      isActive: json['isActive'] as bool? ?? true,
      lastContactAt: json['lastContactAt'] == null
          ? null
          : DateTime.parse(json['lastContactAt'] as String),
      nextFollowUpAt: json['nextFollowUpAt'] == null
          ? null
          : DateTime.parse(json['nextFollowUpAt'] as String),
      committedActionIds: (json['committedActionIds'] as List<dynamic>?)
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

Map<String, dynamic> _$$PersonCommitmentImplToJson(
        _$PersonCommitmentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'personProfileId': instance.personProfileId,
      'name': instance.name,
      'relationship': instance.relationship,
      'notes': instance.notes,
      'needs': instance.needs,
      'tags': instance.tags,
      'isActive': instance.isActive,
      'lastContactAt': instance.lastContactAt?.toIso8601String(),
      'nextFollowUpAt': instance.nextFollowUpAt?.toIso8601String(),
      'committedActionIds': instance.committedActionIds,
      'metadata': instance.metadata,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
