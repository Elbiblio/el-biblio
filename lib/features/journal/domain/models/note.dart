import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'note.g.dart';

@HiveType(typeId: 21)
@JsonSerializable()
class Note {
  const Note({
    this.id,
    this.title,
    this.text,
    this.userId,
    this.isPublic = false,
    this.isFeatured = false,
    this.isPinned = false,
    this.isVoiceRecorded = false,
    this.virtues = const [],
    this.meditationSessionId,
    required this.createdAt,
    required this.updatedAt,
  });

  @HiveField(0)
  final int? id;
  
  @HiveField(1)
  final String? title;
  
  @HiveField(2)
  final String? text;
  
  @HiveField(3)
  @JsonKey(name: 'user_id')
  final int? userId;
  
  @HiveField(4)
  @JsonKey(name: 'is_public')
  final bool isPublic;
  
  @HiveField(5)
  @JsonKey(name: 'is_featured')
  final bool isFeatured;
  
  @HiveField(6)
  @JsonKey(name: 'is_pinned')
  final bool isPinned;
  
  @HiveField(7)
  @JsonKey(name: 'is_voice_recorded')
  final bool isVoiceRecorded;
  
  @HiveField(8)
  final List<String> virtues;

  @HiveField(11)
  @JsonKey(name: 'meditation_session_id')
  final String? meditationSessionId;

  @HiveField(9)
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @HiveField(10)
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  factory Note.fromJson(Map<String, dynamic> json) {
    // Handle type conversions safely
    final id = json['id'];
    final userId = json['user_id'];
    
    return Note(
      id: id is int ? id : (id is num ? id.toInt() : null),
      title: json['title'] as String?,
      text: json['text'] as String?,
      userId: userId is int ? userId : (userId is num ? userId.toInt() : null),
      isPublic: json['is_public'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      isPinned: json['is_pinned'] as bool? ?? false,
      isVoiceRecorded: json['is_voice_recorded'] as bool? ?? false,
      virtues: (json['virtues'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      meditationSessionId: json['meditation_session_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
  Map<String, dynamic> toJson() => _$NoteToJson(this);

  Note copyWith({
    int? id,
    String? title,
    String? text,
    int? userId,
    bool? isPublic,
    bool? isFeatured,
    bool? isPinned,
    bool? isVoiceRecorded,
    List<String>? virtues,
    String? meditationSessionId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      text: text ?? this.text,
      userId: userId ?? this.userId,
      isPublic: isPublic ?? this.isPublic,
      isFeatured: isFeatured ?? this.isFeatured,
      isPinned: isPinned ?? this.isPinned,
      isVoiceRecorded: isVoiceRecorded ?? this.isVoiceRecorded,
      virtues: virtues ?? this.virtues,
      meditationSessionId: meditationSessionId ?? this.meditationSessionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
