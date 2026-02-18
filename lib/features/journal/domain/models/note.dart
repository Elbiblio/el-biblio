import 'package:json_annotation/json_annotation.dart';

part 'note.g.dart';

@JsonSerializable()
class Note {
  const Note({
    required this.id,
    this.title,
    this.text,
    this.userId,
    this.isPublic = false,
    this.isFeatured = false,
    this.isPinned = false,
    this.virtues = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String? title;
  final String? text;
  @JsonKey(name: 'user_id')
  final int? userId;
  @JsonKey(name: 'is_public')
  final bool isPublic;
  @JsonKey(name: 'is_featured')
  final bool isFeatured;
  @JsonKey(name: 'is_pinned')
  final bool isPinned;
  final List<String> virtues;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  factory Note.fromJson(Map<String, dynamic> json) => _$NoteFromJson(json);
  Map<String, dynamic> toJson() => _$NoteToJson(this);

  Note copyWith({
    int? id,
    String? title,
    String? text,
    int? userId,
    bool? isPublic,
    bool? isFeatured,
    bool? isPinned,
    List<String>? virtues,
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
      virtues: virtues ?? this.virtues,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
