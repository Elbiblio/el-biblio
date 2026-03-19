// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoteAdapter extends TypeAdapter<Note> {
  @override
  final int typeId = 21;

  @override
  Note read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Note(
      id: fields[0] as int?,
      title: fields[1] as String?,
      text: fields[2] as String?,
      userId: fields[3] as int?,
      isPublic: fields[4] as bool,
      isFeatured: fields[5] as bool,
      isPinned: fields[6] as bool,
      isVoiceRecorded: fields[7] as bool,
      virtues: (fields[8] as List).cast<String>(),
      createdAt: fields[9] as DateTime,
      updatedAt: fields[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.text)
      ..writeByte(3)
      ..write(obj.userId)
      ..writeByte(4)
      ..write(obj.isPublic)
      ..writeByte(5)
      ..write(obj.isFeatured)
      ..writeByte(6)
      ..write(obj.isPinned)
      ..writeByte(7)
      ..write(obj.isVoiceRecorded)
      ..writeByte(8)
      ..write(obj.virtues)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Note _$NoteFromJson(Map<String, dynamic> json) => Note(
      id: (json['id'] as num?)?.toInt(),
      title: json['title'] as String?,
      text: json['text'] as String?,
      userId: (json['user_id'] as num?)?.toInt(),
      isPublic: json['is_public'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      isPinned: json['is_pinned'] as bool? ?? false,
      isVoiceRecorded: json['is_voice_recorded'] as bool? ?? false,
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
      'is_voice_recorded': instance.isVoiceRecorded,
      'virtues': instance.virtues,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
