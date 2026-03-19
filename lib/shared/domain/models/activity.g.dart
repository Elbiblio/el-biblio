// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Activity _$ActivityFromJson(Map<String, dynamic> json) => Activity(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      subjectType: json['subject_type'] as String,
      subjectId: (json['subject_id'] as num).toInt(),
      type: json['type'] as String,
      pointsEarned: (json['points_earned'] as num).toInt(),
      metadata: json['metadata'] as Map<String, dynamic>?,
      isPublic: json['is_public'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ActivityToJson(Activity instance) => <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'subject_type': instance.subjectType,
      'subject_id': instance.subjectId,
      'type': instance.type,
      'points_earned': instance.pointsEarned,
      'metadata': instance.metadata,
      'is_public': instance.isPublic,
      'created_at': instance.createdAt.toIso8601String(),
    };
