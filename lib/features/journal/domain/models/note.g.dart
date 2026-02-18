// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Note _$NoteFromJson(Map<String, dynamic> json) => Note(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String?,
      text: json['text'] as String?,
      userId: (json['user_id'] as num?)?.toInt(),
      isPublic: json['is_public'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      isPinned: json['is_pinned'] as bool? ?? false,
      virtues: (json['virtues'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$NoteToJson(Note instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'text': instance.text,
      'user_id': instance.userId,
      'is_public': instance.isPublic,
      'is_featured': instance.isFeatured,
      'is_pinned': instance.isPinned,
      'virtues': instance.virtues,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
