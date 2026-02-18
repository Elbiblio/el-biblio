// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bible_insight.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BibleInsight _$BibleInsightFromJson(Map<String, dynamic> json) => BibleInsight(
      sections: (json['sections'] as List<dynamic>)
          .map((e) => InsightSection.fromJson(e as Map<String, dynamic>))
          .toList(),
      reference: json['reference'] as String?,
    );

Map<String, dynamic> _$BibleInsightToJson(BibleInsight instance) =>
    <String, dynamic>{
      'sections': instance.sections,
      'reference': instance.reference,
    };

InsightSection _$InsightSectionFromJson(Map<String, dynamic> json) =>
    InsightSection(
      title: json['title'] as String,
      content: json['content'] as String,
    );

Map<String, dynamic> _$InsightSectionToJson(InsightSection instance) =>
    <String, dynamic>{
      'title': instance.title,
      'content': instance.content,
    };
