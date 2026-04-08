// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReadingPlanImpl _$$ReadingPlanImplFromJson(Map<String, dynamic> json) =>
    _$ReadingPlanImpl(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      durationDays: (json['duration_days'] as num).toInt(),
      themeId: json['theme_id'] as String?,
      isFeatured: json['is_featured'] as bool? ?? false,
      days: (json['days'] as List<dynamic>?)
              ?.map((e) => ReadingPlanDay.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$ReadingPlanImplToJson(_$ReadingPlanImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'thumbnail_url': instance.thumbnailUrl,
      'duration_days': instance.durationDays,
      'theme_id': instance.themeId,
      'is_featured': instance.isFeatured,
      'days': instance.days,
    };

_$ReadingPlanDayImpl _$$ReadingPlanDayImplFromJson(Map<String, dynamic> json) =>
    _$ReadingPlanDayImpl(
      id: (json['id'] as num).toInt(),
      dayNumber: (json['day_number'] as num).toInt(),
      verses:
          (json['verses'] as List<dynamic>).map((e) => e as String).toList(),
      devotionalTitle: json['devotional_title'] as String?,
      devotionalText: json['devotional_text'] as String?,
    );

Map<String, dynamic> _$$ReadingPlanDayImplToJson(
        _$ReadingPlanDayImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'day_number': instance.dayNumber,
      'verses': instance.verses,
      'devotional_title': instance.devotionalTitle,
      'devotional_text': instance.devotionalText,
    };

_$UserReadingPlanImpl _$$UserReadingPlanImplFromJson(
        Map<String, dynamic> json) =>
    _$UserReadingPlanImpl(
      id: (json['id'] as num).toInt(),
      readingPlanId: (json['reading_plan_id'] as num).toInt(),
      currentDay: (json['current_day'] as num?)?.toInt() ?? 1,
      status: json['status'] as String? ?? 'active',
      startedAt: json['started_at'] == null
          ? null
          : DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      plan: json['plan'] == null
          ? null
          : ReadingPlan.fromJson(json['plan'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$UserReadingPlanImplToJson(
        _$UserReadingPlanImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reading_plan_id': instance.readingPlanId,
      'current_day': instance.currentDay,
      'status': instance.status,
      'started_at': instance.startedAt?.toIso8601String(),
      'completed_at': instance.completedAt?.toIso8601String(),
      'plan': instance.plan,
    };
