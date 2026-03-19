// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commitment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Commitment _$CommitmentFromJson(Map<String, dynamic> json) => Commitment(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String,
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      categoryTags: (json['categoryTags'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      difficultyLevel: (json['difficultyLevel'] as num).toInt(),
      themeId: (json['themeId'] as num).toInt(),
      tips:
          (json['tips'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
    );

Map<String, dynamic> _$CommitmentToJson(Commitment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'durationMinutes': instance.durationMinutes,
      'categoryTags': instance.categoryTags,
      'difficultyLevel': instance.difficultyLevel,
      'themeId': instance.themeId,
      'tips': instance.tips,
    };
