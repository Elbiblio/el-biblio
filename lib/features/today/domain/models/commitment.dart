import 'package:json_annotation/json_annotation.dart';

part 'commitment.g.dart';

@JsonSerializable()
class Commitment {
  const Commitment({
    required this.id,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.categoryTags,
    required this.difficultyLevel,
    required this.themeId,
    this.tips = const [],
  });

  final int id;
  final String title;
  final String description;
  final int durationMinutes;
  final List<String> categoryTags;
  final int difficultyLevel;
  final int themeId;
  final List<String> tips;

  factory Commitment.fromJson(Map<String, dynamic> json) => _$CommitmentFromJson(json);
  Map<String, dynamic> toJson() => _$CommitmentToJson(this);

  Commitment copyWith({
    int? id,
    String? title,
    String? description,
    int? durationMinutes,
    List<String>? categoryTags,
    int? difficultyLevel,
    int? themeId,
    List<String>? tips,
  }) {
    return Commitment(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      categoryTags: categoryTags ?? this.categoryTags,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      themeId: themeId ?? this.themeId,
      tips: tips ?? this.tips,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Commitment &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.durationMinutes == durationMinutes &&
        other.categoryTags == categoryTags &&
        other.difficultyLevel == difficultyLevel &&
        other.themeId == themeId &&
        other.tips == tips;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      durationMinutes,
      categoryTags,
      difficultyLevel,
      themeId,
      tips,
    );
  }

  @override
  String toString() {
    return 'Commitment(id: $id, title: $title, description: $description, durationMinutes: $durationMinutes, categoryTags: $categoryTags, difficultyLevel: $difficultyLevel, themeId: $themeId, tips: $tips)';
  }
}
