import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../../today/domain/models/daily_anchors.dart';

@JsonSerializable()
class MeditationSession {
  const MeditationSession({
    required this.id,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.guided,
    required this.audioUrl,
    required this.virtueType,
    required this.completedCount,
  });

  final String id;
  final String title;
  final String description;
  final int durationMinutes;
  final bool guided;
  final String audioUrl;
  final VirtueType virtueType;
  final int completedCount;

  MeditationSession copyWith({
    int? completedCount,
  }) {
    return MeditationSession(
      id: id,
      title: title,
      description: description,
      durationMinutes: durationMinutes,
      guided: guided,
      audioUrl: audioUrl,
      virtueType: virtueType,
      completedCount: completedCount ?? this.completedCount,
    );
  }

  factory MeditationSession.fromJson(Map<String, dynamic> json) {
    return MeditationSession(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      durationMinutes: json['durationMinutes'] as int,
      guided: json['guided'] as bool,
      audioUrl: json['audioUrl'] as String,
      virtueType: VirtueType.values.firstWhere(
        (value) => value.name == json['virtueType'],
        orElse: () => VirtueType.faith,
      ),
      completedCount: json['completedCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'durationMinutes': durationMinutes,
      'guided': guided,
      'audioUrl': audioUrl,
      'virtueType': virtueType.name,
      'completedCount': completedCount,
    };
  }
}

class MeditationSessionAdapter extends TypeAdapter<MeditationSession> {
  @override
  final int typeId = 40;

  @override
  MeditationSession read(BinaryReader reader) {
    return MeditationSession(
      id: reader.readString(),
      title: reader.readString(),
      description: reader.readString(),
      durationMinutes: reader.readInt(),
      guided: reader.readBool(),
      audioUrl: reader.readString(),
      virtueType: reader.read() as VirtueType,
      completedCount: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, MeditationSession obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.title)
      ..writeString(obj.description)
      ..writeInt(obj.durationMinutes)
      ..writeBool(obj.guided)
      ..writeString(obj.audioUrl)
      ..write(obj.virtueType)
      ..writeInt(obj.completedCount);
  }
}
