import 'package:json_annotation/json_annotation.dart';

part 'activity.g.dart';

@JsonSerializable()
class Activity {
  const Activity({
    required this.id,
    required this.userId,
    required this.subjectType,
    required this.subjectId,
    required this.type,
    required this.pointsEarned,
    this.metadata,
    required this.isPublic,
    required this.createdAt,
  });

  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'subject_type')
  final String subjectType;
  @JsonKey(name: 'subject_id')
  final int subjectId;
  final String type;
  @JsonKey(name: 'points_earned')
  final int pointsEarned;
  final Map<String, dynamic>? metadata;
  @JsonKey(name: 'is_public')
  final bool isPublic;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  factory Activity.fromJson(Map<String, dynamic> json) => _$ActivityFromJson(json);
  Map<String, dynamic> toJson() => _$ActivityToJson(this);
}
