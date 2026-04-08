// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'reading_plan.freezed.dart';
part 'reading_plan.g.dart';

@freezed
class ReadingPlan with _$ReadingPlan {
  const factory ReadingPlan({
    required int id,
    required String title,
    String? description,
    @JsonKey(name: 'thumbnail_url') String? thumbnailUrl,
    @JsonKey(name: 'duration_days') required int durationDays,
    @JsonKey(name: 'theme_id') String? themeId,
    @JsonKey(name: 'is_featured') @Default(false) bool isFeatured,
    @Default([]) List<ReadingPlanDay> days,
  }) = _ReadingPlan;

  factory ReadingPlan.fromJson(Map<String, dynamic> json) => _$ReadingPlanFromJson(json);
}

@freezed
class ReadingPlanDay with _$ReadingPlanDay {
  const factory ReadingPlanDay({
    required int id,
    @JsonKey(name: 'day_number') required int dayNumber,
    required List<String> verses,
    @JsonKey(name: 'devotional_title') String? devotionalTitle,
    @JsonKey(name: 'devotional_text') String? devotionalText,
  }) = _ReadingPlanDay;

  factory ReadingPlanDay.fromJson(Map<String, dynamic> json) => _$ReadingPlanDayFromJson(json);
}

@freezed
class UserReadingPlan with _$UserReadingPlan {
  const factory UserReadingPlan({
    required int id,
    @JsonKey(name: 'reading_plan_id') required int readingPlanId,
    @JsonKey(name: 'current_day') @Default(1) int currentDay,
    @Default('active') String status,
    @JsonKey(name: 'started_at') DateTime? startedAt,
    @JsonKey(name: 'completed_at') DateTime? completedAt,
    ReadingPlan? plan,
  }) = _UserReadingPlan;

  factory UserReadingPlan.fromJson(Map<String, dynamic> json) => _$UserReadingPlanFromJson(json);
}
